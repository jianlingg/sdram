`timescale 1ns / 1ns

module data_rd_tb;
    //时钟
    reg            clk         ;
    reg            rst_n       ;

    // 输入激励
    reg   [7:0]    din         ;
    reg            din_vld     ;

    reg   [47:0]  sd_data      ;    
    reg           sd_data_vld  ;

    reg  rdy; 

    // 输出激励
    wire          wr_req ;
    wire          rd_req ;
    wire  [ 8:0]  wr_cnt ;
    wire  [22:0]  wr_addr;
    wire  [47:0]  wr_data;

    parameter CYCLE    = 10;

    //复位时间，此时表示复位3个时钟周期的时间。
    parameter RST_TIME = 3 ;

    //内用寄存器
    reg [47:0] i;

            //待测试的模块例化
data_handles data_handles_uut(
    //global clock
    .   clk        (clk)       ,
    .   rst_n      (rst_n)     ,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //从RX接收的数据
    .   din        (din)        ,//接收RX
    .   din_vld    (din_vld)    ,//接收RX的有效指示信号

   //发送给sdram的数据
    .   wr_req     (wr_req)     ,      //请求写
    .   rd_req     (rd_req)     ,      //请求读
    .   wr_cnt     (wr_cnt)     ,      //读写数量
    .   wr_addr    (wr_addr)    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    .   wr_data    (wr_data)    ,      //写入sdram的数据


    //从sdram接收的数据
    .   sd_data    (sd_data)    ,
    .   sd_data_vld(sd_data_vld),

    //从TX接收的数据
    .   rdy        (rdy)        ,

    //发送给TX的数据
    .   dout       (dout)       ,
    .   dout_vld   (dout_vld)           
//---------------------------------------------------------------------------------------------------------------  
);


    // 生产本地时钟50M
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

    //读出ff，6个数据，地址是：bank2,第5行，第1列  
    //sd_addr:10__0000_0000_0101__0_0000_0001 D:4,196,865
    initial begin
    #1;
    rdy=1;
    din = 0;
    din_vld = 0;
    sd_data = 0;
    sd_data_vld = 0;
    
    #(CYCLE*10);
    din = 8'hff;//r/w:dd是写。ff是读
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
    din = 8'd5;//rowl  0~4095,连
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
    din = 8'd1;//coll  0~511,连
    #(CYCLE*10);
    din_vld = 1;
    #(CYCLE*1);
    din_vld = 0;
    #(CYCLE*10);
    din = 0;

    #(CYCLE*10);
    din = 8'd1;//无用
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