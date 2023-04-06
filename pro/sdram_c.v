

module sdram_c 
 #(
     parameter DATA_WIDTH = 48,                                  // 数据位宽
     parameter BANK_WIDTH = 2,                                   // bank地址位宽
     parameter ROW_WIDTH  = 12,                                  // 行地址位宽
     parameter COLU_WIDTH = 9,                                   // 列地址位宽
     parameter ADDR_WIDTH = BANK_WIDTH + ROW_WIDTH + COLU_WIDTH  // 地址位宽
//     parameter REFRESH_RATE = 1000000,              // 刷新频率
//     parameter T_RCD = 3,                          // RAS到CAS延迟
//     parameter T_RAS = 6,                          // 行地址选择时间
//     parameter T_RC = 7                            // 行周期时间
)

(
    //global clock
    input clk,
    input rst_n,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //从data_handle接收的数据
    input                         wr_req ,      //请求写
    input                         rd_req ,      //请求读
    input       [ 8:0]            wr_cnt ,      //读写数量
    input       [ADDR_WIDTH-1:0]  wr_addr,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    input       [DATA_WIDTH-1:0]  wr_data,      //写数据输入

    //发送给data_handle的信号
    output  reg [DATA_WIDTH-1:0]  rd_data,      //所读数据的输出
    output  reg                   rd_vld,       //读有效
    
    //发送给sdram的信号
    output                        sdram_clk,    //sdram的时钟
    output                        sdram_cke,    //与SDRAM管脚相连的时钟使能信号
                                                        
    output                        sdram_cs ,    //与SDRAM管脚相连的sdram_cs信号
    output                        sdram_ras,    //与SDRAM管脚相连的sdram_ras信号
    output                        sdram_cas,    //与SDRAM管脚相连的sdram_信号
    output                        sdram_we ,    //与SDRAM管脚相连的sdram_WE信号
                                                
    output  reg [1 :0]            sdram_dqm ,   //与SDRAM管脚相连的sdram_dqm信号
    output  reg [11:0]            sdram_addr,   //与SDRAM管脚相连的sdram_ADDR信号
    output  reg [1:0 ]            sdram_bank,   //与SDRAM管脚相连的sdram_BAnk信号
    inout       [DATA_WIDTH-1:0]  sdram_data    //与SDRAM管脚相连的sdram_data信号
//---------------------------------------------------------------------------------------------------------------
);

//所用时间
parameter     T_200us = 20_000 ;//初始化NOP延时
parameter     T_trp   = 2      ;//预充电延时
parameter     T_trc   = 7      ;//自动刷新延时
parameter     T_tmrd  = 2      ;//加载模式延时
parameter     T_1300  = 1300   ;//自动刷新周期
parameter     T_trcd  = 2      ;//激活延时

//命令
parameter      nop             = 4'b0111;
parameter      precharge       = 4'b0010;
parameter      auto_refresh    = 4'b0001;
parameter      mode_config     = 4'b0000;
parameter      active          = 4'b0011;
parameter      write           = 4'b0100;
parameter      read            = 4'b0101;
parameter      burst_terminate = 4'b0110;

//模式寄存器的值
parameter mode_value = 12'b00_0_00_010_0_111;//burst模式，标准操作，输出延时2，burst类型为顺序，burst长度为全页
parameter all_bank   = 12'b01_0_00_000_0_000;
//状态
localparam  S1  = 1 ;//初始化NOP
localparam  S2  = 2 ;//初始化预充电
localparam  S3  = 3 ;//初始化自动刷新1
localparam  S4  = 4 ;//初始化自动刷新2
localparam  S5  = 5 ;//初始化加载模式
localparam  S6  = 6 ;//IDLE状态
localparam  S7  = 7 ;//刷新状态
localparam  S8  = 8 ;//写激活
localparam  S9  = 9 ;//写状态
localparam  S10 = 10;//读激活
localparam  S11 = 11;//读状态



reg [15:0] cnt0;
wire       add_cnt0;
wire       end_cnt0;
reg [15:0] x;
reg [15:0] cnt1;
wire       add_cnt1;
wire       end_cnt1;


reg [4:0 ]         state_c;
reg [4:0 ]         state_n;
reg [3:0 ]         command;
reg [ADDR_WIDTH-1:0] wr_addr_temp;
reg [DATA_WIDTH-1:0] wr_data_ff0; 
reg [DATA_WIDTH-1:0] wr_data_ff1;
reg [DATA_WIDTH-1:0] wr_data_ff2;

