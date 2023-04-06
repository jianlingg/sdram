/************************************************************************************
The code is designed and produced by MDY Science and Education Co., Ltd, which has the entire ownership. It is only for personal learning, which cannot be used for commercial or profit-making purposes without permission.

    MDY's Mission: Develop Chip Talents and Realize National Chip Dream.

    We sincerely hope that our students can learn the real IC / FPGA code through our standard and rigorous code.

    For more FPGA learning materials, please visit the Forum: http://fpgabbs.com/ and official website: http://www.mdy-edu.com/index.html 

    *************************************************************************************/
module sdram_intf(
    //global clock
    input              clk       ,
    input              rst_n     ,

     //user interface
//------------------------------------------------------------------------------------------
    //来自数据处理模块的
    input              wr_req    ,
    input              rd_req    ,
    input  [1 :0]      bank      ,
    input  [12:0]      addr      ,
    input  [15:0]      wdata     ,
    input  [15:0]      dq_in     ,

    output [15:0]  dq_out    ,
    output reg         dq_out_en ,
    output             wr_ack    ,
    output             rd_ack    ,
    output reg [15:0]  rdata     ,
    output reg         rdata_vld ,
    output reg         cke       ,
    output             cs        ,
    output             ras       ,
    output             cas       ,
    output             we        ,
    output reg [1 :0]  dqm       ,
    output reg [12:0]  sd_addr   ,
    output reg [1 :0]  sd_bank   ,
    output             sd_clk      
//------------------------------------------------------------------------------------------
);
    parameter NOP       = 4'b0000 ; //空操作
    parameter PER       = 4'b0001 ; //预充电
    parameter REF       = 4'b0010 ; //自动刷新
    parameter MOD       = 4'b0100 ; //配置模式寄存器
    parameter IDL       = 4'b1000 ; //空闲状态
    parameter ACT       = 4'b0011 ; //激活
    parameter RED       = 4'b0110 ; //读
    parameter WIR       = 4'b1100 ; //写
    
    parameter NOP_CMD   = 4'b0111 ; 
    parameter PER_CMD   = 4'b0010 ;
    parameter REF_CMD   = 4'b0001 ;
    parameter MOD_CMD   = 4'b0000 ;
    parameter ACT_CMD   = 4'b0011 ;
    parameter RED_CMD   = 4'b0101 ;
    parameter WIR_CMD   = 4'b0100 ;
    
    parameter ALL_BANK  = 13'b001_0_00_000_0_000;
    parameter CODE      = 13'b000_0_00_010_0_111;
    
    parameter TIME_780  = 780     ;      
    parameter TIME_WAIT = 10000   ;    
    parameter TIME_TRP  = 2       ;
    parameter TIME_TRC  = 7       ;
    parameter TIME_TMRD = 2       ;
    parameter TIME_TRCD = 2       ;
    parameter TIME_512  = 512     ;


    reg              flag_syn     ;

    reg    [3:0]     state_c      ;
    reg    [3:0]     state_n      ;
    wire             nop2per_start; 
    wire             per2ref_start; 
    wire             per2idl_start; 
    wire             ref2ref_start; 
    wire             ref2mod_start; 
    wire             ref2idl_start; 
    wire             mod2idl_start; 
    wire             idl2ref_start; 
    wire             idl2act_start; 
    wire             act2red_start; 
    wire             act2wir_start; 
    wire             red2per_start; 
    wire             wir2per_start; 
    reg    [3:0]     conmand      ;
    reg    [13:0]    cnt          ;
    wire             add_cnt      ;
    wire             end_cnt      ;
    reg    [1:0]     cnt1         ;
    wire             add_cnt1     ;
    wire             end_cnt1     ;
    reg    [9:0]     cnt_780      ;
    wire             add_cnt_780  ;
    wire             end_cnt_780  ;
    reg    [13:0]    x            ;
    reg              init_flag    ;
    reg              ref_req      ;
    wire             ref_ack      ;
    reg              flag_rd      ;
    wire             rd_en        ;
    reg              rdata_vld_ff0;
    reg              rdata_vld_ff1;
    reg              rdata_vld_ff2;


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        state_c <= NOP;
    end
    else begin
        state_c <= state_n;
    end
