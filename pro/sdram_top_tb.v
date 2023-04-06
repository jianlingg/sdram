`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: ���������Ƽ����޹�˾
// Engineer: �̽���
// 
// Create Date: 2023/03/21 13:57:09
// Design Name: sdram���ڻػ��������
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

    //����
//---------------------------------------------------------------------------------------------------------------
    reg  [7:0]     in;
    reg [35:0]     i ;
    reg flag_add;

    //ʱ�����ڣ���λΪns�����ڴ��޸�ʱ�����ڡ�
    parameter CYCLE    = 20;

    //��λʱ�䣬��ʱ��ʾ��λ3��ʱ�����ڵ�ʱ�䡣
    parameter RST_TIME = 3 ;


// uart uart_uut(
//     //global clock
//     .clk                 (clk            ), 
//     .rst_n               (rst_n          ),

//     //user interface
//     .rx_uart             (rx_uart        ),

//     .tx_uart             (tx_uart        )
// );
//ϵͳ
    //���ɱ���ʱ��50M
    initial begin
        clk = 1;
        forever
        #(CYCLE/2)
        clk=~clk;
    end 

    //������λ�ź�
    initial begin
        rst_n = 1;
        #2;
        rst_n = 0;
        #(CYCLE*RST_TIME);
        rst_n = 1;
    end

    //����ѡ����
    always  @(*)begin
       case(cnt)
        //����ff     д��dd
          0:      begin    s=8'hdd      end

        //ѡ��Ҫ��д��������0~512��
          1:      begin    s=8'd0       end
          2:      begin    s=8'd6       end

        //ѡ���ڵڼ���bank���в�����0~3��
          3:      begin    s=8'd2       end

        //ѡ���ڵڼ��н��в�����0~4096��
          4:      begin    s=8'd0       end
          4:      begin    s=8'd5       end

        //ѡ���ڵڼ��н��в�����0~512��
          6:      begin    s=8'd0       end
          7:      begin    s=8'd0       end
        
        //��д�룬���������ݣ���������������һ�������ַ���0~10��
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


    //������
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