/**
 * This file doesn't actually do anything.
 * It is just used as a test bench for the lexer and parser.
**/

struct letter{
    uchar letter[];//Unsized Arrays
    float2 pos[];
    float2 size[];
};
kernel void layout (global * letters, int *work_item_map){
    size_t x=get_global_id(0);
    letter * curr = letters + x;
    letter * prev = letters + x - 1;
    letter * next = letters + x + 1;
    
    if(!curr->word_start->is_whitespace()) curr->word_start = curr->word_start->prev->word_start;
    if(!curr->line_start->prev->should_newline())line_start = line_start->prev->line_start;
    
    if(!word_end->next->is_whitespace()) word_end = word_end->next->word_end;
    if(!line_end->should_newline())line_end = line_end->next->line_end;
    
    if(prev->should_newline())pos = (float2)(0.,prev->pos.y+parent->line_height);
    else pos.x = prev->pos.x + prev->size.x;
    
}
module letter{
    uchar letter= 0;
    float2 pos  =float2(0,0);
    float2 size =float2(0,0);
    letter* word_start=this;
    letter* word_end  =this;
    letter* line_start=this;
    letter* line_end  =this;
    
    float2 top_right(){    return pos + size;           }
    float2 top_left() {    return pos+float2(0,size.y); }
    float2 bottom_right(){ return pos+float2(size.x,0); }
    float2 bottom_left() { return pos; }
    
    float2 word_size(){ return word_end->top_right() - word_start->bottom_left(); }
    
    bool is_whitespace(){ return letter =='\n' || letter == '\r' || letter =='\t' || letter == ' ' || letter =='\0';}
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

module Ball {
    float2 pos = float2(0);
    float2 vel = float2(0);
    float2 size= float2(0);
    float4 color= float4(0,0,0,0);
    event update(float dt){
        //while(some_var>another){
        if(some_var>another){
            parent->do_bounce(pos,vel);
            pos = vel.xy*dt;
            if(some_var>another)add_work_item();
        }
        //}
    }
};
reduction vector_dot(gentype * A, gentype *B, gentype * res){
    res->next = res->prev + A->next*B->next;
}
module Paddle{
    float2 pos = float2(0,0);
    float2 size = float2(50,200);
    float2 orig_size = float2(50,200);
    float2 score_size = float2(0);
    float2 score_pos = float2(0);
    float4 color = float4(0,0,0,0);
    float down = 0;
    float up = 0;
    int score = 0;
    void update(float dt){
        size += (orig_size-score_size)*16*dt;
        parent->time = 0;
    }
};
module Game{
    Ball ball;
    float2 ball_center;
    float2 window_size;
    float2 paddle_range;
    float4 ball_range;
    Paddle paddles[2];
    float time;
};
module Menu{
    int selection;
};
module Main{
    state_machine state{
        Game game;
        Menu main_menu;
    };
};