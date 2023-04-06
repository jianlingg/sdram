`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/03 13:57:09
// Design Name: 
// Module Name: RX_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RX_tb;
    reg            clk         ;
    reg            rst_n       ;
    reg            din         ;

    wire  [7:0]    dout        ;
    wire           dout_vld    ;
    reg [18:0] i;
    reg [7:0] s;

        //ʱ�����ڣ���λΪns�����ڴ��޸�ʱ�����ڡ�
        parameter CYCLE    = 20;

        //��λʱ�䣬��ʱ��ʾ��λ3��ʱ�����ڵ�ʱ�䡣
        parameter RST_TIME = 3 ;

        //�����Ե�ģ������
        RX uut(
            //global clock
            .clk                 (clk            ), 
            .rst_n               (rst_n          ),

            //user interface
            .din                 (din            ),

            .dout                (dout           ),
            .dout_vld            (dout_vld       )
            );


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
 


   initial begin
        #1
      for( i = 0 ; i < 10 ; i = i + 1)begin
        s = i+5;
        din = 1;
        #(10*CYCLE);
        din = 0;
        #(CYCLE*2604);

        din = s[0];//1
        #(CYCLE*2604);
        din = s[1];//1
        #(CYCLE*2604);
        din = s[2];
        #(CYCLE*2604);
        din = s[3];
        #(CYCLE*2604);
        din = s[4];
        #(CYCLE*2604);
        din = s[5];
         #(CYCLE*2604);
        din = s[6];
        #(CYCLE*2604);
        din = s[7];
        #(CYCLE*2604);

        din = 1;
        #(CYCLE*2604);
        #(CYCLE*2604*18);
         end
    end         
endmodule
