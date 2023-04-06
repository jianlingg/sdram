

module sdram_c 
 #(
     parameter DATA_WIDTH = 48,                                  // ����λ��
     parameter BANK_WIDTH = 2,                                   // bank��ַλ��
     parameter ROW_WIDTH  = 12,                                  // �е�ַλ��
     parameter COLU_WIDTH = 9,                                   // �е�ַλ��
     parameter ADDR_WIDTH = BANK_WIDTH + ROW_WIDTH + COLU_WIDTH  // ��ַλ��
//     parameter REFRESH_RATE = 1000000,              // ˢ��Ƶ��
//     parameter T_RCD = 3,                          // RAS��CAS�ӳ�
//     parameter T_RAS = 6,                          // �е�ַѡ��ʱ��
//     parameter T_RC = 7                            // ������ʱ��
)

(
    //global clock
    input clk,
    input rst_n,

    //user interface
//---------------------------------------------------------------------------------------------------------------
    //��data_handle���յ�����
    input                         wr_req ,      //����д
    input                         rd_req ,      //�����
    input       [ 8:0]            wr_cnt ,      //��д����
    input       [ADDR_WIDTH-1:0]  wr_addr,      //[22:21]sdram_bank,[20:9]row_sdram_addr,[8:0]column_sdram_addr
    input       [DATA_WIDTH-1:0]  wr_data,      //д��������

    //���͸�data_handle���ź�
    output  reg [DATA_WIDTH-1:0]  rd_data,      //�������ݵ����
    output  reg                   rd_vld,       //����Ч
    
    //���͸�sdram���ź�
    output                        sdram_clk,    //sdram��ʱ��
    output                        sdram_cke,    //��SDRAM�ܽ�������ʱ��ʹ���ź�
                                                        
    output                        sdram_cs ,    //��SDRAM�ܽ�������sdram_cs�ź�
    output                        sdram_ras,    //��SDRAM�ܽ�������sdram_ras�ź�
    output                        sdram_cas,    //��SDRAM�ܽ�������sdram_�ź�
    output                        sdram_we ,    //��SDRAM�ܽ�������sdram_WE�ź�
                                                
    output  reg [1 :0]            sdram_dqm ,   //��SDRAM�ܽ�������sdram_dqm�ź�
    output  reg [11:0]            sdram_addr,   //��SDRAM�ܽ�������sdram_ADDR�ź�
    output  reg [1:0 ]            sdram_bank,   //��SDRAM�ܽ�������sdram_BAnk�ź�
    inout       [DATA_WIDTH-1:0]  sdram_data    //��SDRAM�ܽ�������sdram_data�ź�
//---------------------------------------------------------------------------------------------------------------
);

//����ʱ��
parameter     T_200us = 20_000 ;//��ʼ��NOP��ʱ
parameter     T_trp   = 2      ;//Ԥ�����ʱ
parameter     T_trc   = 7      ;//�Զ�ˢ����ʱ
parameter     T_tmrd  = 2      ;//����ģʽ��ʱ
parameter     T_1300  = 1300   ;//�Զ�ˢ������
parameter     T_trcd  = 2      ;//������ʱ

//����
parameter      nop             = 4'b0111;
parameter      precharge       = 4'b0010;
parameter      auto_refresh    = 4'b0001;
parameter      mode_config     = 4'b0000;
parameter      active          = 4'b0011;
parameter      write           = 4'b0100;
parameter      read            = 4'b0101;
parameter      burst_terminate = 4'b0110;

//ģʽ�Ĵ�����ֵ
parameter mode_value = 12'b00_0_00_010_0_111;//burstģʽ����׼�����������ʱ2��burst����Ϊ˳��burst����Ϊȫҳ
parameter all_bank   = 12'b01_0_00_000_0_000;
//״̬
localparam  S1  = 1 ;//��ʼ��NOP
localparam  S2  = 2 ;//��ʼ��Ԥ���
localparam  S3  = 3 ;//��ʼ���Զ�ˢ��1
localparam  S4  = 4 ;//��ʼ���Զ�ˢ��2
localparam  S5  = 5 ;//��ʼ������ģʽ
localparam  S6  = 6 ;//IDLE״̬
localparam  S7  = 7 ;//ˢ��״̬
localparam  S8  = 8 ;//д����
localparam  S9  = 9 ;//д״̬
localparam  S10 = 10;//������
localparam  S11 = 11;//��״̬



reg [15:0] cnt0;
wire       add_cnt0;
wire       end_cnt0;
reg [15:0] x;
reg [15:0] cnt1;
wire       add_cnt1;
wire       end_cnt1;


