`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/05 20:43:32
// Design Name: 
// Module Name: i_cache_final
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i_cache #(
        parameter ADDR_WIDTH = 32,
        parameter CACHE_LINE_SIZE = 8,
        parameter CACHE_WAY_SIZE = 2,
        parameter CACHE_LINE_NUM = 256
    )(
        input   wire              clk,
        input   wire              rst, 

        input   wire        cpu_instr_ena,

        input   wire [31:0] cpu_instr_vaddr,
        input   wire [31:0] cpu_instr_psyaddr,    

        output  wire [31:0] cpu_instr_data,
        output  wire [31:0] cpu_instr_data2,
        output  wire        cpu_instr_data_1ok,
        output  wire        cpu_instr_data_2ok,
        output  wire        stall_all,
    
        output  wire [3 :0] awid,
        output  wire [31:0] awaddr,
        output  wire [7 :0] awlen,
        output  wire [2 :0] awsize,
        output  wire [1 :0] awburst,
        output  wire        awvalid,
        input   wire        awready,
        output  wire [31:0] wdata,
        output  wire [3 :0] wstrb,
        output  wire        wlast,
        output  wire        wvalid,
        input   wire        wready,
        output  wire [3 :0] arid,
        output  reg  [31:0] araddr,
        output  reg  [7 :0] arlen,
        output  wire [2 :0] arsize,
        output  wire [1 :0] arburst,
        output  reg         arvalid,
        input   wire        arready,
        input   wire [3 :0] rid,
        input   wire [31:0] rdata,
        input   wire [1 :0] rresp,
        input   wire        rlast,
        input   wire        rvalid,
        output  wire        rready,
        input   wire [3 :0] bid,
        input   wire [1 :0] bresp,
        input   wire        bvalid,
        output  wire        bready
    );
    assign awid  = 4'h0;
    assign awaddr  = 32'h0000_0000;
    assign awlen  = 8'h00;
    assign awsize  = 3'h0;
    assign awburst  = 2'h0;
    assign awvalid  = 1'b0;
    assign wdata  = 32'h0000_0000;
    assign wstrb  = 4'h0;
    assign wlast  = 1'b0;
    assign wvalid  = 1'b0;
    assign bready  = 1'b0; 
    assign arid = 4'h0;  //not used so far.

    assign arsize = 3'b010;  //means 2^2: 4bytes     while 3'b011 means 2^3 
    assign arburst = 2'b01; //means incre, which is used in ram.

    assign rready = 1'b1;  //always accept data from ram(slaver) so far.
    localparam Byte_c = 2;
    localparam INDEX_WIDTH = $clog2(CACHE_LINE_NUM);  //index_width = 8
    localparam OFFSET_WIDTH =$clog2(CACHE_LINE_SIZE);  //offset width = 3
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH - Byte_c;  //tag width = 19
    
    initial begin
        if(TAG_WIDTH <= 0) begin
            $error("Wrong Tag Width!");
            $finish;
        end
    end


//way 2  cache_line_size 32bytes   cache_line_num = 256   
//cpu info
    reg[31:0]   cpu_instr_psyaddr_reg;
    reg[31:0]   cpu_instr_vaddr_reg;
    always @(posedge clk) begin
        if(rst)begin
            cpu_instr_psyaddr_reg   <= 32'h0;
            cpu_instr_vaddr_reg     <= 32'h0; 
        end else begin
            if(!stall_all && cpu_instr_ena) begin
                cpu_instr_psyaddr_reg   <= cpu_instr_psyaddr;
                cpu_instr_vaddr_reg     <= cpu_instr_vaddr;
            end
        end
    end

    wire [TAG_WIDTH-1   :0] tag_cpu     = cpu_instr_psyaddr_reg [ADDR_WIDTH-1 : 2 + OFFSET_WIDTH + INDEX_WIDTH];
    wire [INDEX_WIDTH-1 :0] index_cpu   = cpu_instr_vaddr       [2+OFFSET_WIDTH+INDEX_WIDTH-1 : 2+OFFSET_WIDTH];
    wire [OFFSET_WIDTH-1:0] offset_cpu  = cpu_instr_vaddr_reg   [2+OFFSET_WIDTH-1 : 2];

//tag part
    wire [INDEX_WIDTH -1 :0] tag_ram_addr;
    wire [23:0] cache_tag_in;
    wire [23:0] cache_tag_out [CACHE_WAY_SIZE -1 :0];
    reg  [2:0]  write_tag_en[CACHE_WAY_SIZE-1:0];
    assign  tag_ram_addr = stall_all ? cpu_instr_vaddr_reg[2+OFFSET_WIDTH+INDEX_WIDTH-1 : 2+OFFSET_WIDTH] : index_cpu;
    //[18:0]
    assign  cache_tag_in = {5'b00001,tag_cpu};

//data part
    wire [INDEX_WIDTH-1:0] instr_ram_data_index;
    wire [31:0] cache_block_in;
    wire [31:0] cache_block_out_v1[CACHE_LINE_SIZE-1:0]; //  [7:0]
    wire [31:0] cache_block_out_v2[CACHE_LINE_SIZE-1:0];
    reg  [3 :0] write_data_bank_en_v1[CACHE_LINE_SIZE-1:0];
    reg  [3 :0] write_data_bank_en_v2[CACHE_LINE_SIZE-1:0];
    assign instr_ram_data_index = stall_all ? cpu_instr_vaddr_reg[2+OFFSET_WIDTH+INDEX_WIDTH-1 : 2+OFFSET_WIDTH] : index_cpu;
    assign cache_block_in       = rdata;


//tag ram
    instr_ram_tag_Part tag_ramv1 (.clka(clk),.ena(cpu_instr_ena),.wea(write_tag_en[0]),.addra(tag_ram_addr),.dina(cache_tag_in),.douta(cache_tag_out[0]));
    instr_ram_tag_Part tag_ramv2 (.clka(clk),.ena(cpu_instr_ena),.wea(write_tag_en[1]),.addra(tag_ram_addr),.dina(cache_tag_in),.douta(cache_tag_out[1]));

//data ram
data_cache_4v data_cachev1_bank0 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[0]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[0]));
data_cache_4v data_cachev1_bank1 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[1]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[1]));
data_cache_4v data_cachev1_bank2 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[2]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[2]));
data_cache_4v data_cachev1_bank3 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[3]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[3]));
data_cache_4v data_cachev1_bank4 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[4]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[4]));
data_cache_4v data_cachev1_bank5 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[5]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[5]));
data_cache_4v data_cachev1_bank6 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[6]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[6]));
data_cache_4v data_cachev1_bank7 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v1[7]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v1[7]));

data_cache_4v data_cachev2_bank0 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[0]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[0]));
data_cache_4v data_cachev2_bank1 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[1]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[1]));
data_cache_4v data_cachev2_bank2 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[2]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[2]));
data_cache_4v data_cachev2_bank3 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[3]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[3]));
data_cache_4v data_cachev2_bank4 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[4]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[4]));
data_cache_4v data_cachev2_bank5 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[5]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[5]));
data_cache_4v data_cachev2_bank6 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[6]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[6]));
data_cache_4v data_cachev2_bank7 (.clka(clk),.ena(cpu_instr_ena),.wea(write_data_bank_en_v2[7]),.addra(instr_ram_data_index),.dina(cache_block_in),.douta(cache_block_out_v2[7]));

//hit miss and so on
    wire [1:0] hit_tag;
    reg miss;

    /*assign hit_tag = (cache_tag_out[0][20] == 1'b1 && cache_tag_out[0][19:0] == tag_cpu)? 2'b01 
                        :(cache_tag_out[1][20] == 1'b1 && cache_tag_out[1][19:0] == tag_cpu)? 2'b10 : 2'b00;*/

    assign hit_tag = (cache_tag_out[0][19] == 1'b1 && cache_tag_out[0][18:0] == tag_cpu)? 2'b01 
                        :(cache_tag_out[1][19] == 1'b1 && cache_tag_out[1][18:0] == tag_cpu)? 2'b10 : 2'b00;
    reg Before_clk;
    always @(posedge clk) begin
        if(rst) begin
            Before_clk <= 1'b0;
        end else begin
            Before_clk <= 1'b1;
        end
    end

    always @(*) begin
        if(rst) begin
            miss = 1'b0;
        end else if(Before_clk == 1'b0) begin
            miss = 1'b0;
        end else if(cpu_instr_ena) begin
                if(hit_tag[0]==1'b0 && hit_tag[1] == 1'b0)begin
                    miss = 1'b1;
                end else begin
                    miss = 1'b0;
                end
            end else begin
                miss = 1'b0;
            end
    end

//LRU_sel
    reg [1:0] LRU_sel;
    reg [1:0] LRU_sel_next;

//status
    wire [ADDR_WIDTH -1 : 0] cache_line_addr;
    wire axi_ena = rst? 1'b0 : miss;  //axi_ena

    localparam [1:0] READ_IDLE = 2'b00;
    localparam [1:0] READ_ADDR = 2'b01;
    localparam [1:0] READ_DATA = 2'b11;
    reg        [1:0] cur_state, next_state;
    reg        [2:0] next_offset, offset_cur;

    assign stall_all = (rst)? 1'b0: (Before_clk == 1'b0)? 1'b0 : (next_state == READ_ADDR || next_state == READ_DATA 
                                                                    || cur_state == READ_ADDR || cur_state ==READ_DATA )? 1'b1 :1'b0;
//output ↓
    reg [31:0] cpu_instr_data_t_next;
    reg [31:0] cpu_instr_data_t_next2;
    reg cpu_instr_data_1ok_next;
    reg cpu_instr_data_2ok_next;
    wire [2:0] offset_data2;
    assign offset_data2 = (offset_cpu < 3'b111)? offset_cpu + 1 :offset_cpu;

    always @(*) begin
        if(rst || miss)begin
            cpu_instr_data_t_next = 32'h0000_0000;
            cpu_instr_data_t_next2 =32'h0000_0000;
            cpu_instr_data_1ok_next = 1'b0;
            cpu_instr_data_2ok_next = 1'b0;
        end else begin
            case(hit_tag)
                2'b01:begin
                    cpu_instr_data_t_next = cache_block_out_v1[offset_cpu];
                    cpu_instr_data_1ok_next = 1'b1;
                    if(~offset_cpu[0])begin
                        cpu_instr_data_2ok_next = 1'b1;
                        cpu_instr_data_t_next2 = cache_block_out_v1[offset_data2];
                    end else begin
                        cpu_instr_data_2ok_next = 1'b0;
                        cpu_instr_data_t_next2 = cache_block_out_v1[offset_data2];
                    end
                end
                2'b10:begin
                    cpu_instr_data_t_next = cache_block_out_v2[offset_cpu];
                    cpu_instr_data_1ok_next = 1'b1;
                    if(~offset_cpu[0])begin
                        cpu_instr_data_t_next2 = cache_block_out_v2[offset_data2];
                        cpu_instr_data_2ok_next = 1'b1;
                    end else begin
                        cpu_instr_data_2ok_next = 1'b0;
                        cpu_instr_data_t_next2 = cache_block_out_v2[offset_data2];
                    end
                end
            endcase
        end
    end

    assign cpu_instr_data  = cpu_instr_data_t_next;
    assign cpu_instr_data2 = cpu_instr_data_t_next2;
    assign cpu_instr_data_1ok = cpu_instr_data_1ok_next;
    assign cpu_instr_data_2ok = cpu_instr_data_2ok_next;

//output ↑

    always @(posedge clk) begin
        if(rst) begin
            cur_state <= READ_IDLE;
            offset_cur <= 3'b000;
            LRU_sel <= 2'b00;
        end
        else begin
            cur_state <= next_state;
            offset_cur <= next_offset;
            LRU_sel <= LRU_sel_next;
        end
    end

    always @(*) begin
        if(rst) begin
            next_state = READ_IDLE;
            next_offset = 3'b000;
            LRU_sel_next = 2'b00;
        end else begin
            case(cur_state)
                READ_IDLE:begin
                    if(Before_clk == 1'b0) begin
                        next_state = READ_IDLE;
                        LRU_sel_next = 2'b01;
                    end else if(~cpu_instr_ena) begin
                        next_state = READ_IDLE;
                        if(hit_tag == 2'b01) begin
                            LRU_sel_next  = 2'b01;
                        end else if (hit_tag == 2'b10) begin
                            LRU_sel_next = 2'b10;
                        end else begin
                            LRU_sel_next = LRU_sel;
                        end
                    end else if(axi_ena) begin
                        next_state = READ_ADDR;
                    end else begin
                        next_state = READ_IDLE;
                    end
                end

                READ_ADDR:begin
                    next_state = arready? READ_DATA :READ_ADDR;
                    next_offset = 3'b000;
                end

                READ_DATA:begin
                    next_state = rlast? READ_IDLE :READ_DATA;
                    next_offset = rlast? 3'b000 : offset_cur + 1;
                end
            endcase
        end
    end

    assign cache_line_addr = {cpu_instr_psyaddr_reg[ADDR_WIDTH-1 : OFFSET_WIDTH+2],{(OFFSET_WIDTH + Byte_c){1'b0}}};

    integer i;
    always @(*) begin
        if(rst)begin
            araddr <= 32'h0000_0000;
            arlen <= 8'b0000_0000;
            arvalid <= 1'b0;
        end else begin
            case (cur_state)
                READ_IDLE:begin
                    write_tag_en[0] <= 3'b000;
                    write_tag_en[1] <= 3'b000;
                    for (i = 0;i<CACHE_LINE_SIZE;i= i+1)begin
                        write_data_bank_en_v1[i] <= 4'b0000;
                        write_data_bank_en_v2[i] <= 4'b0000;
                    end
                    araddr <= 32'h0000_0000;
                    arlen <= 8'b0000_0000;
                    arvalid <= 1'b0;
                end
                READ_ADDR:begin
                    write_tag_en[0] <= 3'b000;
                    write_tag_en[1] <= 3'b000;
                    for (i = 0;i<CACHE_LINE_SIZE;i= i+1)begin
                        write_data_bank_en_v1[i] <= 4'b0000;
                        write_data_bank_en_v2[i] <= 4'b0000;
                    end
                    araddr <= cache_line_addr;
                    arlen <= CACHE_LINE_SIZE - 1;
                    arvalid <= 1'b1;
                end
                READ_DATA:begin
                    araddr <= 32'h0000_0000;
                    arlen <= 8'b0000_0000;
                    arvalid <= 1'b0;
                    case(LRU_sel_next)
                        2'b10:begin
                            write_tag_en[0] <= 3'b111;
                            write_tag_en[1] <= 3'b000;
                            for (i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i != offset_cur) begin
                                write_data_bank_en_v1[i] <= 4'b0000;
                                end
                            end
                            for (i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                write_data_bank_en_v2[i] <= 4'b0000;
                            end
                            write_data_bank_en_v1[offset_cur] <= 4'b1111;
                        end
                        2'b01:begin
                            write_tag_en[0] <= 3'b000;
                            write_tag_en[1] <= 3'b111;
                            for (i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i != offset_cur) begin
                                write_data_bank_en_v2[i] <= 4'b0000;
                                end
                            end
                            for (i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                write_data_bank_en_v1[i] <= 4'b0000;
                            end
                            write_data_bank_en_v2[offset_cur] <= 4'b1111;
                        end
                    endcase
                end
                default:begin
                    write_tag_en[0] <= 3'b000;
                    write_tag_en[1] <= 3'b000;
                    for (i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                        write_data_bank_en_v1[i] <= 4'b0000;
                        write_data_bank_en_v2[i] <= 4'b0000;
                    end
                    araddr <= 32'h0000_0000;
                    arlen <= 8'b0000_0000;
                    arvalid <= 1'b0;
                end
            endcase
        end
    end
    reg flag_cache_miss;

    reg [63:0] cache_replace_count;
    reg [63:0] cache_miss_count;
    reg [63:0] cache_total_count;

    always @(posedge clk) begin
        if(rst) begin
            flag_cache_miss     <=  0;
            cache_miss_count    <=  0;
            cache_total_count   <=  0;
            cache_replace_count <= 0;
        end else begin
            if( miss && flag_cache_miss == 1'b0) begin
                if((LRU_sel_next == 2'b10 && cache_tag_out[0][19] == 1'b1) ||(LRU_sel_next == 2'b01 && cache_tag_out[1][19] == 1'b1))begin
                    cache_replace_count <= cache_replace_count + 1;
                end
                flag_cache_miss <= 1'b1;
                cache_miss_count <= cache_miss_count + 1;
            end else if(flag_cache_miss == 1'b1 && (!miss)) begin
                flag_cache_miss <= 1'b0;
            end
            if(cpu_instr_ena && ~stall_all)begin
                cache_total_count <= cache_total_count +1;
            end
        end
    end
endmodule
