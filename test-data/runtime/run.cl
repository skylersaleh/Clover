#import "standard.h"
typedef struct Ball{
    float2 pos,vel,size;
    float4 color;
} Ball;
typedef struct Paddle{
    float2 pos,size,orig_size,dir;
    float2 score_size[10];
    float2 score_pos[10];
    float4 color;
    float down,up;
    int score;
} Paddle;
typedef struct Game{
    Ball ball;
    float2 ball_center,window_size,paddle_range;
    float4 ball_range;
    Paddle paddles[2];
    float time;
} Game;
ADDMEMMAP(Game,game);
kernel void run_update(global MemMap* cb,float dt){
    global Game* g = &cb->game;
    global Paddle* pads = g->paddles;
    global Ball * b = &(g->ball);
    g->time+=dt;
    b->pos+=b->vel*dt;
    b->vel = clamp(b->vel,-200000.f,200000.f);
    b->vel.y *=sign(b->pos.y-g->ball_range.hi.y+0.5)*sign(g->ball_range.lo.y-b->pos.y+0.5);
    b->pos.y=clamp(b->pos.y,g->ball_range.lo.y,g->ball_range.hi.y);
    if(b->pos.x+pads[1].size.x>g->ball_range.hi.x){
        if(b->pos.x>g->ball_range.hi.x+50){
            b->vel= -400.f;
            b->pos=g->ball_center;
            pads[0].score++;
        }else if(fabs(pads[1].pos.y-b->pos.y)<(pads[1].size.y+b->size.y)/2&&b->vel.x>0){
            b->vel*=(float2)(-1.1,1.1);
            b->color=pads[1].color;
            pads[1].size=pads[1].orig_size*1.3f;
        }
    }
    if(b->pos.x-pads[0].size.x<g->ball_range.lo.x){
        if(fabs(pads[0].pos.y-b->pos.y)<(pads[0].size.y+g->ball.size.y)/2&&b->vel.x<0){
            b->vel*=(float2)(-1.1,1.1);
            b->color=pads[0].color;
            pads[0].size=pads[0].orig_size*1.3f;
        }else if(b->pos.x<g->ball_range.lo.x-50){
            b->pos=g->ball_center;
            b->vel= 400.f;
            pads[1].score++;
        }
    }
    if(pads[0].score>9||pads[1].score>9) pads[0].score=pads[1].score=0;
    for(int i=0;i<2;++i){
        float speed =(pads[i].up-pads[i].down)*700*dt;
        pads[i].pos.y=clamp(pads[i].pos.y+speed,g->paddle_range.lo,g->paddle_range.hi);
        pads[i].size += (pads[i].orig_size-pads[i].size)*dt*4.f;
    }
}
kernel void do_score_circles(global MemMap* cb,float dt){
    size_t i = get_global_id(0),i2 = get_global_id(1);
    global Paddle* p = cb->game.paddles+i2;
    p->score_size[i] =(float2)(i<p->score ? 20.f+5*sin(i*0.5+cb->game.time*5.f):0);
}
kernel void run_input(global MemMap* cb, int id, float value){
    if(id=='s')     cb->game.paddles[0].up= value;
    else if(id=='a')cb->game.paddles[0].down= value;
    else if(id==',')cb->game.paddles[1].up= value;
    else if(id=='.')cb->game.paddles[1].down= value;
}
kernel void update_window(global MemMap *cb, float2 dims,float2 pos){
    global Paddle* p = cb->game.paddles;
    for(int i=0;i<10;++i)p[1].score_pos[i].x =dims[0]-100-i*30;
    p[0].pos.x = p[0].size.x/2;
    p[1].pos.x = dims.x-p[1].size.x/2;
    cb->game.ball_range= (float4)(cb->game.ball.size*0.5f,dims-cb->game.ball.size*0.5f);
    cb->game.paddle_range= (float2)(p[0].orig_size.y*0.5f,dims.y-p[0].orig_size.y*0.5f);
    cb->game.ball_center=dims/2;
    cb->game.window_size=dims;
}
kernel void run(global MemMap *mem){
    global Game* g=&mem->game;
    g->time=0;
    g->ball = (Ball){.vel=400.f,.pos=200.f,.size=40.f,.color=kRed};
    register_ellipse(mem,&(g->ball.pos), &(g->ball.size),&(g->ball.color));
    g->paddles[0].score=g->paddles[1].score=0;
    g->paddles[0].color=kRed;
    g->paddles[1].color=kBlue;
    for(int i=0;i<2;++i){
        g->paddles[i].pos = (float2)(0);
        g->paddles[i].orig_size=g->paddles[i].size = (float2)(30,200);
        register_rect(mem,&(g->paddles[i].pos), &(g->paddles[i].size),&(g->paddles[i].color));
        for(int i2=0;i2<10;++i2){
            g->paddles[i].score_pos[i2] =(float2)(100+i2*30,50);
            register_ellipse(mem,g->paddles[i].score_pos+i2,&(g->paddles[i].score_size[i2]),&(g->paddles[i].color));
        }
    }
    set_background(mem,(int4)(0));
    run_event_kern(mem,kern_id("run.cl","run_update"),kEUpdate);
    run_event_kern(mem,kern_id("run.cl","update_window"),kEWindowResize);
    run_event_kern2D(mem,kern_id("run.cl","do_score_circles"),kEUpdate,10,2);
    run_event_kern(mem,kern_id("run.cl","run_input"),kEInput);
}