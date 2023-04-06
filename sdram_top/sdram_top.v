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

    inout  [15:0]  dq       ,//��̬��

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
//bps�����б�,����50M����������100M����Ҫ*2���Դ�����
   //5028��������Ϊ  9600   
   //2604��������Ϊ  19200  
   //1302��������Ϊ  38400  
   //868 ��������Ϊ  57600  
   //434 ��������Ϊ  115200 
   //391 ��������Ϊ  128000 
   //217 ��������Ϊ  230400 
   //195 ��������Ϊ  256000 
   //107 ��������Ϊ  468000 
   //98  ��������Ϊ  512000 
   //54  ��������Ϊ  921600 
   //50  ��������Ϊ  1000000
   //49  ��������Ϊ  1024000
   //25  ��������Ϊ  2000000
    parameter             bps  =2604*2;  //��������Ϊ19200


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



assign  dq_in = dq; //��̬���룬��
    assign  dq   = dq_out_en?dq_out:16'hzzzz; //��̬�����д


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
        //���͵������ϵ�led
        .   led       (led      ),

        //��sdram���յ�����
        .   sd_data    (sd_data    )    ,
        .   sd_data_vld(sd_data_vld),

        //��TX���յ�����
        .   rdy        (rdy        )        ,

        //���͸�TX������
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

        .wdata     (wdata    ),//�����ݴ������ɵ����ݣ�Ҫ����sdram
        .dq_out    (dq_out   ),//wdata = dq_out
        .dq_out_en (dq_out_en),//�����ݴ������ɵ�

        .dq_in     (dq_in    ),//��sdram�������ź�,��ת��rdata,�ӳ�һ��

        .rdata     (sd_data    ),//��dq_in����
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

