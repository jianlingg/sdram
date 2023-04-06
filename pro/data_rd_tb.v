`timescale 1ns / 1ns

module data_rd_tb;
    //ʱ��
    reg            clk         ;
    reg            rst_n       ;

    // ���뼤��
    reg   [7:0]    din         ;
    reg            din_vld     ;

    reg   [47:0]  sd_data      ;    
    reg           sd_data_vld  ;

    reg  rdy; 

    // �������
    wire          wr_req ;
    wire          rd_req ;
    wire  [ 8:0]  wr_cnt ;
    wire  [22:0]  wr_addr;
    wire  [47:0]  wr_data;

    parameter CYCLE    = 10;

    //��λʱ�䣬��ʱ��ʾ��λ3��ʱ�����ڵ�ʱ�䡣
    parameter RST_TIME = 3 ;

    //���üĴ���
    reg [47:0] i;

            //�����Ե�ģ������
data_handles data_handles_uut(
    //global clock
    .   clk        (clk)       ,
    .   rst_n      (rst_n)     ,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //��RX���յ�����
    .   din        (din)        ,//����RX
    .   din_vld    (din_vld)    ,//����RX����Чָʾ�ź�

   //���͸�sdram������
    .   wr_req     (wr_req)     ,      //����д
    .   rd_req     (rd_req)     ,      //�����
    .   wr_cnt     (wr_cnt)     ,      //��д����
    .   wr_addr    (wr_addr)    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    .   wr_data    (wr_data)    ,      //д��sdram������


    //��sdram���յ�����
    .   sd_data    (sd_data)    ,
    .   sd_data_vld(sd_data_vld),

    //��TX���յ�����
    .   rdy        (rdy)        ,

    //���͸�TX������
    .   dout       (dout)       ,
    .   dout_vld   (dout_vld)           
//---------------------------------------------------------------------------------------------------------------  
);


    // ��������ʱ��50M
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

    //����ff��6�����ݣ���ַ�ǣ�bank2,��5�У���1��  
    //sd_addr:10__0000_0000_0101__0_0000_0001 D:4,196,865
    initial begin
    #1;
    rdy=1;
    din = 0;
    din_vld = 0;
    sd_data = 0;
    sd_data_vld = 0;
    
    #(CYCLE*10);
    din = 8'hff;//r/w:dd��д��ff�Ƕ�
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd0;//wr_cnth
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd6;//wr_cntl
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd2;//bank0~3
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd0;//rowh
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd5;//rowl  0~4095,��
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd0;//colh
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd1;//coll  0~511,��
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd1;//����
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;


    // for( i = 0 ; i < 100 ; i = i + 1)begin//write
    // #(CYCLE*10);
    // din = i+10;//data  0~256
    // #(CYCLE*10);
    // din_vld = 1;
    // #(CYCLE*1);
    // din_vld = 0;
    // #(CYCLE*10);
    // din = 0;
    // end
 
    #(CYCLE*1000000);
    end

    always @(posedge clk) begin//read
        if(rd_req)begin
            #(CYCLE*3);
            sd_data_vld = 1;
            #(CYCLE*1);

            for( i = 0 ; i < 6 ; i = i + 1)begin
                sd_data = i+10;//data  0~256
                #(CYCLE*1);
            end

            sd_data_vld = 0;
        end
    end
endmodule