end

always @(*)begin
    case(state_c)
        NOP:begin
            if(nop2per_start)begin
                state_n = PER;
            end
            else begin
                state_n = state_c;
            end
        end
        PER:begin
            if(per2ref_start)begin
                state_n = REF;
            end
            else if(per2idl_start)begin
                state_n = IDL;
            end
            else begin
                state_n = state_c;
            end
        end
        REF:begin
            if(ref2ref_start)begin
                state_n = REF;
            end
            else if(ref2mod_start)begin
                state_n = MOD;
            end
            else if(ref2idl_start)begin
                state_n = IDL;
            end
            else begin
                state_n = state_c;
            end
        end
        MOD:begin
            if(mod2idl_start)begin
                state_n = IDL;
            end
            else begin
                state_n = state_c;
            end
        end
        IDL:begin
            if(idl2ref_start)begin
                state_n = REF;
            end
            else if(idl2act_start)begin
                state_n = ACT;
            end
            else begin
                state_n = state_c;
            end
        end
        ACT:begin
            if(act2red_start)begin
                state_n = RED;
            end
            else if(act2wir_start)begin
                state_n = WIR;
            end
            else begin
                state_n = state_c;
            end
        end
        RED:begin
            if(red2per_start)begin
                state_n = PER;
            end
            else begin
                state_n = state_c;
            end
        end
        WIR:begin
            if(wir2per_start)begin
                state_n = PER;
            end
            else begin
                state_n = state_c;
            end
        end
        default:begin
            state_n = IDL;
        end
    endcase
end


assign nop2per_start = state_c==NOP && end_cnt;
assign per2ref_start = state_c==PER && init_flag==1 && end_cnt;
assign ref2ref_start = state_c==REF && init_flag==1 && cnt1==0 && end_cnt;
assign ref2mod_start = state_c==REF && init_flag==1 && end_cnt1;
assign mod2idl_start = state_c==MOD && end_cnt;

assign ref2idl_start = state_c==REF && init_flag==0 && end_cnt;
assign idl2ref_start = state_c==IDL && ref_req;
assign idl2act_start = state_c==IDL && ref_req==0 && (wr_req || rd_req);
assign act2red_start = state_c==ACT && ((flag_syn==1 && flag_rd==0) || (flag_syn==0 && rd_req)) && end_cnt;
assign act2wir_start = state_c==ACT && ((flag_syn==1 && flag_rd==1) || (flag_syn==0 && wr_req)) && end_cnt;
assign red2per_start = state_c==RED && end_cnt;
assign wir2per_start = state_c==WIR && end_cnt;
assign per2idl_start = state_c==PER && init_flag==0 && end_cnt;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 0;
    end  
    else if(add_cnt)begin
        if(end_cnt)
            cnt <= 0;
        else
            cnt <= cnt + 1;
    end
end

assign add_cnt = state_c!=IDL;       
assign end_cnt = add_cnt && cnt== x-1;   


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        init_flag <= 1;
    end
    else if(mod2idl_start)begin
        init_flag <= 0;
    end
end


always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        cnt1 <= 0; 
    end
    else if(add_cnt1) begin
        if(end_cnt1)
            cnt1 <= 0; 
        else
            cnt1 <= cnt1+1 ;
   end
end
assign add_cnt1 = init_flag && state_c==REF && end_cnt;
assign end_cnt1 = add_cnt1  && cnt1 == 2-1 ;


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        flag_rd <= 0;
    end
    else if(state_c==RED)begin
        flag_rd <= 1;
    end
    else if(state_c==WIR)begin
        flag_rd <= 0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        flag_syn <= 0;
    end
    else if(state_c==ACT && wr_req && rd_req)begin
        flag_syn <= 1;
    end
    else if(end_cnt)begin
        flag_syn <= 0;
    end
