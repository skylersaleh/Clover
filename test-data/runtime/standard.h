#import "types.h"

ADDMEMMAP(CommandBuffer,cb);
#define kRed (float4)(1,0,0,1)
#define kBlue (float4)(0,0,1,1)
#define kGreen (float4)(0,1,0,1)
#define kWhite (float4)(1,1,1,1)
#define kBlack (float4)(0,0,0,1)
#define kYellow (float4)(1,1,0,1)
#define kCyan (float4)(0,1,1,1)
#define kMagenta (float4)(1,0,1,1)


int copy_string(global char* dest, global char* src, int start, int end){
    src-=start;
    while(start<end&&src[start]){
        dest[start]=src[start];
        ++start;
    }
    return start;
}
int copy_string_constant(global char* dest, constant char* src, int start, int end){
    src-=start;
    while(start<end&&src[start]){
        dest[start]=src[start];
        ++start;
    }
    return start;
}
int copy_char(global char* dest, char src, int start, int end){
    if(start<end)dest[start++]=src;
    return start;
}
int copy_int(global char* dest, int source, int start, int end){
    char buffer[11];
    if(source<0){
        start=copy_char(dest,'-',start,end);
        source*=-1;
    }
    char dig[10];
    
    for(int i=0;i<10;++i){
        dig[i]=source%10;
        source/=10;
    }
    while (source>9&&start<end) {
        int dec = source%10;
        source/=10;
        
    }
}
int push_command_buffer(global MemMap* mem,int size){
    global int * address =&(mem->cb.cb_pos);
    return atomic_add(address,size);
}

void set_background(global MemMap* mem,int4 color){
    int address=push_command_buffer(mem,5);
    CB(mem,address) = kCSetBackground;
    CB(mem,address+1) = color[0];
    CB(mem,address+2) = color[1];
    CB(mem,address+3) = color[2];
    CB(mem,address+4) = color[3];
}
void register_ellipse(global MemMap* mem, global float2* pos, global float2* size, global float4* color){
    int address= push_command_buffer(mem,4);
    CB(mem,address)=kCRegisterEllipse;
    CB(mem,address+1)= (global float*)pos-(global float*)mem;
    CB(mem,address+2)= (global float*)size-(global float*)mem;
    CB(mem,address+3)= (global float*)color-(global float*)mem;

}
void register_rect(global MemMap* mem, global float2* pos, global float2* size, global float4* color){
    int address= push_command_buffer(mem,4);
    CB(mem,address)=kCRegisterRect;
    CB(mem,address+1)= (global float*)pos-(global float*)mem;
    CB(mem,address+2)= (global float*)size-(global float*)mem;
    CB(mem,address+3)= (global float*)color-(global float*)mem;
    
}

void print(global MemMap* mem,constant char* string){
    int size = 0;
    while(string[size]){
        ++size;
    }
    int address=push_command_buffer(mem,(size+3)/4+2);
    CB(mem,address++) = kCPrint;
    CB(mem,address++) = size;
    address*=4;
    global char* mc = (global char*)mem;
    int i = 0;
    while(string[i]){
        mc[(address++)%(kCommandBufferSize*4)]=string[i];
        ++i;
    }
}
void run_event_kern3D(global MemMap* mem, int kern,int event, int sizeX,int sizeY,int sizeZ){
    int address = push_command_buffer(mem,6);
    CB(mem,address) = kCRunKern;
    CB(mem,address+1) = kern;
    CB(mem,address+2) = event;
    CB(mem,address+3) = sizeX;
    CB(mem,address+4) = sizeY;
    CB(mem,address+5) = sizeZ;
}
void run_event_kern2D(global int* mem, int kern,int event, int sizeX,int sizeY){
    run_event_kern3D(mem,kern,event,sizeX,sizeY,1);

}
void run_event_kern1D(global MemMap* mem, int kern,int event, int sizeX){
    run_event_kern3D(mem,kern,event,sizeX,1,1);

}
void run_event_kern(global MemMap* mem, int kern,int event){
    run_event_kern3D(mem,kern,event,1,1,1);
}
void run_kern3D(global MemMap* mem, int kern, int sizeX,int sizeY,int sizeZ){
    run_event_kern3D(mem,kern,kENow,sizeX,sizeY,sizeZ);
}
void run_kern2D(global MemMap* mem, int kern, int sizeX,int sizeY){
    run_kern3D(mem,kern,sizeX,sizeY,1);
}
void run_kern1D(global MemMap* mem, int kern, int sizeX){
    run_kern3D(mem,kern,sizeX,1,1);
}
void run_kern(global MemMap* mem, int kern){
    run_kern3D(mem,kern,1,1,1);
}


