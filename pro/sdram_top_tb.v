`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 苏州索拉科技有限公司
// Engineer: 程江博
// 
// Create Date: 2023/03/21 13:57:09
// Design Name: sdram串口回环顶层测试
// Module Name: sdram_top_tb
// Project Name: sdram
// Target Devices: MP801
// Tool Versions: Quartus Prime 22.1std
// Description: 
// 
// Dependencies: 
// 
// Revision:0.01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module sdram_top_tb ;
    //global clock
    reg            clk         ;
    reg            rst_n       ;

    //user interface
    reg            rx_uart     ;

    wire           tx_uart     ;

    //变量
//---------------------------------------------------------------------------------------------------------------
    reg  [7:0]     in;
    reg [35:0]     i ;
    reg flag_add;

    //时钟周期，单位为ns，可在此修改时钟周期。
    parameter CYCLE    = 20;

    //复位时间，此时表示复位3个时钟周期的时间。
    parameter RST_TIME = 3 ;


// uart uart_uut(
//     //global clock
//     .clk                 (clk            ), 
//     .rst_n               (rst_n          ),

//     //user interface
//     .rx_uart             (rx_uart        ),

//     .tx_uart             (tx_uart        )
// );
//系统
    //生成本地时钟50M
    initial begin
        clk = 1;
        forever
        #(CYCLE/2)
        clk=~clk;
    end 

    //产生复位信号
    initial begin
        rst_n = 1;
        #2;
        rst_n = 0;
        #(CYCLE*RST_TIME);
        rst_n = 1;
    end

    //变量选择器
    always  @(*)begin
       case(cnt)
        //读：ff     写：dd
          0:      begin    s=8'hdd      end

        //选择要读写的数量（0~512）
          1:      begin    s=8'd0       end
          2:      begin    s=8'd6       end

        //选择在第几个bank进行操作（0~3）
          3:      begin    s=8'd2       end

        //选择在第几行进行操做（0~4096）
          4:      begin    s=8'd0       end
          4:      begin    s=8'd5       end

        //选择在第几列进行操作（0~512）
          6:      begin    s=8'd0       end
          7:      begin    s=8'd0       end
        
        //若写入，则输入数据；若读出，则输送一个结束字符（0~10）
          8:      begin    s=8'd3       end
          9:      begin    s=8'd55      end
          default:begin    s=8'd66      end
       endcase
    end

    initial begin
        #1
        #(CYCLE*26);
        s=8'hdd
        for( i = 0 ; i < 66 ; i = i + 1)begin
            rx_uart = 1;
            #(10*CYCLE);
            rx_uart = 0;
            #(CYCLE*2604*2);

            rx_uart = s[0];//1
            #(CYCLE*2604*2);
            rx_uart = s[1];//1
            #(CYCLE*2604*2);
            rx_uart = s[2];
            #(CYCLE*2604*2);
            rx_uart = s[3];
            #(CYCLE*2604*2);
            rx_uart = s[4];
            #(CYCLE*2604*2);
            rx_uart = s[5];
             #(CYCLE*2604*2);
            rx_uart = s[6];
            #(CYCLE*2604*2);
            rx_uart = s[7];
            #(CYCLE*2604*2);

            rx_uart = 1;
            #(CYCLE*2604*2);
            #(CYCLE*2604*2*18);

            flag_add = 1;
            #(CYCLE);
            flag_add = 0;
        end
    end


    //计数器
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
    
    assign add_cnt = flag_add;
    assign end_cnt = add_cnt && cnt == 12-1;



endmodule //sdram_top_tb