end

assign rd_ack = act2red_start;
assign wr_ack = act2wir_start;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        conmand <= NOP_CMD;
    end
    else if(nop2per_start || red2per_start || wir2per_start)begin
        conmand <= PER_CMD;
    end
    else if(per2ref_start || ref2ref_start || idl2ref_start)begin
        conmand <= REF_CMD;
    end
    else if(ref2mod_start)begin
        conmand <= MOD_CMD;
    end
    else if(idl2act_start)begin
        conmand <= ACT_CMD;
    end
    else if(act2red_start)begin
        conmand <= RED_CMD;
    end
    else if(act2wir_start)begin
        conmand <= WIR_CMD;
    end
    else begin
        conmand <= NOP_CMD;
    end
end

assign {cs,ras,cas,we} = conmand;
assign sd_clk = ~clk;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dqm <= 2'b11;
    end
    else if(mod2idl_start)begin
        dqm <= 2'b00;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        cke <= 0;
    end
    else begin
        cke <= 1;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        sd_addr <= 13'b0;
    end
    else if(nop2per_start || red2per_start || wir2per_start)begin
        sd_addr <= ALL_BANK;
    end
    else if(ref2mod_start)begin
        sd_addr <= CODE;
    end
    else if(idl2act_start)begin
        sd_addr <= addr;
    end
    else begin
        sd_addr <= 13'b0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        sd_bank <= 2'b00;
    end
    else if(idl2act_start || act2wir_start || act2red_start)begin
        sd_bank <= bank;
    end
    else begin
        sd_bank <= 0;
    end
end

//变量选择器
always  @(*)begin
   case(state_c)
      NOP:      begin   x = TIME_WAIT;       end
      PER:      begin   x = TIME_TRP ;       end
      REF:      begin   x = TIME_TRC ;       end
      MOD:      begin   x = TIME_TMRD;       end
      ACT:      begin   x = TIME_TRCD;       end
      default:  begin   x = TIME_512 ;       end
   endcase
end
 

always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        cnt_780 <= 0; 
    end
    else if(add_cnt_780) begin
        if(end_cnt_780)
            cnt_780 <= 0; 
        else
            cnt_780 <= cnt_780+1 ;
   end
end
assign add_cnt_780 = !init_flag;
assign end_cnt_780 = add_cnt_780  && cnt_780 == TIME_780-1 ;

//锁存end_cnt
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        ref_req <= 0;
    end
    else if(end_cnt_780)begin
        ref_req <= 1;
    end
    else if(ref_ack)begin
        ref_req <= 0;
    end
end


assign ref_ack = state_c==IDL && ref_req;
assign wr_ack  = act2wir_start;
assign rd_ack  = act2red_start;


//发送给sdram的512个数据
assign  dq_out = wdata;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dq_out_en <= 1'b0;
    end
    else if(act2wir_start)begin
        dq_out_en <= 1'b1;
    end
    else if(end_cnt)begin
        dq_out_en <= 1'b0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rdata <= 16'b0;
    end
    else begin
        rdata <= dq_in;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rdata_vld_ff0 <= 0;
    end
    else if(act2red_start)begin
        rdata_vld_ff0 <= 1;
    end
    else if(end_cnt)begin
        rdata_vld_ff0 <= 0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rdata_vld     <= 0;
        rdata_vld_ff1 <= 0;
        rdata_vld_ff2 <= 0;
    end
    else begin
        rdata_vld_ff1 <= rdata_vld_ff0;
        rdata_vld_ff2 <= rdata_vld_ff1;
        rdata_vld     <= rdata_vld_ff2;
    end
end


endmodule
