/*

按下k1,向sdram写入512个数据
按下k2,读出一页数据，通过串口显示到pc
按下k3,bank+1

*/
module data_ctrl(
    //global clock
    input                clk     ,
    input                rst_n   ,

    //user interface
//------------------------------------------------------------------------------------------
    //4个按键
    input        [3:0]   key ,

    //从sdram_c 反馈回来的读写响应信号
    input                wr_ack  , 
    input                rd_ack  ,

    //从sdram接收的数据
    input        [15:0]  sd_data    ,
    input                sd_data_vld,

    //从TX接收的数据
    input                rdy        ,

    //发送给TX的数据
    output  reg  [ 7:0]  dout       ,
    output  reg          dout_vld   ,

    //送往sdram_c的读写请求信号和数据，地址
    output  reg          wr_req  ,
    output  reg          rd_req  ,
    output  reg  [1:0]   bank    ,
    output       [12:0]  addr    ,
    output  reg  [15:0]  wdata   ,
    
    output       [3:0 ]  led
//------------------------------------------------------------------------------------------
);

wire   [3:0]   key_vld  ; 
reg            flag_wr  ;
reg    [9:0]   cnt0     ;
wire           add_cnt0 ;
wire           end_cnt0 ;
wire           add_bank ;
wire           end_bank ;

reg rd;
reg wr;

wire [7:0]  data = sd_data[7:0];
wire        empty;
wire [7:0]  q;
wire        rdreq = !empty && rdy;

//按键检测
key key1(
    //global clock
    . clk(clk),
    . rst_n(rst_n),

    //use interface
    . key(key[0]),
    . key_vld(key_vld[0])
    );

    key key2(
    //global clock
    . clk(clk),
    . rst_n(rst_n),

    //use interface
    . key(key[1]),
    . key_vld(key_vld[1])
    );

    key key3(
    //global clock
    . clk(clk),
    . rst_n(rst_n),

    //use interface
    . key(key[2]),
    . key_vld(key_vld[2])
    );

    key key4(
    //global clock
    . clk(clk),
    . rst_n(rst_n),

    //use interface
    . key(key[3]),
    . key_vld(key_vld[3])
    );
 

rd_fifo	fifo_u (
	.clock ( clk         ),
//--------------------------------------------    
	.data  ( data        ),
    .wrreq ( sd_data_vld ),

	.rdreq ( rdreq       ),
    .q     ( q           ),
//-------------------------------------------- 
	.empty ( empty       )
	);


//写入TX的数据
always  @(posedge clk )begin
    dout <= q;
end

always  @(posedge clk )begin
    dout_vld <= rdreq;
end




//k1按下~写响应返回
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_req <= 0;
    end
    else if(key_vld[0])begin
        wr_req <= 1;
    end
    else if(wr_ack)begin
        wr_req <= 0;
    end
end

//k2按下~读响应返回
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_req <= 0;
    end
    else if(key_vld[1])begin
        rd_req <= 1;
    end
    else if(rd_ack)begin
        rd_req <= 0;
    end
end

assign led = {bank,rd,wr};
//读灯0位
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd <= 0;
    end
    else if(rd_ack)begin
        rd <= !rd;
    end
end

//写灯1位
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr <= 0;
    end
    else if(cnt0 == 510)begin
        wr <= !wr;
    end
end

//bank灯3,2位   //k3按下:代表bank地址加一
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        bank <= 0; 
    end
    else if(add_bank) begin
        if(end_bank)
            bank <= 0; 
        else
            bank <= bank+1 ;
   end
end
assign add_bank = key_vld[2];
assign end_bank = add_bank  && bank == 4-1 ;

//写信号下：写入sdram的数据为0~512
always  @(*)begin
    if(flag_wr)begin
        wdata = {6'b0,cnt0};
    end
    else begin
        wdata = 0;
    end
end

//收到写请求后，写信号拉高，直到计数完毕
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        flag_wr <= 0;
    end
    else if(wr_ack)begin
        flag_wr <= 1;
    end
    else if(end_cnt0)begin
        flag_wr <= 0;
    end
end

//计数器：0~511
always @(posedge clk or negedge rst_n) begin 
    if (rst_n==0) begin
        cnt0 <= 0; 
    end
    else if(add_cnt0) begin
        if(end_cnt0)
            cnt0 <= 0; 
        else
            cnt0 <= cnt0+1 ;
   end
end
assign add_cnt0 = flag_wr;
assign end_cnt0 = add_cnt0  && cnt0 == 512-1 ;

//地址都是从0开始写或读
assign addr = 13'b0;


endmodule

