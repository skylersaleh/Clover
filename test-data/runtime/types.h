enum {
    kCommandBufferSize=1024,
    kCommandBufferIndex = kCommandBufferSize,
    kMemSize=kCommandBufferIndex+10,
};
enum Events{
    kENow,
    kEUpdate,
    kEInput,
    kEWindowResize,
};
enum ProgramInfo{
    kIMemMapSize = 0,
    kICommandBufferSize=1,
    kICBPos=2,
    kProgramInfoSize
};

enum Commands{
    kCRunKern,
    kCSetBackground,
    kCDrawShape,
    kCPrint,
    kCRegisterEllipse,
    kCRegisterRect,
    kCUserEventBegin,
};

typedef struct CommandBuffer{
    int data[kCommandBufferSize];
    int cb_pos;
}CommandBuffer;
#define CB(A,B) ((CommandBuffer*)A)->data[(B)%kCommandBufferSize]
#define CB_FLOAT(A,B) ((float*)((CommandBuffer*)A)->data)[(B)%kCommandBufferSize]
#define CB_BYTE(A,B,BYTE) ((unsigned char*)((CommandBuffer*)A)->data)[((B)%kCommandBufferSize)*4+BYTE]