reg [ 8:0] wr_cnt_temp;

wire s1_to_s2_start ;
wire s2_to_s3_start ;
wire s3_to_s4_start ;
wire s4_to_s5_start ;
wire s5_to_s6_start ;
wire s6_to_s7_start ;
wire s6_to_s8_start ;
wire s6_to_s10_start ;
wire s7_to_s6_start ;
wire s8_to_s9_start ;
wire s9_to_s6_start ;
wire s10_to_s11_start ;
wire s11_to_s6_start ;


wire init_state = state_c == S1 || state_c == S2 || state_c == S3 || state_c == S4 || state_c == S5;
wire wr_en;

//sdram所用时钟
assign sdram_clk = !clk;
//使能时钟设计
assign sdram_cke = 1;


//状态机
always @(posedge clk or negedge rst_n) begin
    if (rst_n==0)
        state_c <= S1 ;
    else
        state_c <= state_n;
end

always @(*) begin
    case(state_c)
        S1 :begin
            if(s1_to_s2_start)
                state_n = S2 ;
            else
                state_n = state_c ;
        end
        S2 :begin
            if(s2_to_s3_start)
                state_n = S3 ;
            else
                state_n = state_c ;
        end
        S3 :begin
            if(s3_to_s4_start)
                state_n = S4 ;
            else
                state_n = state_c ;
        end
        S4 :begin
            if(s4_to_s5_start)
                state_n = S5 ;
            else
                state_n = state_c ;
        end
        S5 :begin
            if(s5_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S6 :begin
            if(s6_to_s7_start)
                state_n = S7 ;
            else if(s6_to_s8_start)
                state_n = S8 ;
            else if(s6_to_s10_start)
                state_n = S10 ;
            else
                state_n = state_c ;
        end
        S7 :begin
            if(s7_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S8 :begin
            if(s8_to_s9_start)
                state_n = S9 ;
            else
                state_n = state_c ;
        end
        S9 :begin
            if(s9_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S10 :begin
            if(s10_to_s11_start)
                state_n = S11 ;
            else
                state_n = state_c ;
        end
        S11 :begin
            if(s11_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        default : state_n = S1 ;
    endcase
end

assign s1_to_s2_start   = state_c==S1  && (end_cnt0);
assign s2_to_s3_start   = state_c==S2  && (end_cnt0);
assign s3_to_s4_start   = state_c==S3  && (end_cnt0);
assign s4_to_s5_start   = state_c==S4  && (end_cnt0);
assign s5_to_s6_start   = state_c==S5  && (end_cnt0);
assign s6_to_s7_start   = state_c==S6  && (end_cnt1);//记1300的刷新时间
assign s6_to_s8_start   = state_c==S6  && (wr_req && !s6_to_s7_start && !rd_req);//非刷非读，有写可
assign s6_to_s10_start  = state_c==S6  && (rd_req && !s6_to_s7_start);//非刷有写，可
assign s7_to_s6_start   = state_c==S7  && (end_cnt0);//需要trc时间

assign s8_to_s9_start   = state_c==S8  && (end_cnt0);//需要trcd时间
assign s9_to_s6_start   = state_c==S9  && (end_cnt0);//需要突发终止命令
assign s10_to_s11_start = state_c==S10 && (end_cnt0);//需要trcd时间
assign s11_to_s6_start  = state_c==S11 && (end_cnt0);//需要突发终止命令

//变量选择器
always  @(*)begin
   case(state_c)
      S1:      begin      x=T_200us        ;      end//nop
      S2:      begin      x=T_trp          ;      end//per
      S3:      begin      x=T_trc          ;      end//ref
      S4:      begin      x=T_trc          ;      end//ref
      S5:      begin      x=T_tmrd         ;      end//mod
      S7:      begin      x=T_trc          ;      end//ref
      S8:      begin      x=T_trcd         ;      end//act
      S9:      begin      x=wr_cnt_temp    ;      end//red
      S10:     begin      x=T_trcd         ;      end//act
      S11:     begin      x=wr_cnt_temp    ;      end//wir
      default: begin      x=T_200us        ;      end
   endcase
end

// 计数器1
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
         cnt0 <= 0;
    end
    else if(add_cnt0)begin
      if(end_cnt0)
         cnt0 <= 0;
      else
         cnt0 <= cnt0 + 1;
    end      
end

assign add_cnt0 = state_c != S6;
assign end_cnt0 = add_cnt0 && cnt0 == x-1;


//计数器2:统计自动刷新的时间
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
         cnt1 <= 0;
      end
    else if(state_c!= S6 && end_cnt1)begin//状态非空闲且到达刷新计数终值，就锁存终值，直到回到空闲，下个周期，cnt1<=0
         cnt1 <= cnt1;
    end
    else if(add_cnt1)begin
      if(end_cnt1)
         cnt1 <= 0;
      else
         cnt1 <= cnt1 + 1;
    end      
end

assign add_cnt1  = !init_state;
assign end_cnt1  = add_cnt1 && cnt1 == T_1300-1;
//在读写态，并且到了默认刷新时，需要打破默认刷新的时间，将其延长到读写完毕
/*理解：就是说本该在空闲态且计数满跳到刷新态，但因为在在读写态，所以暂时不能跳转到刷新态，同时因为跳转到刷新态的条件是
本身处在空闲态且计数满，空闲态这一条件读写完毕后就自动跳转了，计数满这一条件就需要锁存计数满的条件
*/

//读写数量
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_cnt_temp <= 0;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin
        wr_cnt_temp <= wr_cnt;
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//命令赋予 没问题
assign {sdram_cs,sdram_ras,sdram_cas,sdram_we} = command;

always  @(posedge clk)begin
    if(s1_to_s2_start)begin //100usnop操作结束后，发出预充电命令
        command <= precharge;
    end
    else if(s2_to_s3_start || s3_to_s4_start || s6_to_s7_start) begin
        command <= auto_refresh;
    end
    else if(s4_to_s5_start)begin
        command <= mode_config;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin//检测到读写信号后，发出激活命令
        command <= active;
    end
    else if(s8_to_s9_start)begin
        command <= write;
    end
    else if(s10_to_s11_start)begin
        command <= read;
    end
    else if(s9_to_s6_start || s11_to_s6_start)begin//读写完成后给出突发终止命令
        command <= burst_terminate;
    end
    else begin
        command <= nop;
    end
end

//sdram_addr缓存 没问题 
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        wr_addr_temp <= 23'b0;
    end
    else if(wr_req || rd_req)begin
        wr_addr_temp <= wr_addr;
    end
end

//A0-A9,A11，即sdram_addr，只持续一个周期
always  @(posedge clk )begin
    if(s1_to_s2_start)begin
        sdram_addr <= all_bank;            //或sdram_addr[10] <= 1;
    end
    else if(s4_to_s5_start)begin
        sdram_addr <= mode_value;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin//解析出row_sdram_addr,因为要同步激活态输出，所以并不需要缓存该数据
        sdram_addr <= wr_addr[20:9];
    end
    else if(s8_to_s9_start || s10_to_s11_start)begin//解析出column_sdram_addr，因为要在激活态后的读写态赋值，所以需要用到缓存保存的数据
        sdram_addr <= {3'b0, wr_addr_temp[8:0]};
    end
    else begin
        sdram_addr <= 0;
    end
end

//sdram_dqm数据掩码设计
always  @(posedge clk)begin 
    if(init_state)begin
        sdram_dqm <= 2'b11;
    end
    else begin
        sdram_dqm <= 2'b00;
    end
end

//sdram_bank
always  @(posedge clk)begin
    if(s6_to_s8_start|| s6_to_s10_start)begin
        sdram_bank <= wr_addr[22:21];
    end
    else if(s8_to_s9_start || s10_to_s11_start)begin
        sdram_bank <= wr_addr_temp[22:21];
    end
    else begin
        sdram_bank <= 0;
    end
end


//wr_data延时
always  @(posedge clk )begin
    wr_data_ff0 <= wr_data;
    wr_data_ff1 <= wr_data_ff0;
    wr_data_ff2 <= wr_data_ff1;
end

//sdram_data 写入
assign wr_en = state_c == S8 || state_c == S9;
assign sdram_data   = wr_en ? wr_data_ff2 : 48'hzzzz;

//rd 读出，sdram_data -> rd_data
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_data <= 16'b0;
    end
    else begin
        rd_data <= sdram_data;
    end
end

//读有效
always  @(posedge clk )begin
    if(state_c == S11 && cnt0 == 2-1)begin
        rd_vld <= 1;
    end
    else if((state_c == S6 && cnt0 == 2-1)|| (state_c ==S1))begin
        rd_vld <= 0;
    end
end

endmodule 


