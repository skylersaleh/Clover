Clover 
======

With a large number of problems, I noticed that the OpenCL language did not provide enough information about a kernels execution to the compiler to properly optimize it to the hardware it was targeting, and I noticed that the OpenCL library often provided information relevant on how to optimize the kernel execution far to late in the process to be useful. Also, I noticed that there was no clean way of implementing complicated execution patterns in current OpenCL that are relevant to many algorithms. And that their was a lot of boiler plate code I was writing just to create proper graphs to handle all of the cases, and the memory for these complicated patterns. Also, I noticed that there was no good way for a program to hide the latency of the calculations between different hardware devices, leading to a lot of stalling in most algorithms implementations. 

To fix these issues, I am trying to develop my own meta language, called Clover. It consists of three parts: a compiler/translator,  a reconfigurable ABI, and a run time, that exists in a library linked to another application. By providing these three components we can abstract the algorithm away from the current hardware, and do hardware specific optimizations in a different computational space than the algorithm. Also, by combining the compiler and the run time, new hardware features can be emulated quickly, even when the native hardware can not support the functionality. And since Clover exists solely as a library, it requires no hardware or driver modifications to use, and can be deployed in applications immediately. 

![](https://raw.githubusercontent.com/skylersaleh/Clover/master/docs/diagrams/block_diagram.png)

Language
--------

Ill start by explaining the language itself, as it is the most interesting part. It is very much a super set of OpenCL (think C vs C++) rather than a completely new language. The goal is that any OpenCL 2.0 kernel should be valid in Clover. And it provides a bunch of useful features that complement those in OpenCL 2.0, such as…

- The ability to describe the host calling convention and required buffers inside the kernel. This allows the run time to automatically perform most stages of initialization, and allows the compiler to optimize certain access patterns.
- An abstraction that allows for kernels or functions on arbitrary devices to be called, as if they were native to the language. (You can have a OpenCL kernel call a registered C function and vice-versa)
- Kernel introspection. This allows the kernel to read back optimization relevant traits about its state when compiled to tweak its execution (an example is the kernel can read back its maximum work group size for the hardware it is running on, and use that to determine optimum work group sizes for local memory)
- Constant expressions, which can be mixed with the prior to easily code kernels that are tailored to multiple hardware devices.
- A limited version of C++ templates.
- Import semantics. 
- An abstraction of kernel enqueue kernel, that allows you to enqueue kernel that are not in the same CL file.
- A simulated version of function pointers.
- Some tools for negotiating buffer layouts with a host application.
- And a simulated early out for kernel execution (useful for simulating preemption and sleep functionality)
- An event kernel type that allows lower overhead enqueueing of repetitive kernels. 

But, more interestingly, it includes tools for performing common sets of computationally intensive process. I noticed most computationally intensive algorithms can be converted to fall under three categories: Tree Traversal, Reduction, and Constraint resolution, and most of these problems have known methods of parallelizing them. However, the strategies used are often fairly complicated, error prone, and requires a lot of knowledge of GPGPU to implement. So, a big portion of the language is adding tools to describe doing these style of calculations in a programmer friendly way, and then have the compiler generate a hardware friendly implementation to solve the problem. 

Reduction
---------

Lets start with a reduction problem…

An example of a classical implementation of this is the dot product of two vectors. To do this quickly you would need to set up a proper reduction tree, and allocate the required amount of local memory to do the calculation, and put barriers in the proper places, and spend a lot of time optimizing for your specific hardware target. In clover you write this:

```
reduction vector_dot(gentype * A, gentype *B, gentype * res){
    res->next = res->prev + A->next*B->next;
}
```

And that is it. The compiler does the rest. Of note here are the new keywords I have added to the language: “reduction”, “gentype”, “prev”, and “next”. 

The reduction keyword signals to the compiler that this kernel performs an operation that should use a “reduction” strategy. And while I could probably deduce that the operation being performed matches a reduction from the AST, I found that to be very difficult, and there would be no way around guessing the wrong strategy to use, so I decided to just make it explicit to the compiler, to save time on my end, and to prevent future problems. 

Gentype is a variable that is defined the same way as it is in the OpenCL specification, and is the template capability that I added into the language. A gentype can be called with all primitive data types, and so it saves programmer effort, by auto generating the duplicate kernels for the different variable types. 

The “next" and “prev” keywords provide an abstraction from the get_global_id, get_local_id, and associated data structure that is used to perform the calculation. It also provides enough information in the AST generated from this code to then build the proper parallel reduction tree required to implement this efficiently on a GPU, or the unrolled loop that would be required to efficiently implement this on the CPU. And since the buffer format is described in the kernel, the compiler can also optimize the sizing of things like local memory to better map to the target hardware and problem. Also something to notice is that the programmer does not have to configure the workgroup sizes to run this kernel, they can be deduced from its arguments.

Modules
-------

I add support for a type of object oriented programming in Clover. This is to handle the tree traversal use case. Modules implement a very similar capability to C++ classes.

- Dynamic memory allocation can not be done on many hardware devices, so many techniques that are reliant on dynamic memory such as: polymorphism, multiple inheritance, virtual function calls, have replacements that are better suited to the hardware.
- The memory is tightly coupled to the execution. This allows the compiler to conveniently handle memory control in the existing AST that denotes the flow of execution. Also it makes it very difficult to cause memory access violations, and gives the compiler more information about the applications graph during execution.
- Because the compiler has a good grasp on the graph structure it can implicitly define links between graph structures such as next, prev, and parent nodes. Which helps prevent programmer errors. Also since the parent nodes are known at compiler time, their types can be checked, and the interface paradigm can be implemented by referencing variables in the parent class. 
- Also modules are encouraged to communicate between each other asynchronously, because synchronous communication must be emulated, due to the fact that their execution may be happening on different hardware devices. 

Here is an example of what a module looks like.

```
module Ball {
    float2 pos = float2(0);
    float2 vel = float2(0);
    float2 size= float2(0);
    float4 color= float4(0,0,0,0);
    event update(float dt){
        parent->do_bounce(pos,vel);
        pos = vel.xy*dt;
    }
};
```

Notice that the module can call functions on its parent. And because of that it can not be added as a member of a class that does not have a do_bounce function. Also, note that it describes its own data layout, and default initialization of variables, in a way that most programmers are familiar with.

For performance reasons modules can be implemented as either structures of arrays or array of structs depending on the applications use of the objects, and the compiler can perform series-parallel graph decomposition on the AST to increase the achievable level of parallelism. Also kernels called on individual modules of common types are coalesced together as one kernel enqueue with a larger workgroup, to increase parallelism. 

Constraint Graphs
-----------------

This is one I am very proud of, and I have not seen its implementation in any other languages. Clover includes a tool for solving arbitrary constraint graphs, which allows for very complicated algorithms to be written very easily. Its functionality is best explained through an example...

Lets say you are designing a program that layouts text to be rendered in a user interface. As input you must take in a newline delimited string, and a width for each line of text. As output you have to provide a graph that allows you to iterate through lines, words and letters in the sequence. Along with the bounding boxes of each of these that show were each letter should be rendered in the interface. 

While this problem seems simple at first there is a lot of complexity in it, that seem to preclude it from being parallelized at all. For instance:

- Newlines can be included in the input string in any position and must result in the position of the next letter changing to the next line, and effect the x and y coordinates of every proceeding letter after it.
- Words and lines are variable character length.
- Characters have different sizes in Latin languages. 
- The coordinate of the next letters is dependent on the location of the previous letter.
- When a word extends past the width of a line, the whole word must be moved to the next line to wrap the text properly. (The position of the first character in a word is dependent on the position of the last character in the word)
- Sometimes you want to include a figure inline with the text, so the width of each line changes based off of the y coordinate of the line. 
- The outputs are graphs! GPUs can’t do dynamic memory allocation. 

However, it turns out that this type of problem is actually absurdly parallel, you can actually perform the calculation on each letter in parallel if you use Stochastic Diffusion Search. However, designing an OpenCL program that implements this algorithm for a general problem like that efficiently is very difficult, and involves a lot of error prone and mechanical processes for the programmer. Also the performance of SDS is heavily dependent on the final graphs constructions (its best case is O(N), and its worst case is O(N^2)), so in Clover, I have designed the language so that the compiler can extract all of the required information to implement SDS out of the AST, and optimize it based on the current graph itself. And the result is that you can solve this sort of problem very quickly and with very little effort. The below code implements a solution to the above mentioned problem in clover. 

```
module letter{
    uchar letter=0;
    float2 pos  =float2(0,0);
    float2 size =float2(0,0);
    letter* word_start=this;
    letter* word_end  =this;
    letter* line_start=this;
    letter* line_end  =this;
    float2 top_right(){ return pos + size; }
    float2 top_left(){  return pos+float2(0,size.y); }
    float2 bottom_right(){ return pos+float2(size.x,0); }
    float2 bottom_left(){  return pos; }
    
    float2 word_size(){ return word_end->top_right() - word_start->bottom_left(); }
    
    bool is_whitespace(){ return letter =='\n' || letter == '\r' || letter =='\t' ||letter == ' ' || letter =='\0';}
    bool should_newline(){ return letter=='\n' || word_start->prev->pos.x + word_size().x > parent->line_width; }
    constraint layout(){
        
        if(!word_start->is_whitespace()) word_start = word_start->prev->word_start;
        if(!line_start->prev->should_newline())line_start = line_start->prev->line_start;
        
        if(!word_end->next->is_whitespace()) word_end = word_end->next->word_end;
        if(!line_end->should_newline())line_end = line_end->next->line_end;
        
        if(prev->should_newline())pos = (float2)(0.,prev->pos.y+parent->line_height);
        else pos.x = prev->pos.x + prev->size.x;
    }
};
```

And that is it. The only keyword that gets added in this example is the constraint type that indicates to the compiler that it should use the constraint strategy when calling this kernel. The prev, next, and parent keywords end up retaining the same functionality as they were defined with above Whats more, SDS is a very versatile algorithm and has been applied to text search, object recognition, feature tracking, robot localization, path finding, and a lot of other algorithms that require large amounts of computation. 

And those are the big things that I am adding with the language. There is a few other things I wanted to add to the language, but those are the major ones.

ABI
----
To enable the functionally required by the language the Clover runtime and the Clover script must be able to communicate effectively, both synchronously and asynchronously. To do this the memory is stored as a flat memory map, that is mapped to the memory space of all devices executing the code. The compiler determines the format of this memory map, based off the AST generated from the Clover compiler, and configures the  Clover run time for communication with the Clover script. Asynchronous communication can happen between the executing Clover script and the run time by directly writing into the memory map, but any communication that happens using this method must be tolerant to receiving old information.

Synchronous communication can happen by placing a Synchronous Buffer in the memory map. In Clover the synchronous buffers are arbitrarily sized at compile time by the Clover script, and operate as a lockless ring-buffer. The Clover compiler automatically tells the run time when it needs to handle updates to the synchronous buffers and at what points synchronization must be added in the OpenCL command buffer for correct operation. This allows the Clover run time to enqueue kernels in parallel with the kernels execution.

Run-Time
--------
The Clover run time is the last key part of Clover. It is what handles the basic application flow control, memory allocation, Clover-host application communication, and hosts the Clover compiler. Since the run time controls both the compiler, and the applications flow, it can easily dynamically profile the applications hot spots, and suggest to the compiler how it could possibly optimize the generated code better. Also since it controls the memory allocation, it can measure the cost of transferring memory to different hardware, and can try to find the best hardware to run a certain types of functions on, at a very high level. 

Command information is transmitted between the Clover script and the run time by packets in a  “Execution Buffer”, which is just a synchronous buffer that is tagged by the compiler. Inside the execution buffer, commands are stored as two 8 byte numbers. The first one being the command identifier, and the second stores the address where the arguments are stored. 

The command identifier is used to look up a function pointer, which is then called with the argument address. This is used to allow a Clover script to call native functions, and by some simple extensions it can be used for imitating kernel enqueue kernel on CL 1.2 hardware. Since communication through the execution buffer is always going to be slow (because it involves synchronization), the run time implements an event loop to reduce the amount of synchronous communication. The event loop is pretty standard accept that events can reference data stored in the memory map asynchronously to control their execution. 
