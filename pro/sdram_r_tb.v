`timescale 1 ns/1 ns

module sdram_r_tb();
//输入
//---------------------------------------------------------------------------------------------------------------
//时钟和复位
reg clk  ;
reg rst_n;

//uut的输入信号
reg               wr_req   ;      //请求写
reg               rd_req   ;      //请求读
reg               rd_req_s ;      //请求读
reg       [ 8:0]  wr_cnt ;      //读写数量
reg       [22:0]  wr_addr;      //[21:20]sdram_bank_sdram_addr,[19:8]row_sdram_addr,[7:0]column_sdram_addr
reg       [47:0]  wr_data;      //写数据输入

//输出
//---------------------------------------------------------------------------------------------------------------
wire      [47:0]  rd_data;      //所读数据的输出
wire              rd_vld ;       //读有效
                           
wire              sdram_clk;
wire              sdram_cke;    //与SDRAM管脚相连的时钟使能信号

//命令                         
wire              sdram_cs ;    //与SDRAM管脚相连的sdram_cs信号
wire              sdram_ras;    //与SDRAM管脚相连的sdram_ras信号
wire              sdram_cas;    //与SDRAM管脚相连的sdram_信号
wire              sdram_we ;    //与SDRAM管脚相连的sdram_WE信号
                        
wire      [1 :0]  sdram_dqm ;   //与SDRAM管脚相连的sdram_dqm信号
wire      [11:0]  sdram_addr;   //与SDRAM管脚相连的sdram_ADDR信号
wire      [1:0 ]  sdram_bank;   //与SDRAM管脚相连的sdram_BAnk信号
wire      [47:0]  sdram_data;    //与SDRAM管脚相连的sdram_data信号


wire      [47:0]  dq;
reg               dq_data_en          ;             //增加此两信号，写成三态门的；——则写操作时，对dq的赋值，转换成对wr_data_en与wr_data的赋值。
reg       [47:0]  dq_data             ; 

assign  dq = dq_data_en?dq_data:48'hzzzz;
                                                    
reg       [47:0]           i             ;



        //时钟周期，单位为ns，可在此修改时钟周期。
        parameter CYCLE    = 10;

        //复位时间，此时表示复位3个时钟周期的时间。
        parameter RST_TIME = 3 ;

        //待测试的模块例化
        sdram_c sdram_c_uut(
            //global clock
            .clk        (clk      ),        //系统工作时钟100MHz
            .rst_n      (rst_n    ),        //系统复位信号，低电平有效 

            //user interface 
            .wr_req     (wr_req   ),        //写请求信号
            .rd_req     (rd_req   ),        //读请求信号
            .wr_cnt     (wr_cnt   ),        //读写数量输入
            .wr_addr    (wr_addr  ),        //读写地址输入
            .wr_data    (wr_data  ),        //写数据输入

       
            .rd_data    (rd_data  ),        //读数据输出
            .rd_vld     (rd_vld   ),        //读数据有效指示信号

            ////////////////////////////////////////////////////////////
            //// 时钟及使能
            .sdram_clk  (sdram_clk),        //与SDRAM管脚相连的时钟信号
            .sdram_cke  (sdram_cke),        //与SDRAM管脚相连的时钟使能信号

            // 命令
            .sdram_cs   (sdram_cs ),        //与SDRAM管脚相连的CS信号
            .sdram_ras  (sdram_ras),        //与SDRAM管脚相连的RAS信号
            .sdram_cas  (sdram_cas),        //与SDRAM管脚相连的CAS信号
            .sdram_we   (sdram_we ),        //与SDRAM管脚相连的WE信号

            // 地址
            .sdram_bank (sdram_bank),        //与SDRAM管脚相连的BANK信号
            .sdram_addr (sdram_addr),        //与SDRAM管脚相连的ADDR信号

            // 数据
            .sdram_dqm  (sdram_dqm),        //与SDRAM管脚相连的DQM信号
            .sdram_data (dq       )         //与SDRAM管脚相连的DQ信号
        );



    //生成本地时钟50M
    initial begin
        clk = 0;
        forever begin
            #(CYCLE/2)
            clk=~clk;
        end
    end

    //产生复位信号
    initial begin
        rst_n = 1;
        #2;
        rst_n = 0;
        #(CYCLE*RST_TIME);
        rst_n = 1;
    end

    always @(posedge clk)begin
        rd_req <= rd_req_s;
    end

    //输入信号wr_req/wr_addr/wr_data赋值方式
    initial begin
        #1;
        wr_req = 0;
        rd_req_s = 0;
        wr_addr = 0;
        wr_cnt  = 0;
        wr_data = 0;
        dq_data = 0;
        dq_data_en = 0;
        wr_addr = 23'b10_0000_0000_0101_0_0000_0001; 
        wr_cnt = 5;

        //写操作：给出写请求，要写入的地址，要写入的数据量和要写入的数据，其中写入地址和数据量不变
        #((50_000)*CYCLE);  
        

        for( i = 0 ; i < 199 ; i = i + 1)begin
                rd_req_s = (i==0 || i==100)?1:0;
                #(CYCLE*1);
            end                   
        #((20_0000)*CYCLE); 
    end

    always @(posedge clk) begin
        if(rd_req)begin
            #(CYCLE*4);

            for( i = 0 ; i < 199 ; i = i + 1)begin
                dq_data_en = 1;
                dq_data = i+10;
                #(CYCLE*1);
            end

            dq_data_en = 0;
        end
    end



endmodule