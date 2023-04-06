`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
/*
写入离散数据，并读出连续数据数据

*/
//////////////////////////////////////////////////////////////////////////////////

module data_handles(
    //global clock
    input                clk        ,
    input                rst_n      ,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //从RX接收的数据
    input        [7:0]   din        ,      //接收RX
    input                din_vld    ,      //接收RX的有效指示信号

   //发送给sdram的数据
    output  reg          wr_req     ,      //请求写
    output               rd_req     ,      //请求读
    output  reg  [ 8:0]  wr_cnt     ,      //读写数量
    output  reg  [22:0]  wr_addr    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    output       [47:0]  wr_data    ,      //写入sdram的数据


    //从sdram接收的数据
    input        [47:0]  sd_data    ,
    input                sd_data_vld,

    //从TX接收的数据
    input                rdy        ,

    //发送给TX的数据
    output  reg  [ 7:0]  dout       ,
    output  reg          dout_vld   
//---------------------------------------------------------------------------------------------------------------
);


    reg         rd_flag_fifo;
    reg         din_vld_f;

    reg         rd_flag;
    reg         wr_flag;
    reg [3:0]   cnt0;
    wire        add_cnt0;
    wire        end_cnt0;


    wire [47:0] wf_data;
    wire        wf_empty;
    wire [8:0]  wf_usedw;
    wire [47:0] wf_q;


    wire [8:0]  cnts;
    wire        wf_wrreq;
    wire        wf_rdreq;

    wire        rf_empty;
    wire [8:0]  rf_usedw;
    wire [47:0] rf_q;
    wire        rf_rdreq;

    wire        wr_reqs ;
    


//写fifo,数据流向是：RX -> data_handle -> wf_fifo -> sdram_c ->sdram
wr_fifo	wf_fifo_uut (
	.clock ( clk ),
    .wrreq ( wf_wrreq ),
	.data ( wf_data ),
	.rdreq ( wf_rdreq ),
	.empty ( wf_empty ),
	.q ( wf_q ),
	.usedw ( wf_usedw )
	);

//读fifo,数据流向是：RX -> data_handle -> sdram_c -> sdram -> sdram_c -> data_handle -> rf_fifo -> data_handle -> TX
wr_fifo	rf_fifo_uut (
	.clock ( clk ),
    .wrreq ( sd_data_vld ),
	.data ( sd_data ),
	.rdreq ( rf_rdreq ),
	.empty ( rf_empty ),
	.q ( rf_q ),
	.usedw ( rf_usedw )
	);

//写入读fifo的数据
assign  wf_data    = {40'b0,din};

//写入读fifo的请求:当输入到达第8个，即数据态，开始将输入写进fifo
assign  wf_wrreq   = (cnt0 >=8 && wr_flag) ? din_vld_f : 1'b0;

//读出读fifo/写入sdram的请求
assign  wf_rdreq   = !wf_empty && rd_flag_fifo;

//写入sdram的数据：根据时序图需要延迟两拍，方案是：推迟两拍wr_req
assign  wr_data = wf_q ;

//写入sdram的请求：命令配置好后，发送请求
assign  wr_reqs  = wr_flag  ? end_cnt0 : 1'b0;

//读出sdram/写入写fifo的请求  ：命令配置好后，发送请求
assign  rd_req  = rd_flag  ? end_cnt0 : 1'b0;

//读出读fifo的请求
assign  rf_rdreq = !rf_empty && rdy;

//写入sdram的请求延迟
always  @(posedge clk )begin
    wr_req <= wr_reqs;
end

//写入TX的数据
always  @(posedge clk )begin
    dout <= rf_q[7:0];
end


always  @(posedge clk )begin
    dout_vld <= rf_rdreq;
end


//读取读fifo的一半标志
always  @(*)begin
    if(wf_empty)begin
        rd_flag_fifo <= 0;
    end
    else if(wr_reqs)begin
        rd_flag_fifo <= 1;
    end
end

always  @(posedge clk )begin
    din_vld_f <= din_vld;
end

assign cnts = wr_flag ? 8+wr_cnt : 9;
// 计数器1
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

assign add_cnt0 = din_vld_f ;
assign end_cnt0 = add_cnt0 && cnt0 == cnts-1;



///////////////////////////////////////////////////////////检测读写
//rd_flag
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rd_flag <= 0;
    end
    else if(cnt0 == 0  && din == 8'hff && din_vld_f)begin
        rd_flag <= 1;
    end
end




//wr_flag
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_flag <= 0;
    end
    else if(cnt0 == 0  && din == 8'hdd && din_vld_f)begin
        wr_flag <= 1;
    end
end

///////////////////////////////////////////////////////////解析读写个数
//wr_cnt
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_cnt <= 0;
    end
    else if(cnt0 == 1  && din_vld_f)begin
        wr_cnt[8] <= din[0];
    end
    else if(cnt0 == 2  && din_vld_f)begin
        wr_cnt[7:0] <= din;
    end
end

///////////////////////////////////////////////////////////解析读写地址
//[22:0]sdram   :  [22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_addr <= 0;
    end
    else if(cnt0 == 3  && din_vld_f)begin//bank
        wr_addr[22:21] <= din[1:0];
    end
    else if(cnt0 == 4  && din_vld_f)begin//rowh
        wr_addr[20:17] <= din[3:0];
    end
    else if(cnt0 == 5  && din_vld_f)begin//rowl
        wr_addr[16:9]  <= din[7:0];
    end
    else if(cnt0 == 6  && din_vld_f)begin//colh
        wr_addr[8]     <= din[0];
    end
    else if(cnt0 == 7  && din_vld_f)begin//coll
        wr_addr[7:0]   <= din[7:0];
    end

end

endmodule