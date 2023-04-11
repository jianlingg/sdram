/*例化板

key key_u(
    //global clock
    . clk(clk),
    . rst_n(rst_n),

    //use interface
    . key(key),
    . key_vld(key_vld)
);

);


*/
module key 
#(
    parameter t_20ms  = 2000_000  //100m
)
(
    //global clock 100 Mhz
    input clk,
    input rst_n,

    //use interface
    input    key,
    output  reg key_vld 
);


    reg [2:0]state_c;
    reg [2:0]state_n;
    wire ide_to_dwx_start ;
    wire dwx_to_ide_start ;
    wire dwx_to_wat_start ;
    wire wat_to_upx_start ;
    wire upx_to_wat_start ;
    wire upx_to_ide_start ;

    wire add_cnt;
    wire end_cnt;
    reg [20:0] cnt;


    localparam  ide = 1;
    localparam  dwx = 2;
    localparam  wat = 3;
    localparam  upx = 4;

    reg  [1:0] key_s;
    wire up_edge = key_s == 2'b01;
    wire dw_edge = key_s == 2'b10;
//key signal 流转两个寄存器，为检测边沿
always  @(posedge clk)begin
    key_s <= {key_s[0],key};
end

always @(posedge clk )begin
    if(dwx_to_wat_start)begin
        key_vld <= 1;
    end
    else begin
        key_vld <= 0;
    end
end

//计数器:20ms
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt <= 0;
      end
    else if(!add_cnt)begin
        cnt <= 0;
    end
    else if(add_cnt)begin
      if(end_cnt)
         cnt <= 0;
      else
         cnt <= cnt + 1;
      end      
end

assign add_cnt = state_c == dwx || state_c == upx;
assign end_cnt = add_cnt && cnt == t_20ms-1;

//状态机
always @(posedge clk or negedge rst_n) begin
    if (rst_n==0)
            state_c <= ide ;
    else
        state_c <= state_n;
end
always @(*) begin
    case(state_c)
        ide :begin
            if(ide_to_dwx_start)
                state_n = dwx ;
            else
                state_n = state_c ;
        end
        dwx :begin
            if(dwx_to_ide_start)
                state_n = ide ;
            else if(dwx_to_wat_start)
                state_n = wat ;
            else
                state_n = state_c ;
        end
        wat :begin
            if(wat_to_upx_start)
                state_n = upx ;
            else
                state_n = state_c ;
        end
        upx :begin
            if(upx_to_wat_start)
                state_n = wat ;
            else if(upx_to_ide_start)
                state_n = ide ;
            else
                state_n = state_c ;
        end
        default : state_n = ide ;
    endcase
end

assign ide_to_dwx_start = state_c==ide && (dw_edge);
assign dwx_to_ide_start = state_c==dwx && (up_edge);
assign dwx_to_wat_start = state_c==dwx && (end_cnt);
assign wat_to_upx_start = state_c==wat && (up_edge);
assign upx_to_wat_start = state_c==upx && (dw_edge);
assign upx_to_ide_start = state_c==upx && (end_cnt);
endmodule
