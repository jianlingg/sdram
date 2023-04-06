`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/02 09:54:36
// Design Name: 
// Module Name: TX
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
// ��������,���յ�λ
//////////////////////////////////////////////////////////////////////////////////


module RX (
    //global clock
    input                 clk      ,
    input                 rst_n    ,

    //user interface
    input                 din  ,

    output  reg [7:0]     dout     ,
    output  reg           dout_vld      
    
);

// �Ĵ����б�
    //bps������
    reg    [12:0] cnt0     ;
    wire          add_cnt0 ;
    wire          end_cnt0 ;
    reg    [3:0]  cnt1     ;
    wire          add_cnt1 ;
    wire          end_cnt1 ;

    reg           din_ff0  ;
    reg           din_ff1  ;
    reg           din_ff2  ;
    reg           flag_add ;
    reg    [3:0]   bit     ;

   
    parameter             bps  =2604;  //��������Ϊ19200


//�������
//////////////////////////////////////////////////////////////////////////////////////

    //bps������
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
    
    assign add_cnt0 = flag_add ;
    assign end_cnt0 = add_cnt0 && cnt0 == bps - 1;
    
    //λ������2
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             cnt1 <= 0;
          end
        else if(add_cnt1)begin
          if(end_cnt1)
             cnt1 <= 0;
          else
             cnt1 <= cnt1 + 1;
        end      
    end
    
    assign add_cnt1 = end_cnt0;
    assign end_cnt1 = add_cnt1 && cnt1 == 9-1;

    //��һ����:��Ϊǰ��ǰ�ͺ����Ϊ->�½���
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            flag_add <= 0;
        end
        else if(!flag_add && !din_ff1 && din_ff2)begin
            flag_add <= 1;
        end
        else if(end_cnt1)begin 
            flag_add <= 0;
        end
    end

    //�첽�ź�ͬ����+�½��ؼ������
    always  @(posedge clk)begin
        din_ff0 <= din;
        din_ff1 <= din_ff0;
        din_ff2 <= din_ff1;
    end

    //ÿ�ֽڲ�����
    always  @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            bit <= 0;
        end
        else if(add_cnt0 && (cnt0 == bps*7/25 || cnt0 == bps*8/25 || cnt0 == bps*9/25 || cnt0 == bps*10/25 || cnt0 == bps*11/25 || cnt0 == bps*12/25 || cnt0 == bps*13/25 || cnt0 == bps*14/25 || cnt0 == bps*15/25 || cnt0 == bps*16/25) && cnt1)begin
            bit <= bit + din_ff1;
        end
        else if(end_cnt0) begin
            bit <= 0;
        end
    end

    //dout,����һ�ֽ�����
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n==1'b0)begin
            dout <= 0;
        end
        else if(add_cnt0 && cnt0 == bps*17/25 && cnt1 >= 1 && cnt1 < 9)begin
            dout[cnt1-1] <= (bit >= 5);
        end
    end

    //dout_vld
    always  @(posedge clk)begin
        if(add_cnt1 && cnt1 == 9-1) begin
            dout_vld <= 1;
        end
        else begin
            dout_vld <= 0;
        end
    end


endmodule //RX