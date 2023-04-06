/************************************************************************************
The code is designed and produced by MDY Science and Education Co., Ltd, which has the entire ownership. It is only for personal learning, which cannot be used for commercial or profit-making purposes without permission.

    MDY's Mission: Develop Chip Talents and Realize National Chip Dream.

    We sincerely hope that our students can learn the real IC / FPGA code through our standard and rigorous code.

    For more FPGA learning materials, please visit the Forum: http://fpgabbs.com/ and official website: http://www.mdy-edu.com/index.html 

    *************************************************************************************/
module sdram_top(
    //global clock
    input          clk      ,
    input          rst_n    ,

    input  [3:0]   key      ,

    inout  [15:0]  dq       ,//三态门

    output         cke      ,
    output         cs       ,  
    output         ras      ,
    output         cas      ,
    output         we       ,
    output [1 :0]  dqm      ,
    output [12:0]  sd_addr  ,
    output [1 :0]  sd_bank  ,
    output         sd_clk   ,
    
    output [3:0]   led      ,

    output         tx_uart    
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


wire              clk_100m ;
    wire              wr_ack   ;
    wire              rd_ack   ;
    wire              wr_req   ;
    wire              rd_req   ;
    wire [1 :0]       bank     ;
    wire [12:0]       addr     ;

    wire [15:0]       wdata    ;
    wire [15:0]       sd_data    ;
    wire              sd_data_vld;
    wire [3:0 ]       key_vld  ;

    wire [15:0]       dq_in    ;
    wire [15:0]       dq_out   ;
    wire              dq_out_en;

    wire  [7:0]       uart_out     ;  
	wire              uart_out_vld ; 



assign  dq_in = dq; //三态输入，读
    assign  dq   = dq_out_en?dq_out:16'hzzzz; //三态输出，写


    pll_100m pll_u(
    	.inclk0    (clk      ),
    	.c0        (clk_100m )
    );
     
    data_ctrl ctrl_u(
        .   clk       (clk_100m ), 
        .   rst_n     (rst_n    ),
        .   key       (key      ),
        .   wr_ack    (wr_ack   ),   
        .   rd_ack    (rd_ack   ),   
        .   wr_req    (wr_req   ),   
        .   rd_req    (rd_req   ),   
        .   bank      (bank     ),   
        .   addr      (addr     ),    
        .   wdata     (wdata    ),
        //发送到板子上的led
        .   led       (led      ),

        //从sdram接收的数据
        .   sd_data    (sd_data    )    ,
        .   sd_data_vld(sd_data_vld),

        //从TX接收的数据
        .   rdy        (rdy        )        ,

        //发送给TX的数据
        .   dout       (uart_out    )       ,
        .   dout_vld   (uart_out_vld)             
        );
    
    sdram_intf sdram_u(
        .clk       (clk_100m ),   
        .rst_n     (rst_n    ),
        .wr_req    (wr_req   ),
        .rd_req    (rd_req   ),
        .bank      (bank     ),
        .addr      (addr     ),

        .wdata     (wdata    ),//从数据处理生成的数据，要发往sdram
        .dq_out    (dq_out   ),//wdata = dq_out
        .dq_out_en (dq_out_en),//从数据处理生成的

        .dq_in     (dq_in    ),//从sdram读出的信号,流转到rdata,延迟一拍

        .rdata     (sd_data    ),//和dq_in连接
        .rdata_vld (sd_data_vld),      

        .wr_ack    (wr_ack   ),
        .rd_ack    (rd_ack   ),
        .cke       (cke      ),
        .cs        (cs       ),
        .ras       (ras      ),
        .cas       (cas      ),
        .we        (we       ),
        .dqm       (dqm      ),
        .sd_addr   (sd_addr  ),
        .sd_bank   (sd_bank  ),
        .sd_clk    (sd_clk   )  
        
    );

    TX#(.bps(bps)) TX_uut(
        //global clock
        .clk                 (clk_100m      ), 
        .rst_n               (rst_n         ),

        //user interface
        .din                 (uart_out       ),
        .din_vld             (uart_out_vld   ),

        .dout                (tx_uart       ),
        .rdy                 (rdy           )
    );



    endmodule

