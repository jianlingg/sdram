module sdram_top (
        //global clock
    input                 clk        ,
    input                 rst_n      ,

    //user interface
    input                 rx_uart    ,

    output                tx_uart    ,

    output                sdram_clk  ,
    output                sdram_cke  ,
    output                sdram_cs   ,
    output                sdram_ras  ,
    output                sdram_cas  ,
    output                sdram_we   ,
    output     [ 1:0]     sdram_bank ,
    output     [11:0]     sdram_addr ,
    output     [ 1:0]     sdram_dqm  ,
    input      [47:0]     sdram_dq   
       
);

//bps参数列表,这是50M，若需适配100M，需要*2，以此类推
   //5028代表波特率为  9600   
   //2604代表波特率为  19200  
   //1302代表波特率为  38400  
   //868 代表波特率为  57600  
   //434 代表波特率为  115200 
   //391 代表波特率为  128000 
   //217 代表波特率为  230400 
   //195 代表波特率为  256000 
   //107 代表波特率为  468000 
   //98  代表波特率为  512000 
   //54  代表波特率为  921600 
   //50  代表波特率为  1000000
   //49  代表波特率为  1024000
   //25  代表波特率为  2000000
    parameter             bps  =2604*2;  //代表波特率为19200

    wire clk_100;
    wire locked;

    wire  [7:0]         uart_in      ;  
	wire                uart_in_vld  ;  
	wire  [7:0]         uart_out     ;  
	wire                uart_out_vld ;   

    wire                wr_req       ;
    wire                rd_req       ;
    wire   [8:0]        wr_cnt       ;
    wire   [22:0]       wr_addr      ;
    wire   [47:0]       wr_data      ;

    wire   [47:0]       sd_data      ;
    wire                sd_data_vld  ;
    wire                rdy          ;


    pll_100 pll_100_uut(
	.areset           (!rst_n   ),
	.inclk0           (clk      ),
	.c0               (clk_100  ),
    .locked           (locked   )
    );

    RX#(.bps(bps)) RX_uut(
        //global clock
        .clk                 (clk_100     ), 
        .rst_n               (locked      ),

        //user interface
        .din                 (rx_uart     ),

        .dout                (uart_in     ),
        .dout_vld            (uart_in_vld )
    );


    data_handles data_handles_uut(
        //global clock
        .   clk        (clk_100    )   ,
        .   rst_n      (locked     )   ,

        //user interface
//---------------------------------------------------------------------------------------------------------------
        //从RX接收的数据
        .   din        (uart_in    )  ,//接收RX
        .   din_vld    (uart_in_vld)    ,//接收RX的有效指示信号

       //发送给sdram的数据
        .   wr_req     (wr_req     )     ,      //请求写
        .   rd_req     (rd_req     )     ,      //请求读
        .   wr_cnt     (wr_cnt     )     ,      //读写数量
        .   wr_addr    (wr_addr    )    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
        .   wr_data    (wr_data    )    ,      //写入sdram的数据


        //从sdram接收的数据
        .   sd_data    (sd_data    )    ,
        .   sd_data_vld(sd_data_vld),

        //从TX接收的数据
        .   rdy        (rdy        )        ,

        //发送给TX的数据
        .   dout       (uart_out    )       ,
        .   dout_vld   (uart_out_vld)           
//---------------------------------------------------------------------------------------------------------------  
    );



    sdram_c sdram_c_uut(
        //global clock
        .clk        (clk_100    ),        //系统工作时钟100MHz
        .rst_n      (locked     ),        //复位信号，低电平有效 

        //user interface 
//---------------------------------------------------------------------------------------------------------------  
        //从data_handle接收的数据
        .wr_req     (wr_req     ),        //写请求信号
        .rd_req     (rd_req     ),        //读请求信号
        .wr_cnt     (wr_cnt     ),        //读写数量输入
        .wr_addr    (wr_addr    ),        //读写地址输入
        .wr_data    (wr_data    ),        //写数据输入

       //发送给data_handle的信号
        .rd_data    (sd_data    ),        //读数据输出
        .rd_vld     (sd_data_vld),        //读数据有效指示信号

        //发送给sdram的信号
        .sdram_clk  (sdram_clk  ),        //与SDRAM管脚相连的时钟信号
        .sdram_cke  (sdram_cke  ),        //与SDRAM管脚相连的时钟使能信号

        .sdram_cs   (sdram_cs   ),        //与SDRAM管脚相连的CS信号
        .sdram_ras  (sdram_ras  ),        //与SDRAM管脚相连的RAS信号
        .sdram_cas  (sdram_cas  ),        //与SDRAM管脚相连的CAS信号
        .sdram_we   (sdram_we   ),        //与SDRAM管脚相连的WE信号

        .sdram_bank (sdram_bank ),        //与SDRAM管脚相连的BANK信号
        .sdram_addr (sdram_addr ),        //与SDRAM管脚相连的ADDR信号
        .sdram_dqm  (sdram_dqm  ),        //与SDRAM管脚相连的DQM信号
        .sdram_data (sdram_dq   )         //与SDRAM管脚相连的DQ信号
        //---------------------------------------------------------------------------------------------------------------
    );

    TX#(.bps(bps)) TX_uut(
        //global clock
        .clk                 (clk_100       ), 
        .rst_n               (locked        ),

        //user interface
        .din                 (uart_out      ),
        .din_vld             (uart_out_vld  ),

        .dout                (tx_uart       ),
        .rdy                 (rdy           )
    );

endmodule //sdram_top