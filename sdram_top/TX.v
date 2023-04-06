`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:���������Ƽ����޹�˾
// Engineer: �̽���
// 
// Create Date: 2023/03/02 09:54:36
// Design Name: rs_485
// Module Name: TX
// Project Name: RS_485
// Target Devices: ����
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// ���ڷ���:�յ�en�źź���һ���ֽ����ݣ������ɽӿ�din���룬�ȷ���λ
//////////////////////////////////////////////////////////////////////////////////


module TX(
    //global clock
    input         clk       ,
    input         rst_n     ,

    //user interface
    input        din_vld    ,
    input  [7:0] din        ,

    output reg   rdy        ,
    output reg   dout
    
    );

// �Ĵ����б�
    //bps������
    reg    [12:0] cnt0     ;
    wire          add_cnt0 ;
    wire          end_cnt0 ;
    //λ������
    reg    [3:0]  cnt1     ;
    wire          add_cnt1 ;
    wire          end_cnt1 ;

    reg           flag_add ;
    reg    [7 :0] din_tem  ;
    wire   [9 :0] dins     ;

    parameter             bps  =2604;  //��������Ϊ19200

//�������
//////////////////////////////////////////////////////////////////////////////////////
   
    //��������Ч������δ��������ʱ����din�����ݴ�
    always  @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            din_tem <= 0;
        end
        else if(!flag_add && din_vld) begin
            din_tem <= din;
        end
        else if(end_cnt1)begin
            din_tem <= 0;
        end

    end

    //bpsʱ�Ӽ�����
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

    assign add_cnt0 = flag_add;
    assign end_cnt0 = add_cnt0 && cnt0 == bps - 1;

    //λ������
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
    assign end_cnt1 = add_cnt1 && cnt1 == 10-1;

    //��һ����
    always  @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            flag_add <= 0;
        end
        else if(!flag_add && din_vld)begin
            flag_add <= 1;
        end
        else if(end_cnt1)begin 
            flag_add <= 0;
        end
    end

    assign dins = {1'b1,din_tem,1'b0};

    //dout���ȷ��͵�λ
    always  @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dout <= 1;
        end
        else if(add_cnt0 && cnt0 == 1-1)begin
            dout <= dins[cnt1];
        end
    end

    //rdy:���ݷ����ڼ�
    always @(*)begin
        if(din_vld || flag_add)
            rdy = 0;
        else
            rdy = 1;
    end


endmodule