reg [4:0 ]         state_c;
reg [4:0 ]         state_n;
reg [3:0 ]         command;
reg [ADDR_WIDTH-1:0] wr_addr_temp;
reg [DATA_WIDTH-1:0] wr_data_ff0; 
reg [DATA_WIDTH-1:0] wr_data_ff1;
reg [DATA_WIDTH-1:0] wr_data_ff2;

reg [ 8:0] wr_cnt_temp;

wire s1_to_s2_start ;
wire s2_to_s3_start ;
wire s3_to_s4_start ;
wire s4_to_s5_start ;
wire s5_to_s6_start ;
wire s6_to_s7_start ;
wire s6_to_s8_start ;
wire s6_to_s10_start ;
wire s7_to_s6_start ;
wire s8_to_s9_start ;
wire s9_to_s6_start ;
wire s10_to_s11_start ;
wire s11_to_s6_start ;


wire init_state = state_c == S1 || state_c == S2 || state_c == S3 || state_c == S4 || state_c == S5;
wire wr_en;

//sdram����ʱ��
assign sdram_clk = !clk;
//ʹ��ʱ�����
assign sdram_cke = 1;


//״̬��
always @(posedge clk or negedge rst_n) begin
    if (rst_n==0)
        state_c <= S1 ;
    else
        state_c <= state_n;
end

