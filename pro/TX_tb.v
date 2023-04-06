`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/02 14:50:18
// Design Name: 
// Module Name: TX_tb
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


module TX_tb;
reg       clk         ;
reg       rst_n       ;

reg       din_vld     ;
reg [7:0] s;
reg [18:0] i;

wire      dout     ;
wire      rdy         ;

 //ʱ�����ڣ���λΪns�����ڴ��޸�ʱ�����ڡ�
        parameter CYCLE    = 20;

        //��λʱ�䣬��ʱ��ʾ��λ3��ʱ�����ڵ�ʱ�䡣
        parameter RST_TIME = 3 ;

        //�����Ե�ģ������
        TX uut(
            //global clock
            .clk                 (clk            ), 
            .rst_n               (rst_n          ),

            //user interface
            .din_vld             (din_vld        ),
            .din                 (s              ),

            .dout                (dout           ),
            .rdy                 (rdy            )
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
      din_vld = 0;
      #(10*CYCLE);
      din_vld = 1;
      #(CYCLE);
      din_vld = 0;
      
      #(CYCLE*2604*16);
      #(10*CYCLE);
      din_vld = 1;
      #(CYCLE);
      din_vld = 0;
    end

    initial begin
        #1
        for( i = 0 ; i < 10 ; i = i + 1)begin
            s = i+5;
            #(CYCLE*2604*16);
        end
    end


    
endmodule
