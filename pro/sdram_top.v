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
        //��RX���յ�����
        .   din        (uart_in    )  ,//����RX
        .   din_vld    (uart_in_vld)    ,//����RX����Чָʾ�ź�

       //���͸�sdram������
        .   wr_req     (wr_req     )     ,      //����д
        .   rd_req     (rd_req     )     ,      //�����
        .   wr_cnt     (wr_cnt     )     ,      //��д����
        .   wr_addr    (wr_addr    )    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
        .   wr_data    (wr_data    )    ,      //д��sdram������


        //��sdram���յ�����
        .   sd_data    (sd_data    )    ,
        .   sd_data_vld(sd_data_vld),

        //��TX���յ�����
        .   rdy        (rdy        )        ,

        //���͸�TX������
        .   dout       (uart_out    )       ,
        .   dout_vld   (uart_out_vld)           
//---------------------------------------------------------------------------------------------------------------  
    );



    sdram_c sdram_c_uut(
        //global clock
        .clk        (clk_100    ),        //ϵͳ����ʱ��100MHz
        .rst_n      (locked     ),        //��λ�źţ��͵�ƽ��Ч 

        //user interface 
//---------------------------------------------------------------------------------------------------------------  
        //��data_handle���յ�����
        .wr_req     (wr_req     ),        //д�����ź�
        .rd_req     (rd_req     ),        //�������ź�
        .wr_cnt     (wr_cnt     ),        //��д��������
        .wr_addr    (wr_addr    ),        //��д��ַ����
        .wr_data    (wr_data    ),        //д��������

       //���͸�data_handle���ź�
        .rd_data    (sd_data    ),        //���������
        .rd_vld     (sd_data_vld),        //��������Чָʾ�ź�

        //���͸�sdram���ź�
        .sdram_clk  (sdram_clk  ),        //��SDRAM�ܽ�������ʱ���ź�
        .sdram_cke  (sdram_cke  ),        //��SDRAM�ܽ�������ʱ��ʹ���ź�

        .sdram_cs   (sdram_cs   ),        //��SDRAM�ܽ�������CS�ź�
        .sdram_ras  (sdram_ras  ),        //��SDRAM�ܽ�������RAS�ź�
        .sdram_cas  (sdram_cas  ),        //��SDRAM�ܽ�������CAS�ź�
        .sdram_we   (sdram_we   ),        //��SDRAM�ܽ�������WE�ź�

        .sdram_bank (sdram_bank ),        //��SDRAM�ܽ�������BANK�ź�
        .sdram_addr (sdram_addr ),        //��SDRAM�ܽ�������ADDR�ź�
        .sdram_dqm  (sdram_dqm  ),        //��SDRAM�ܽ�������DQM�ź�
        .sdram_data (sdram_dq   )         //��SDRAM�ܽ�������DQ�ź�
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