always @(*) begin
    case(state_c)
        S1 :begin
            if(s1_to_s2_start)
                state_n = S2 ;
            else
                state_n = state_c ;
        end
        S2 :begin
            if(s2_to_s3_start)
                state_n = S3 ;
            else
                state_n = state_c ;
        end
        S3 :begin
            if(s3_to_s4_start)
                state_n = S4 ;
            else
                state_n = state_c ;
        end
        S4 :begin
            if(s4_to_s5_start)
                state_n = S5 ;
            else
                state_n = state_c ;
        end
        S5 :begin
            if(s5_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S6 :begin
            if(s6_to_s7_start)
                state_n = S7 ;
            else if(s6_to_s8_start)
                state_n = S8 ;
            else if(s6_to_s10_start)
                state_n = S10 ;
            else
                state_n = state_c ;
        end
        S7 :begin
            if(s7_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S8 :begin
            if(s8_to_s9_start)
                state_n = S9 ;
            else
                state_n = state_c ;
        end
        S9 :begin
            if(s9_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        S10 :begin
            if(s10_to_s11_start)
                state_n = S11 ;
            else
                state_n = state_c ;
        end
        S11 :begin
            if(s11_to_s6_start)
                state_n = S6 ;
            else
                state_n = state_c ;
        end
        default : state_n = S1 ;
    endcase
end

assign s1_to_s2_start   = state_c==S1  && (end_cnt0);
assign s2_to_s3_start   = state_c==S2  && (end_cnt0);
assign s3_to_s4_start   = state_c==S3  && (end_cnt0);
assign s4_to_s5_start   = state_c==S4  && (end_cnt0);
assign s5_to_s6_start   = state_c==S5  && (end_cnt0);
assign s6_to_s7_start   = state_c==S6  && (end_cnt1);//��1300��ˢ��ʱ��
assign s6_to_s8_start   = state_c==S6  && (wr_req && !s6_to_s7_start && !rd_req);//��ˢ�Ƕ�����д��
assign s6_to_s10_start  = state_c==S6  && (rd_req && !s6_to_s7_start);//��ˢ��д����
assign s7_to_s6_start   = state_c==S7  && (end_cnt0);//��Ҫtrcʱ��

assign s8_to_s9_start   = state_c==S8  && (end_cnt0);//��Ҫtrcdʱ��
assign s9_to_s6_start   = state_c==S9  && (end_cnt0);//��Ҫͻ����ֹ����
assign s10_to_s11_start = state_c==S10 && (end_cnt0);//��Ҫtrcdʱ��
assign s11_to_s6_start  = state_c==S11 && (end_cnt0);//��Ҫͻ����ֹ����

//����ѡ����
always  @(*)begin
   case(state_c)
      S1:      begin      x=T_200us        ;      end//nop
      S2:      begin      x=T_trp          ;      end//per
      S3:      begin      x=T_trc          ;      end//ref
      S4:      begin      x=T_trc          ;      end//ref
      S5:      begin      x=T_tmrd         ;      end//mod
      S7:      begin      x=T_trc          ;      end//ref
      S8:      begin      x=T_trcd         ;      end//act
      S9:      begin      x=wr_cnt_temp    ;      end//red
      S10:     begin      x=T_trcd         ;      end//act
      S11:     begin      x=wr_cnt_temp    ;      end//wir
      default: begin      x=T_200us        ;      end
   endcase
end

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

assign add_cnt0 = state_c != S6;
assign end_cnt0 = add_cnt0 && cnt0 == x-1;


//������2:ͳ���Զ�ˢ�µ�ʱ��
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
         cnt1 <= 0;
      end
    else if(state_c!= S6 && end_cnt1)begin//״̬�ǿ����ҵ���ˢ�¼�����ֵ����������ֵ��ֱ���ص����У��¸����ڣ�cnt1<=0
         cnt1 <= cnt1;
    end
    else if(add_cnt1)begin
      if(end_cnt1)
         cnt1 <= 0;
      else
         cnt1 <= cnt1 + 1;
    end      
end

assign add_cnt1  = !init_state;
assign end_cnt1  = add_cnt1 && cnt1 == T_1300-1;
//�ڶ�д̬�����ҵ���Ĭ��ˢ��ʱ����Ҫ����Ĭ��ˢ�µ�ʱ�䣬�����ӳ�����д���
/*��⣺����˵�����ڿ���̬�Ҽ���������ˢ��̬������Ϊ���ڶ�д̬��������ʱ������ת��ˢ��̬��ͬʱ��Ϊ��ת��ˢ��̬��������
�����ڿ���̬�Ҽ�����������̬��һ������д��Ϻ���Զ���ת�ˣ���������һ��������Ҫ���������������
*/

//��д����
always  @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        wr_cnt_temp <= 0;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin
        wr_cnt_temp <= wr_cnt;
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//����� û����
assign {sdram_cs,sdram_ras,sdram_cas,sdram_we} = command;

always  @(posedge clk)begin
    if(s1_to_s2_start)begin //100usnop���������󣬷���Ԥ�������
        command <= precharge;
    end
    else if(s2_to_s3_start || s3_to_s4_start || s6_to_s7_start) begin
        command <= auto_refresh;
    end
    else if(s4_to_s5_start)begin
        command <= mode_config;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin//��⵽��д�źź󣬷�����������
        command <= active;
    end
    else if(s8_to_s9_start)begin
        command <= write;
    end
    else if(s10_to_s11_start)begin
        command <= read;
    end
    else if(s9_to_s6_start || s11_to_s6_start)begin//��д��ɺ����ͻ����ֹ����
        command <= burst_terminate;
    end
    else begin
        command <= nop;
    end
end

//sdram_addr���� û���� 
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        wr_addr_temp <= 23'b0;
    end
    else if(wr_req || rd_req)begin
        wr_addr_temp <= wr_addr;
    end
end

//A0-A9,A11����sdram_addr��ֻ����һ������
always  @(posedge clk )begin
    if(s1_to_s2_start)begin
        sdram_addr <= all_bank;            //��sdram_addr[10] <= 1;
    end
    else if(s4_to_s5_start)begin
        sdram_addr <= mode_value;
    end
    else if(s6_to_s8_start || s6_to_s10_start)begin//������row_sdram_addr,��ΪҪͬ������̬��������Բ�����Ҫ���������
        sdram_addr <= wr_addr[20:9];
    end
    else if(s8_to_s9_start || s10_to_s11_start)begin//������column_sdram_addr����ΪҪ�ڼ���̬��Ķ�д̬��ֵ��������Ҫ�õ����汣�������
        sdram_addr <= {3'b0, wr_addr_temp[8:0]};
    end
    else begin
        sdram_addr <= 0;
    end
end

//sdram_dqm�����������
always  @(posedge clk)begin 
    if(init_state)begin
        sdram_dqm <= 2'b11;
    end
    else begin
        sdram_dqm <= 2'b00;
    end
end

//sdram_bank
always  @(posedge clk)begin
    if(s6_to_s8_start|| s6_to_s10_start)begin
        sdram_bank <= wr_addr[22:21];
    end
    else if(s8_to_s9_start || s10_to_s11_start)begin
        sdram_bank <= wr_addr_temp[22:21];
    end
    else begin
        sdram_bank <= 0;
    end
end


//wr_data��ʱ
always  @(posedge clk )begin
    wr_data_ff0 <= wr_data;
    wr_data_ff1 <= wr_data_ff0;
    wr_data_ff2 <= wr_data_ff1;
end

//sdram_data д��
assign wr_en = state_c == S8 || state_c == S9;
assign sdram_data   = wr_en ? wr_data_ff2 : 48'hzzzz;

//rd ������sdram_data -> rd_data
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        rd_data <= 16'b0;
    end
    else begin
        rd_data <= sdram_data;
    end
end

//����Ч
always  @(posedge clk )begin
    if(state_c == S11 && cnt0 == 2-1)begin
        rd_vld <= 1;
    end
    else if((state_c == S6 && cnt0 == 2-1)|| (state_c ==S1))begin
        rd_vld <= 0;
    end
end

endmodule 


