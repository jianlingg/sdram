`timescale 1 ns/1 ns

module sdram_r_tb();
//����
//---------------------------------------------------------------------------------------------------------------
//ʱ�Ӻ͸�λ
reg clk  ;
reg rst_n;

//uut�������ź�
reg               wr_req   ;      //����д
reg               rd_req   ;      //�����
reg               rd_req_s ;      //�����
reg       [ 8:0]  wr_cnt ;      //��д����
reg       [22:0]  wr_addr;      //[21:20]sdram_bank_sdram_addr,[19:8]row_sdram_addr,[7:0]column_sdram_addr
reg       [47:0]  wr_data;      //д��������

//���
//---------------------------------------------------------------------------------------------------------------
wire      [47:0]  rd_data;      //�������ݵ����
wire              rd_vld ;       //����Ч
                           
wire              sdram_clk;
wire              sdram_cke;    //��SDRAM�ܽ�������ʱ��ʹ���ź�

//����                         
wire              sdram_cs ;    //��SDRAM�ܽ�������sdram_cs�ź�
wire              sdram_ras;    //��SDRAM�ܽ�������sdram_ras�ź�
wire              sdram_cas;    //��SDRAM�ܽ�������sdram_�ź�
wire              sdram_we ;    //��SDRAM�ܽ�������sdram_WE�ź�
                        
wire      [1 :0]  sdram_dqm ;   //��SDRAM�ܽ�������sdram_dqm�ź�
wire      [11:0]  sdram_addr;   //��SDRAM�ܽ�������sdram_ADDR�ź�
wire      [1:0 ]  sdram_bank;   //��SDRAM�ܽ�������sdram_BAnk�ź�
wire      [47:0]  sdram_data;    //��SDRAM�ܽ�������sdram_data�ź�


wire      [47:0]  dq;
reg               dq_data_en          ;             //���Ӵ����źţ�д����̬�ŵģ�������д����ʱ����dq�ĸ�ֵ��ת���ɶ�wr_data_en��wr_data�ĸ�ֵ��
reg       [47:0]  dq_data             ; 

assign  dq = dq_data_en?dq_data:48'hzzzz;
                                                    
reg       [47:0]           i             ;



        //ʱ�����ڣ���λΪns�����ڴ��޸�ʱ�����ڡ�
        parameter CYCLE    = 10;

        //��λʱ�䣬��ʱ��ʾ��λ3��ʱ�����ڵ�ʱ�䡣
        parameter RST_TIME = 3 ;

        //�����Ե�ģ������
        sdram_c sdram_c_uut(
            //global clock
            .clk        (clk      ),        //ϵͳ����ʱ��100MHz
            .rst_n      (rst_n    ),        //ϵͳ��λ�źţ��͵�ƽ��Ч 

            //user interface 
            .wr_req     (wr_req   ),        //д�����ź�
            .rd_req     (rd_req   ),        //�������ź�
            .wr_cnt     (wr_cnt   ),        //��д��������
            .wr_addr    (wr_addr  ),        //��д��ַ����
            .wr_data    (wr_data  ),        //д��������

       
            .rd_data    (rd_data  ),        //���������
            .rd_vld     (rd_vld   ),        //��������Чָʾ�ź�

            ////////////////////////////////////////////////////////////
            //// ʱ�Ӽ�ʹ��
            .sdram_clk  (sdram_clk),        //��SDRAM�ܽ�������ʱ���ź�
            .sdram_cke  (sdram_cke),        //��SDRAM�ܽ�������ʱ��ʹ���ź�

            // ����
            .sdram_cs   (sdram_cs ),        //��SDRAM�ܽ�������CS�ź�
            .sdram_ras  (sdram_ras),        //��SDRAM�ܽ�������RAS�ź�
            .sdram_cas  (sdram_cas),        //��SDRAM�ܽ�������CAS�ź�
            .sdram_we   (sdram_we ),        //��SDRAM�ܽ�������WE�ź�

            // ��ַ
            .sdram_bank (sdram_bank),        //��SDRAM�ܽ�������BANK�ź�
            .sdram_addr (sdram_addr),        //��SDRAM�ܽ�������ADDR�ź�

            // ����
            .sdram_dqm  (sdram_dqm),        //��SDRAM�ܽ�������DQM�ź�
            .sdram_data (dq       )         //��SDRAM�ܽ�������DQ�ź�
        );



    //���ɱ���ʱ��50M
    initial begin
        clk = 0;
        forever begin
            #(CYCLE/2)
            clk=~clk;
        end
    end

    //������λ�ź�
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

    //�����ź�wr_req/wr_addr/wr_data��ֵ��ʽ
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

        //д����������д����Ҫд��ĵ�ַ��Ҫд�����������Ҫд������ݣ�����д���ַ������������
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