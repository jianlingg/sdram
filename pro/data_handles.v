`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
/*
д����ɢ���ݣ�������������������

*/
//////////////////////////////////////////////////////////////////////////////////

module data_handles(
    //global clock
    input                clk        ,
    input                rst_n      ,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //��RX���յ�����
    input        [7:0]   din        ,      //����RX
    input                din_vld    ,      //����RX����Чָʾ�ź�

   //���͸�sdram������
    output  reg          wr_req     ,      //����д
    output               rd_req     ,      //�����
    output  reg  [ 8:0]  wr_cnt     ,      //��д����
    output  reg  [22:0]  wr_addr    ,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    output       [47:0]  wr_data    ,      //д��sdram������


    //��sdram���յ�����
    input        [47:0]  sd_data    ,
    input                sd_data_vld,

    //��TX���յ�����
    input                rdy        ,

    //���͸�TX������
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
    


//дfifo,���������ǣ�RX -> data_handle -> wf_fifo -> sdram_c ->sdram
wr_fifo	wf_fifo_uut (
	.clock ( clk ),
    .wrreq ( wf_wrreq ),
	.data ( wf_data ),
	.rdreq ( wf_rdreq ),
	.empty ( wf_empty ),
	.q ( wf_q ),
	.usedw ( wf_usedw )
	);

//��fifo,���������ǣ�RX -> data_handle -> sdram_c -> sdram -> sdram_c -> data_handle -> rf_fifo -> data_handle -> TX
wr_fifo	rf_fifo_uut (
	.clock ( clk ),
    .wrreq ( sd_data_vld ),
	.data ( sd_data ),
	.rdreq ( rf_rdreq ),
	.empty ( rf_empty ),
	.q ( rf_q ),
	.usedw ( rf_usedw )
	);

//д���fifo������
assign  wf_data    = {40'b0,din};

//д���fifo������:�����뵽���8����������̬����ʼ������д��fifo
assign  wf_wrreq   = (cnt0 >=8 && wr_flag) ? din_vld_f : 1'b0;

//������fifo/д��sdram������
assign  wf_rdreq   = !wf_empty && rd_flag_fifo;

//д��sdram�����ݣ�����ʱ��ͼ��Ҫ�ӳ����ģ������ǣ��Ƴ�����wr_req
assign  wr_data = wf_q ;

//д��sdram�������������úú󣬷�������
assign  wr_reqs  = wr_flag  ? end_cnt0 : 1'b0;

//����sdram/д��дfifo������  ���������úú󣬷�������
assign  rd_req  = rd_flag  ? end_cnt0 : 1'b0;

//������fifo������
assign  rf_rdreq = !rf_empty && rdy;

//д��sdram�������ӳ�
always  @(posedge clk )begin
    wr_req <= wr_reqs;
end

//д��TX������
always  @(posedge clk )begin
    dout <= rf_q[7:0];
end


always  @(posedge clk )begin
    dout_vld <= rf_rdreq;
end


//��ȡ��fifo��һ���־
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
// ������1
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



///////////////////////////////////////////////////////////����д
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

///////////////////////////////////////////////////////////������д����
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

///////////////////////////////////////////////////////////������д��ַ
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