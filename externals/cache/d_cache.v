`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/17 13:18:49
// Design Name: 
// Module Name: d_cache
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


module d_cache#(
        parameter ADDR_WIDTH = 32,
        parameter CACHE_LINE_SIZE = 8,
        parameter CACHE_WAY_SIZE = 2,
        parameter CACHE_LINE_NUM = 128
    )(
        input wire              clk,
        input wire              rst,

        //
        input wire              D_i_stall, // i- cache stall
        input wire              r_mem_ena,
        input wire [3:0]        w_mem_ena,
        input wire [31:0]       mem_addr_next,
        //input wire [31:0]       mem_addr_cur,
        input wire [31:0]       w_mem_data,

        output wire [31:0]      mem_data,
        output wire             d_cache_stall,

        //axi
        //aw   with out awcache awlock  awprot
        output wire [3:0]       awid,
        output reg  [31:0]      awaddr,
        output reg  [7:0]       awlen,
        output wire [2:0]       awsize,
        output wire [1:0]       awburst,
        output reg              awvalid,
        input  wire             awready,
        //w
        output reg  [31 : 0]    wdata,
        output wire [3 : 0]     wstrb,//
        output reg              wlast,
        output reg              wvalid,
        input wire              wready,
        //ar
        output wire [3 : 0]     arid,
        output reg  [31 : 0]    araddr,
        output reg  [7 : 0]     arlen,
        output wire [2 : 0]     arsize,
        output wire [1 : 0]     arburst,
        output reg              arvalid,
        input wire              arready,
        //r
        input wire [3 : 0]      rid,
        input wire [31 : 0]     rdata,
        input wire [1 : 0]      rresp,
        input wire              rlast,
        input wire              rvalid,
        output wire             rready,
        //b
        input wire [3 : 0]      bid,      //not used 
        input wire [1 : 0]      bresp,   //not used 
        input wire              bvalid,
        output wire             bready
    );
    assign awid  = 4'h0;
    assign wstrb  = 4'h0;
    assign arid = 4'h0;  //not used so far.

    assign awburst  = 2'b01;
    assign awsize  = 3'b010;
    assign arsize = 3'b010;  //means 2^2: 4bytes     while 3'b011 means 2^3 
    assign arburst = 2'b01; //means incre, which is used in ram.

    assign rready = 1'b1;

    //wire cache_ena = r_mem_ena || (w_mem_ena!=4'b0000);
    reg cache_ena;
    reg reg_cache_ena;

    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功

    always @(posedge clk ) begin
        if(rst)begin
            reg_cache_ena <= 1'b0;
        end else if(!D_i_stall)begin
            reg_cache_ena <= cache_ena;
        end
    end

    reg [3:0]  w_mem_ena_reg;
    reg [31:0] w_mem_data_reg;

    reg [31:0] mem_addr_cur;
    always @(posedge clk ) begin
        if(rst)begin
            mem_addr_cur <= 32'h0000_0000;
        end else if(!d_cache_stall)begin
            mem_addr_cur <= mem_addr_next;
        end
    end

    always @(posedge clk ) begin
        if(rst)begin
            w_mem_data_reg <= 32'h0000_0000;
            w_mem_ena_reg <= 4'b0000;
        end else if(!d_cache_stall) begin
            w_mem_ena_reg <= w_mem_ena;
            w_mem_data_reg <= w_mem_data;
        end else begin
            w_mem_ena_reg <= w_mem_ena_reg;
            w_mem_data_reg <= w_mem_data_reg;
        end
    end

    reg dirty;
    localparam Byte_c       = 2;
    localparam INDEX_WIDTH  = $clog2(CACHE_LINE_NUM);  //index_width = 7
    localparam OFFSET_WIDTH = $clog2(CACHE_LINE_SIZE);  //offset width = 3
    localparam TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH - Byte_c;  //tag width = 20

    initial begin
        if(TAG_WIDTH <= 0) begin
            $error("Wrong Tag Width!");
            $finish;
        end
    end

    reg [31:0] write_buffer [CACHE_LINE_SIZE-1:0]; //it needs to be changed

    wire [TAG_WIDTH   -1   :0]   tag_cur      = mem_addr_cur [ADDR_WIDTH-1 : 2 + OFFSET_WIDTH + INDEX_WIDTH]; //ADDR_WIDTH - TAG_WIDTH +1
    wire [INDEX_WIDTH -1   :0] index_next     = mem_addr_next [2+OFFSET_WIDTH+INDEX_WIDTH-1 : 2+OFFSET_WIDTH];
    wire [INDEX_WIDTH -1   :0] index_cur      = mem_addr_cur[2+OFFSET_WIDTH+INDEX_WIDTH-1 : 2+OFFSET_WIDTH];
    wire [OFFSET_WIDTH-1   :0]  offset_cur    = mem_addr_cur [2+OFFSET_WIDTH-1 : 2];

//TAG PART
    wire [INDEX_WIDTH -1 :0]    tag_ram_addr;
    reg  [23:0]                 cache_tag_in;
    wire [23:0]                 cache_tag_out  [CACHE_WAY_SIZE -1 :0];
    reg  [2:0]                   write_tag_en  [CACHE_WAY_SIZE -1:0];

    assign  tag_ram_addr =  d_cache_stall? index_cur: index_next;
    //assign  cache_tag_in = {4'b0001,tag_cur};

//DATA PART

    wire [INDEX_WIDTH-1 : 0] d_ram_data_index;
    assign d_ram_data_index = d_cache_stall? index_cur:index_next;

    reg [31 : 0] cache_block_in [CACHE_LINE_SIZE-1 :0 ];
    wire [31 : 0] cache_block_out_v1 [CACHE_LINE_SIZE-1:0]; //  [7:0]
    wire [31 : 0] cache_block_out_v2 [CACHE_LINE_SIZE-1:0];
    reg [3:0]  write_data_bank_en_v1[CACHE_LINE_SIZE-1 :0];
    reg [3:0]  write_data_bank_en_v2[CACHE_LINE_SIZE-1 :0];
    assign lw_ram_data_index =  d_cache_stall? index_cur: index_next;
//tag ram
    instr_ram_tag_Part tag_ramv1 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_tag_en[0]),.addra(tag_ram_addr),.dina(cache_tag_in),.douta(cache_tag_out[0]));
    instr_ram_tag_Part tag_ramv2 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_tag_en[1]),.addra(tag_ram_addr),.dina(cache_tag_in),.douta(cache_tag_out[1]));

//data ram
data_cache_4v data_cachev1_bank0 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[0]),.addra(d_ram_data_index),.dina(cache_block_in[0]),.douta(cache_block_out_v1[0]));
data_cache_4v data_cachev1_bank1 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[1]),.addra(d_ram_data_index),.dina(cache_block_in[1]),.douta(cache_block_out_v1[1]));
data_cache_4v data_cachev1_bank2 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[2]),.addra(d_ram_data_index),.dina(cache_block_in[2]),.douta(cache_block_out_v1[2]));
data_cache_4v data_cachev1_bank3 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[3]),.addra(d_ram_data_index),.dina(cache_block_in[3]),.douta(cache_block_out_v1[3]));
data_cache_4v data_cachev1_bank4 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[4]),.addra(d_ram_data_index),.dina(cache_block_in[4]),.douta(cache_block_out_v1[4]));
data_cache_4v data_cachev1_bank5 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[5]),.addra(d_ram_data_index),.dina(cache_block_in[5]),.douta(cache_block_out_v1[5]));
data_cache_4v data_cachev1_bank6 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[6]),.addra(d_ram_data_index),.dina(cache_block_in[6]),.douta(cache_block_out_v1[6]));
data_cache_4v data_cachev1_bank7 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v1[7]),.addra(d_ram_data_index),.dina(cache_block_in[7]),.douta(cache_block_out_v1[7]));

data_cache_4v data_cachev2_bank0 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[0]),.addra(d_ram_data_index),.dina(cache_block_in[0]),.douta(cache_block_out_v2[0]));
data_cache_4v data_cachev2_bank1 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[1]),.addra(d_ram_data_index),.dina(cache_block_in[1]),.douta(cache_block_out_v2[1]));
data_cache_4v data_cachev2_bank2 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[2]),.addra(d_ram_data_index),.dina(cache_block_in[2]),.douta(cache_block_out_v2[2]));
data_cache_4v data_cachev2_bank3 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[3]),.addra(d_ram_data_index),.dina(cache_block_in[3]),.douta(cache_block_out_v2[3]));
data_cache_4v data_cachev2_bank4 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[4]),.addra(d_ram_data_index),.dina(cache_block_in[4]),.douta(cache_block_out_v2[4]));
data_cache_4v data_cachev2_bank5 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[5]),.addra(d_ram_data_index),.dina(cache_block_in[5]),.douta(cache_block_out_v2[5]));
data_cache_4v data_cachev2_bank6 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[6]),.addra(d_ram_data_index),.dina(cache_block_in[6]),.douta(cache_block_out_v2[6]));
data_cache_4v data_cachev2_bank7 (.clka(clk),.ena(cache_ena || reg_cache_ena),.wea(write_data_bank_en_v2[7]),.addra(d_ram_data_index),.dina(cache_block_in[7]),.douta(cache_block_out_v2[7]));

    wire [1:0] hit_tag;
    reg miss;
    assign hit_tag = (cache_tag_out[0][20] == 1'b1 && cache_tag_out[0][19:0] == tag_cur)? 2'b01 
                        :(cache_tag_out[1][20] == 1'b1 && cache_tag_out[1][19:0] == tag_cur)? 2'b10 : 2'b00;

    

    always @(*) begin
        if(rst) begin
            miss = 1'b0;
        end else if(reg_cache_ena) begin
                if(hit_tag[0]==1'b0 && hit_tag[1] == 1'b0)begin
                    miss = 1'b1;
                end else begin
                    miss = 1'b0;
                end
            end else begin
                miss = 1'b0;
            end
    end
    
    reg [1:0] data_cache_status;

//lru_Sel
    reg [1:0] LRU_sel;
    reg [1:0] LRU_sel_next;

//CACHE
    localparam [1:0] CACHE_IDLE    =  2'b00;
    localparam [1:0] CACHE_READ    =  2'b01;
    localparam [1:0] CACHE_WRITE   =  2'b10;

    reg [1:0] cur_cache_status;
    always @(posedge clk) begin
        if(rst) begin
            cur_cache_status <= 2'b00;
        end else begin
            cur_cache_status <= data_cache_status;
        end
    end

    always @(*) begin
        if(rst)begin
            data_cache_status = CACHE_IDLE;
        end else if(D_i_stall) begin
            data_cache_status = CACHE_IDLE;
        end else if(r_mem_ena && w_mem_ena == 4'b0000)begin
            data_cache_status = CACHE_READ;
        end else if(w_mem_ena != 4'b0000) begin
            data_cache_status = CACHE_WRITE;
        end else if(w_mem_ena==4'b0000 && !r_mem_ena)begin  //无lw 且 无sw
            data_cache_status = CACHE_IDLE;
        end else begin
            data_cache_status = CACHE_IDLE;
        end
    end

    reg [2:0] cur_count, next_count;
    reg [9:0] next_state;
    reg [9:0] cur_state;
    reg [2:0] next_offset , cur_offset;
    
    //lw  & sw
    localparam [9:0] NO_L_SW    = 10'b00000_00000;
    localparam [9:0] LW_IDLE    = 10'b00000_00001;
    localparam [9:0] LW_ADDR    = 10'b00000_00010;
    localparam [9:0] LW_WRITE   = 10'b00000_00100;
    localparam [9:0] LW_READ    = 10'b00000_01000;
    localparam [9:0] LW_DREAD   = 10'b00000_10000;
    localparam [9:0] LW_ISTALL  = 10'b00000_10001;


    localparam [9:0] SW_IDLE    = 10'b00001_00000;
    localparam [9:0] SW_ADDR    = 10'b00010_00000;
    localparam [9:0] SW_WRITE   = 10'b00100_00000;
    localparam [9:0] SW_READ    = 10'b01000_00000;
    localparam [9:0] SW_DREAD   = 10'b10000_00000;

//lw
    wire [ADDR_WIDTH -1 :0]  cache_line_addr = {mem_addr_cur[ADDR_WIDTH-1 : OFFSET_WIDTH+2],
                                            {(OFFSET_WIDTH + Byte_c){1'b0}}};

    wire [ADDR_WIDTH -1 :0] cache_wb_addr = LRU_sel == (2'b10) ?
        {index_cur,cache_tag_out[0],{(OFFSET_WIDTH+Byte_c){1'b0}}}:
            {index_cur,cache_tag_out[1],{(OFFSET_WIDTH+Byte_c){1'b0}}};

    reg [31:0] Cache_mem_data_reg;
    reg [31:0] Cache_mem_data;
    always @(*) begin
        if(rst || miss)begin
            Cache_mem_data= 32'h0000_0000;
        end else begin
            Cache_mem_data = (hit_tag == 2'b01)? cache_block_out_v1[offset_cur] :cache_block_out_v2[offset_cur] ;
        end
    end

    always @(posedge clk ) begin
        if(rst)begin
            Cache_mem_data_reg <= 32'h0000_0000;
        end else begin
            if(D_i_stall && (cur_state == LW_ISTALL))begin
                Cache_mem_data_reg <= Cache_mem_data_reg;
            end else begin
                Cache_mem_data_reg <=  Cache_mem_data;
            end
        end
    end

    assign mem_data = (cur_state == LW_ISTALL)? Cache_mem_data_reg : Cache_mem_data;

    /*always @(*) begin
        if(rst)begin
            dirty = 1'b0;
        end else if(!miss ||!reg_cache_ena) begin
            dirty = 1'b0;
        end else begin
            dirty = (LRU_sel_next == 2'b01)? cache_tag_out[1][21] : cache_tag_out[0][21];
        end
    end*/

    always @(*) begin
        if(rst)begin
            dirty = 1'b0;
        end else if(miss)begin
            dirty = (LRU_sel_next == 2'b01)? cache_tag_out[1][21] : cache_tag_out[0][21];
        end else begin
            dirty = 1'b0;
        end
    end

    always @(posedge clk) begin
        if(rst)begin
            cur_count   <= 3'b000;
            cur_state   <= NO_L_SW;
            cur_offset  <= 3'b000;
            LRU_sel     <= 2'b01;
        end else begin
            cur_count   <= next_count;
            cur_state   <= next_state;
            cur_offset  <= next_offset;
            LRU_sel     <= LRU_sel_next;
        end 
    end
    assign d_cache_stall = (rst)? 1'b0 :   (next_state == LW_ADDR || next_state == LW_READ ||next_state == LW_DREAD ||next_state == LW_WRITE ||
                                            next_state == SW_ADDR || next_state == SW_READ ||next_state == SW_DREAD ||next_state == SW_WRITE ||
                                            cur_state == SW_ADDR || cur_state == SW_READ ||cur_state == SW_DREAD ||cur_state == SW_WRITE|| cur_state == SW_IDLE||
                                            cur_state == LW_ADDR || cur_state == LW_READ ||cur_state == LW_DREAD ||cur_state == LW_WRITE )? 1'b1:1'b0;

    always @(posedge clk ) begin
        raddr_rcv <= rst             ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                     (cur_state == SW_DREAD || cur_state == LW_DREAD ||cur_state == SW_READ ||cur_state == LW_READ)? 1'b0 : raddr_rcv;
        waddr_rcv <= rst             ? 1'b0 :
                    awvalid&&awready ? 1'b1 :
                    (cur_state == SW_DREAD || cur_state == LW_DREAD ||cur_state == SW_READ ||cur_state == LW_READ)? 1'b0 : waddr_rcv;
        wdata_rcv <= rst                  ? 1'b0 :
                    wvalid&&wready&&wlast ? 1'b1 :
                    (cur_state == SW_DREAD || cur_state == LW_DREAD ||cur_state == SW_READ ||cur_state == LW_READ)? 1'b0 : wdata_rcv;
    end
    assign bready  = waddr_rcv; 
    integer  i;
    always @(*) begin
        if(rst) begin
            cache_ena = 1'b0;
            next_state   = NO_L_SW;
            next_offset  = 3'b000;
            LRU_sel_next = 2'b01;
            next_count   = 3'b000;
            
            arvalid = 1'b0;
            araddr  = 32'h0000_0000;
            arlen   = 8'b0000_0000;
            
            awvalid = 1'b0;
            awaddr  = 32'h0000_0000;
            awlen   = 8'b0000_0000;

            wvalid = 1'b0;
            wlast  = 1'b0;
            for(i = 0;i<CACHE_LINE_SIZE;i = i+1)begin
                write_buffer [i] = 32'h0000_0000;
            end
        end else begin
            case(cur_state)
                NO_L_SW:begin
                    LRU_sel_next = LRU_sel;
                    araddr   = 32'h0000_0000;
                    arlen    = 8'b0000_0000;
                    arvalid  = 1'b0;

                    awaddr   = 32'h0000_0000;
                    awlen    = 8'b0000_0000;
                    awvalid  = 1'b0;

                    wvalid = 1'b0;
                    wlast  = 1'b0;

                    next_offset = 3'b000;
                    write_tag_en[0] = 3'b000;
                    write_tag_en[1] = 3'b000;
                    for(i = 0;i<CACHE_LINE_SIZE;i= i+1) begin
                        write_data_bank_en_v1[i] = 4'b0000;
                        write_data_bank_en_v2[i] = 4'b0000;
                    end
                    case(data_cache_status)
                        CACHE_IDLE:begin
                            next_state  = NO_L_SW;
                            cache_ena = 1'b0;
                        end
                        CACHE_READ:begin
                            next_state  = LW_IDLE;
                            cache_ena  = 1'b1;
                        end
                        CACHE_WRITE:begin
                            next_state =  SW_IDLE;
                            cache_ena = 1'b1;
                        end
                        default:begin
                            next_state = NO_L_SW;
                        end
                    endcase
                end

                LW_IDLE:begin
                    write_tag_en[0] = 3'b000;
                    write_tag_en[1] = 3'b000;
                    for(i = 0;i<CACHE_LINE_SIZE;i= i+1) begin
                        write_data_bank_en_v1[i] = 4'b0000;
                        write_data_bank_en_v2[i] = 4'b0000;
                    end
                    if(!miss)begin
                        LRU_sel_next = hit_tag;
                        if(D_i_stall) begin
                            next_state = LW_ISTALL;
                            cache_ena = 1'b1;
                        end else begin
                        case(data_cache_status)
                            CACHE_IDLE:begin
                                next_state  = NO_L_SW;
                                cache_ena   = 1'b0;
                            end
                            CACHE_READ:begin
                                next_state  = LW_IDLE;
                                cache_ena   = 1'b1;
                            end
                            CACHE_WRITE:begin
                                next_state  =  SW_IDLE;
                                cache_ena   =  1'b1;
                            end
                        endcase 
                    end
                    end else begin
                        LRU_sel_next = LRU_sel;
                        next_state  = LW_ADDR;
                        cache_ena = 1'b1;
                    end
                end

                LW_ADDR:begin
                    cache_ena  =1'b1;
                    LRU_sel_next = LRU_sel;
                    cache_ena = 1'b1;
                    if(dirty)begin
                        arvalid     = 1'b1;
                        arlen       = CACHE_LINE_SIZE-1;
                        araddr      = cache_line_addr;

                        awvalid     = 1'b1;
                        awlen       = CACHE_LINE_SIZE -1;
                        awaddr      = cache_wb_addr;
                        wvalid      = 1'b1;
                        next_state  = (waddr_rcv && wready && raddr_rcv)?  LW_WRITE :LW_ADDR;
                    end else begin
                        arvalid     = 1'b1;
                        arlen       = CACHE_LINE_SIZE-1;
                        araddr      = cache_line_addr;

                        next_state  = arready? LW_READ : LW_ADDR;
                    end
                end

                LW_READ:begin
                    araddr <= 32'h0000_0000;
                    arlen <= 8'b0000_0000;
                    arvalid <= 1'b0;
                    cache_block_in[cur_offset] = rdata;
                    cache_tag_in = {4'b0001,tag_cur};
                    LRU_sel_next = LRU_sel;
                    
                    case(LRU_sel_next)
                        2'b01:begin
                            write_tag_en[0] = 3'b000;
                            write_tag_en[1] = 3'b111;
                            for(i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i!=cur_offset)begin
                                    write_data_bank_en_v2[i] = 4'b0000;
                                end
                                write_data_bank_en_v1[i] = 4'b0000;
                            end
                            write_data_bank_en_v2[cur_offset] = 4'b1111;
                        end
                        2'b10:begin
                            write_tag_en[0] = 3'b111;
                            write_tag_en[1] = 3'b000;
                            for(i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i != cur_offset)begin
                                    write_data_bank_en_v1[i] = 4'b0000;
                                end
                                write_data_bank_en_v2[i] = 4'b0000;
                            end
                            write_data_bank_en_v1[cur_offset] = 4'b1111;
                        end
                    endcase

                    if(rlast)begin
                        next_offset = 3'b000;
                        if(D_i_stall)begin
                            next_state = LW_ISTALL;
                            cache_ena = 1'b1;
                        end else begin
                            next_state = NO_L_SW;
                            cache_ena = 1'b0;
                        end
                    end else begin
                        cache_ena = 1'b1;
                        next_state  = LW_READ;
                        next_offset = cur_offset + 1;
                    end
                end

                LW_WRITE:begin
                    LRU_sel_next = LRU_sel;
                    cache_ena = 1'b1;
                    araddr <= 32'h0000_0000;
                    arlen <= 8'b0000_0000;
                    arvalid <= 1'b0;

                    awaddr <= 32'h0000_0000;
                    awlen <= 8'b0000_0000;
                    awvalid <= 1'b0;

                    wvalid = 1'b1;
                    case(hit_tag)
                        2'b01:begin
                            wdata = cache_block_out_v1[cur_count];
                        end
                        2'b10:begin
                            wdata = cache_block_out_v2[cur_count];
                        end
                    endcase
                    write_buffer[cur_offset] = rdata;
                    if(cur_count < 3'b111)begin
                        next_state   = LW_WRITE;
                        next_offset  = cur_offset + 1;
                        next_count   = cur_count  + 1;
                    end else begin
                        wlast        = 1'b1;
                        next_state   = LW_DREAD;
                        next_offset  = 3'b000;
                        next_count   = 3'b000;
                    end
                end

                LW_DREAD:begin
                    wlast = 1'b0;
                    wvalid = 1'b0;
                    LRU_sel_next = LRU_sel;
                    cache_block_in[0] = write_buffer[0];
                    cache_block_in[1] = write_buffer[1];
                    cache_block_in[2] = write_buffer[2];
                    cache_block_in[3] = write_buffer[3];
                    cache_block_in[4] = write_buffer[4];
                    cache_block_in[5] = write_buffer[5];
                    cache_block_in[6] = write_buffer[6];
                    cache_block_in[7] = write_buffer[7];
                    cache_tag_in = {4'b0001,tag_cur};
                    case(LRU_sel_next)
                        2'b01:begin
                            write_tag_en[0] = 3'b000;
                            write_tag_en[1] = 3'b111;
                            for(i = 0;i<CACHE_LINE_SIZE; i = i+1)begin
                                write_data_bank_en_v2[i] = 4'b1111;
                                write_data_bank_en_v1[i] = 4'b0000;
                            end
                        end
                        2'b10:begin
                            write_tag_en[0] = 3'b111;
                            write_tag_en[1] = 3'b000;
                            for(i = 0; i<CACHE_LINE_SIZE;i = i +1)begin
                                write_data_bank_en_v1[i] = 4'b1111;
                                write_data_bank_en_v2[i] = 4'b0000;
                            end
                        end
                    endcase
                    if(D_i_stall)begin
                        next_state = LW_ISTALL;
                        cache_ena = 1'b1;
                    end else begin
                        next_state = NO_L_SW;
                        cache_ena = 1'b0;
                    end
                end

                LW_ISTALL:begin
                    LRU_sel_next = LRU_sel;
                    if(D_i_stall) begin
                        next_state = LW_ISTALL;
                        cache_ena = 1'b1;
                    end else begin
                        next_state = NO_L_SW;
                        cache_ena = 1'b0;
                    end
                end

                SW_IDLE:begin
                    write_tag_en[0] = 3'b000;
                    write_tag_en[1] = 3'b000;
                    cache_block_in[offset_cur] = w_mem_data_reg;
                    if(!miss) begin
                        LRU_sel_next = hit_tag;
                        next_state = NO_L_SW;
                        cache_ena  = 1'b0;
                        case(hit_tag)
                            2'b01:begin
                                for( i = 0;i<CACHE_LINE_SIZE;i = i+1)begin
                                    if(i != offset_cur)begin
                                        write_data_bank_en_v1[i] = 4'b0000;
                                    end
                                        write_data_bank_en_v2[i] = 4'b0000;
                                end
                                write_data_bank_en_v1[offset_cur] = w_mem_ena_reg;
                            end
                            2'b10:begin
                                for( i = 0;i<CACHE_LINE_SIZE;i = i+1)begin
                                    if(i != offset_cur)begin
                                        write_data_bank_en_v2[i] = 4'b0000;
                                    end
                                        write_data_bank_en_v1[i] = 4'b0000;
                                end
                                write_data_bank_en_v2[offset_cur] = w_mem_ena_reg;
                            end
                        endcase

                    end else begin
                        for(i = 0;i < CACHE_LINE_SIZE;i= i+1) begin
                            write_data_bank_en_v1[i] = 4'b0000;
                            write_data_bank_en_v2[i] = 4'b0000;
                        end
                        cache_ena  = 1'b1;
                        LRU_sel_next = LRU_sel;
                        next_state  = SW_ADDR;
                    end
                end

                SW_ADDR:begin
                    cache_ena = 1'b1;
                    LRU_sel_next = LRU_sel;
                    if(dirty) begin
                        araddr  <= cache_line_addr;
                        arlen   <= CACHE_LINE_SIZE -1;
                        arvalid <= 1'b1;

                        awaddr  <= cache_wb_addr;
                        awlen   <= CACHE_LINE_SIZE -1;
                        awvalid <= 1'b1;

                        wvalid = 1'b1;
                        wlast  = 1'b0;

                        next_state = (raddr_rcv && waddr_rcv  && wready)? SW_WRITE:SW_ADDR;
                    end else begin
                        araddr  <= cache_line_addr;
                        arlen   <= CACHE_LINE_SIZE -1;
                        arvalid <= 1'b1;
                        next_state  = arready? SW_READ: SW_ADDR;
                    end
                end

                SW_READ:begin   //ok
                    LRU_sel_next = LRU_sel;
                    araddr  <= 32'h0000_0000;
                    arlen   <= 8'b0000_0000;
                    arvalid <= 1'b0;
                    cache_tag_in = {4'b0011,tag_cur};
                    cache_block_in[cur_offset] = (cur_offset == offset_cur)? w_mem_data_reg : rdata;
                    case(LRU_sel_next)
                        2'b01:begin
                            write_tag_en[0] = 3'b000;
                            write_tag_en[1] = 3'b111;
                            for(i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i!=cur_offset)begin
                                    write_data_bank_en_v2[i] = 4'b0000;
                                end
                                write_data_bank_en_v1[i] = 4'b0000;
                            end
                            write_data_bank_en_v2[cur_offset] = 4'b1111;
                        end
                        2'b10:begin
                            write_tag_en[0] = 3'b111;
                            write_tag_en[1] = 3'b000;
                            for(i = 0 ;i<CACHE_LINE_SIZE;i = i+1) begin
                                if(i != cur_offset)begin
                                    write_data_bank_en_v1[i] = 4'b0000;
                                end
                                write_data_bank_en_v2[i] = 4'b0000;
                            end
                            write_data_bank_en_v1[cur_offset] = 4'b1111;
                        end
                    endcase
                    if(rlast)begin
                        next_offset = 3'b000;
                        next_state  = NO_L_SW;
                        cache_ena   = 1'b0;
                    end else begin
                        next_state  = SW_READ;
                        cache_ena = 1'b1;
                        next_offset = cur_offset + 1;
                    end
                end

                SW_WRITE:begin
                    cache_ena = 1'b1;
                    LRU_sel_next = LRU_sel;
                    araddr  <= 32'h0000_0000;
                    arlen   <= 8'b0000_0000;
                    arvalid <= 1'b0;

                    awaddr  <= 32'h0000_0000;
                    awlen   <= 8'b0000_0000;
                    awvalid <= 1'b0;
                    
                    case(LRU_sel_next)
                        2'b01:begin
                            wdata = cache_block_out_v2[cur_count];
                        end
                        2'b10:begin
                            wdata = cache_block_out_v1[cur_count];
                        end
                    endcase
                    write_buffer [cur_offset] = (cur_offset ==offset_cur)?
                                                                w_mem_data_reg:rdata;
                    if(cur_count < 3'b111)begin
                        wvalid = 1'b1;
                        next_state   = SW_WRITE;
                        next_offset  = cur_offset + 1;
                        next_count   = cur_count  + 1;
                    end else begin
                        wvalid = 1'b0;
                        wlast        = 1'b1;
                        next_state   = SW_DREAD;
                        next_offset  = 3'b000;
                        next_count   = 3'b000;
                    end
                end

                SW_DREAD:begin
                    LRU_sel_next = LRU_sel;
                    wlast = 1'b0;
                    wvalid = 1'b0;
                    cache_block_in[0] = write_buffer[0];
                    cache_block_in[1] = write_buffer[1];
                    cache_block_in[2] = write_buffer[2];
                    cache_block_in[3] = write_buffer[3];
                    cache_block_in[4] = write_buffer[4];
                    cache_block_in[5] = write_buffer[5];
                    cache_block_in[6] = write_buffer[6];
                    cache_block_in[7] = write_buffer[7];
                    cache_tag_in = {4'b0011,tag_cur};
                    case(LRU_sel_next)
                        2'b01:begin
                            write_tag_en [0] = 3'b000;
                            write_tag_en [1] = 3'b111;
                            for(i = 0;i<CACHE_LINE_SIZE; i = i+1)begin
                                write_data_bank_en_v2[i] = 4'b1111;
                            end
                        end
                        2'b10:begin
                            write_tag_en [0] = 3'b111;
                            write_tag_en [1] = 3'b000;
                            for(i = 0;i<CACHE_LINE_SIZE; i = i+1)begin
                                write_data_bank_en_v1[i] = 4'b1111;
                            end
                        end
                    endcase
                    next_state = NO_L_SW;
                    cache_ena  = 1'b0;
                end
            endcase
        end
    end
endmodule