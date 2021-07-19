`timescale 1ns / 1ps

module d_cache #(
    parameter WAY       = 2,
    parameter LINE_SIZE = 16,
    parameter LINE_NUM  = 256
) (
    input   wire        clk,
    input   wire        rst,

    input   wire        cpu_en,
    input   wire [3 :0] cpu_wen,
    input   wire [3 :0] cpu_load_type,
    input   wire [31:0] cpu_vaddr,
    input   wire [31:0] cpu_psyaddr,
    input   wire [31:0] cpu_wdata,
    output  wire [31:0] cpu_rdata,
    output  reg  [31:0] cpu_d_cache_stall,

    // axi
    output  reg  [31:0] axi_araddr,
    output  reg  [3 :0] axi_arlen,
    output  reg  [2 :0] axi_arsize,
    output  reg         axi_arvalid,
    input   wire        axi_arready,

    input   wire [31:0] axi_rdata,
    input   wire        axi_rlast,
    input   wire        axi_rvalid,
    output  reg         axi_rready,

    output  wire [31:0] axi_awaddr,
    output  wire [3 :0] axi_awlen,
    output  wire [2 :0] axi_awsize,
    output  wire        axi_awvalid,
    input   wire        axi_awready,
    
    output  wire [31:0] axi_wdata,
    output  wire [3 :0] axi_wstrb,
    output  wire        axi_wlast,
    output  wire        axi_wvalid,
    input   wire        axi_wready,

    input   wire        axi_bvalid,
    output  wire        axi_bready
);
    
    //  parameters
    
    localparam OFFSET_LOG   = $clog2(LINE_SIZE / 4);
    localparam INDEX_LOG    = $clog2(LINE_NUM);
    localparam WAY_LOG      = $clog2(WAY);
    localparam TAG_INDEX    = 32 - 2 - OFFSET_LOG - INDEX_LOG;

    localparam [2 :0] IDLE_STATE   = 0;
    localparam [2 :0] LOOKUP_STATE = 1;
    localparam [2 :0] MISS_STATE   = 2;
    localparam [2 :0] REPLACE_STATE= 3;
    localparam [2 :0] REFILL_STATE = 4;
    localparam [2 :0] WRITE_STATE  = 5;

    initial begin
        if (LINE_SIZE * LINE_NUM != 4 * 1024) begin
            $display("ERROR! NOT 4K PAGE SIZE!");
            $finish;
        end
    end

    // wires and regs

    reg  [2 :0] master_state;
    reg  [2 :0] master_next_state;
    reg  [2 :0] slave_state;
    reg  [2 :0] slave_next_state;


    // instances
    wire                dirty_ena   [WAY-1:0];
    wire                dirty_wea   [WAY-1:0];
    wire [INDEX_LOG-1:0]dirty_addra [WAY-1:0];
    wire                dirty_dina  [WAY-1:0];
    wire                dirty_douta [WAY-1:0];

    wire                tagv_ena    [WAY-1:0];
    wire                tagv_wea    [WAY-1:0];
    wire [INDEX_LOG-1:0]tagv_addra  [WAY-1:0];
    wire [20         :0]tagv_dina   [WAY-1:0];
    wire [20         :0]tagv_douta  [WAY-1:0];

    wire [WAY*OFFSET_LOG-1:0]   bank_ena    ;
    wire [3          :0]        bank_wea    [WAY*OFFSET_LOG-1:0];
    wire [INDEX_LOG-1:0]        bank_addra  [WAY*OFFSET_LOG-1:0];
    wire [31         :0]        bank_dina   [WAY*OFFSET_LOG-1:0];
    wire [31         :0]        bank_douta  [WAY*OFFSET_LOG-1:0];

    wire [WAY*OFFSET_LOG-1:0]   refill_en   ;
    wire [3          :0]        refill_wea  ;
    wire [INDEX_LOG-1:0]        refill_addra;
    wire [31         :0]        refill_dina ;

    wire [WAY*OFFSET_LOG-1:0]   wbuffer_en   ;
    wire [3          :0]        wbuffer_wea  ;
    wire [INDEX_LOG-1:0]        wbuffer_addra;
    wire [31         :0]        wbuffer_dina ;

    genvar i, j;
    generate
        for (i = 0; i < WAY; i = i + 1) begin: dirty
            D dirty_inst (
                .clka   (clk            ),
                .ena    (dirty_ena[i]   ),
                .wea    (dirty_wea[i]   ),
                .addra  (dirty_addra[i] ),
                .dina   (dirty_dina[i]  ),
                .douta  (dirty_douta[i] )
            );
        end

        for (i = 0; i < WAY; i = i + 1) begin: tagv
            TAGV tagv_inst (
                .clka   (clk            ),
                .ena    (tagv_ena[i]    ),
                .wea    (tagv_wea[i]    ),
                .addra  (tagv_addra[i]  ),
                .dina   (tagv_dina[i]   ),
                .douta  (tagv_douta[i]  )
            );
        end

        for (i = 0; i < WAY; i = i + 1) begin: data
            for (j = 0; j < LINE_SIZE / 4; j = j + 1) begin: bank
                DATA bank_inst (
                .clka   (clk                        ),
                .ena    (bank_ena[i*OFFSET_LOG+j]   ),
                .wea    (bank_wea[i*OFFSET_LOG+j]   ),
                .addra  (bank_addra[i*OFFSET_LOG+j] ),
                .dina   (bank_dina[i*OFFSET_LOG+j]  ),
                .douta  (bank_douta[i*OFFSET_LOG+j] )
                );             
            end
        end
    endgenerate

    wire                    wbuffer_en_i;
    wire [1             :0] wbuffer_hit_sel_i;
    wire [3             :0] wbuffer_wen_i;
    wire [INDEX_LOG -1  :0] wbuffer_index_i;
    wire [OFFSET_LOG-1  :0] wbuffer_offset_i;
    wire [31            :0] wbuffer_wdata_i;

    wire                    wbuffer_en_reg;
    wire [1             :0] wbuffer_hit_sel_reg;
    wire [3             :0] wbuffer_wen_reg;
    wire [INDEX_LOG -1  :0] wbuffer_index_reg;
    wire [OFFSET_LOG-1  :0] wbuffer_offset_reg;
    wire [31            :0] wbuffer_wdata_reg;

    write_buffer write_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        .stall      (),
        
        .en_i       (wbuffer_en_i       ),
        .hit_sel_i  (wbuffer_hit_sel_i  ),
        .wen_i      (wbuffer_wen_i      ),
        .index_i    (wbuffer_index_i    ),
        .offset_i   (wbuffer_offset_i   ),
        .wdata_i    (wbuffer_wdata_i    ),

        .en_o       (wbuffer_en_reg     ),
        .hit_sel_o  (wbuffer_hit_sel_reg),
        .wen_o      (wbuffer_wen_reg    ),
        .index_o    (wbuffer_index_reg  ),
        .offset_o   (wbuffer_offset_reg ),
        .wdata_o    (wbuffer_wdata_reg  )
    );

    wire        en_reg;
    wire [3 :0] wen_reg;
    wire [3 :0] load_type_reg;
    wire [31:0] vaddr_reg;
    wire [31:0] psyaddr_reg;
    wire [31:0] wdata_reg;

    request_buffer request_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        
        .en_i       (cpu_en             ),
        .wen_i      (cpu_wen            ),
        .load_type_i(cpu_load_type      ),
        .vaddr_i    (cpu_vaddr          ),
        .psyaddr_i  (cpu_psyaddr        ),
        .wdata_i    (cpu_wdata          ),

        .en_o       (en_reg             ),
        .wen_o      (wen_reg            ),
        .load_type_o(load_type_reg      ),
        .vaddr_o    (vaddr_reg          ),
        .psyaddr_o  (psyaddr_reg        ),
        .wdata_o    (wdata_reg          )
    );

    reg                     axi_buffer_en;
    reg  [31:0]             axi_buffer_addr;
    reg  [LINE_SIZE*8-1:0]  axi_buffer_data;
    wire                    axi_buffer_free;

    write_axi_buffer #(LINE_SIZE) write_axi_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        
        .en         (axi_buffer_en      ),
        .addr       (axi_buffer_addr    ),
        .data       (axi_buffer_data    ),
        .empty      (axi_buffer_free    ),

        .axi_awaddr (axi_awaddr         ),
        .axi_awlen  (axi_awlen          ),
        .axi_awsize (axi_awsize         ),
        .axi_awvalid(axi_awvalid        ),
        .axi_awready(axi_awready        ),
        .axi_wdata  (axi_wdata          ),
        .axi_wstrb  (axi_wstrb          ),
        .axi_wlast  (axi_wlast          ),
        .axi_wvalid (axi_wvalid         ),
        .axi_wready (axi_wready         ),
        .axi_bvalid (axi_bvalid         ),
        .axi_bready (axi_bready         )
    );

    wire [WAY_LOG-1:0]  lfsr_sel;
    reg  [WAY_LOG-1:0]  lfsr_sel_reg;
    reg                 lfsr_stall;
    LFSR #(WAY_LOG) lfsr0 (
        .clk        (clk                ),
        .rst        (rst                ),
        .out        (lfsr_sel           )
    );

    always @(posedge clk ) begin
        if (rst) begin
            lfsr_sel_reg <= {WAY_LOG{1'b0}};
        end else if (~lfsr_stall) begin
            lfsr_sel_reg <= lfsr_sel;
        end
    end

    // logic

    wire [INDEX_LOG -1:0] cpu_index     = cpu_vaddr[2+OFFSET_LOG+INDEX_LOG-1:2+OFFSET_LOG];
    wire [OFFSET_LOG-1:0] cpu_offset    = cpu_vaddr[2+OFFSET_LOG-1          :2];
    
    wire [INDEX_LOG -1:0] index_reg     = vaddr_reg[2+OFFSET_LOG+INDEX_LOG-1:2+OFFSET_LOG];
    wire [OFFSET_LOG-1:0] offset_reg    = vaddr_reg[2+OFFSET_LOG-1          :2];

    wire [TAG_INDEX -1:0] tag_reg       = psyaddr_reg[31:2+OFFSET_LOG+INDEX_LOG];

    wire hit_write_conflict             = 
        wbuffer_en_reg & (wbuffer_offset_reg == cpu_offset | wbuffer_offset_i == cpu_offset);
    
    wire [WAY       -1:0] hit_sel       = {
        (tag_reg == tagv_douta[1][TAG_INDEX:1]) & tagv_douta[1][0],
        (tag_reg == tagv_douta[0][TAG_INDEX:1]) & tagv_douta[0][0]
    };
    wire miss                           = hit_sel == 2'b00;
    reg  [OFFSET_LOG-1:0] write_line_counter;


    // REFILL
    wire [31:0] refill_wen32        = 
        {{8{wen_reg[3]}}, {8{wen_reg[2]}}, {8{wen_reg[1]}}, {8{wen_reg[0]}}};
    wire [31:0] refill_store_data   =
        wdata_reg & refill_wen32 | axi_rdata & ~refill_wen32;
    decoder decoder2_4 (
        .in     (write_line_counter ),
        .out    (refill_offset_sel  )
    );
    assign refill_en                = 
        {{4{lfsr_sel_reg}} & refill_offset_sel, {4{lfsr_sel_reg}} & refill_offset_sel};
    assign refill_wea               = 4'b1111;
    assign refill_addra             = index_reg;
    assign refill_dina              =
        (offset_reg == write_line_counter) && (|wen_reg) ? 
            refill_store_data : axi_rdata;
    
    // write buffer
    assign wbuffer_en               =
        {{4{wbuffer_hit_sel_reg}} & wbuffer_offset_reg, {4{wbuffer_hit_sel_reg}} & wbuffer_offset_reg};
    assign wbuffer_wea              = wbuffer_wen_reg;
    assign wbuffer_addra            = wbuffer_index_reg;
    assign wbuffer_dina             = wbuffer_wdata_reg;



    always @(posedge clk) begin
        if (rst) begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end else if (master_state == REFILL_STATE && axi_rvalid) begin
            write_line_counter <= write_line_counter + {OFFSET_LOG{1'b1}};
        end else begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end
    end

    always @(*) begin
        lfsr_stall          = 1'b0;
        cpu_d_cache_stall   = 1'b0;
        master_next_state   = IDLE_STATE;

        axi_buffer_en       = 1'b0;
        axi_buffer_addr     = 32'h0;
        axi_buffer_data     = {LINE_SIZE*8{1'b0}};

        axi_araddr          = 32'h0;
        axi_arlen           = 4'h0;
        axi_arsize          = 3'h0;
        axi_arvalid         = 1'b0;

        case (master_state)
        IDLE_STATE: begin
            lfsr_stall      = 1'b0;
            if (~cpu_en | cpu_en & hit_write_conflict) begin
                master_next_state = IDLE_STATE;
                cpu_d_cache_stall = 1'b1; 
            end else begin
                master_next_state = LOOKUP_STATE;
                cpu_d_cache_stall = 1'b0; 
            end 
        end

        LOOKUP_STATE: begin
            lfsr_stall      = 1'b0;
            if (~miss & (~cpu_en | cpu_en & hit_write_conflict)) begin
                master_next_state = IDLE_STATE;
                cpu_d_cache_stall = 1'b1;
            end else if (~miss & cpu_en) begin
                master_next_state = LOOKUP_STATE;
                cpu_d_cache_stall = 1'b0;
            end else begin
                master_next_state = MISS_STATE;
                cpu_d_cache_stall = 1'b1;
            end
        end

        MISS_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            lfsr_stall              = 1'b0;
            if (~axi_buffer_free) begin
                master_next_state   = MISS_STATE;
            end else begin
                master_next_state   = REPLACE_STATE;
                lfsr_stall          = 1'b1;
                axi_buffer_en       = dirty_douta[lfsr_sel];
                axi_buffer_addr     = {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}};
                axi_buffer_data     = {
                    bank_douta[lfsr_sel][3],
                    bank_douta[lfsr_sel][2],
                    bank_douta[lfsr_sel][1],
                    bank_douta[lfsr_sel][0]
                };
                
                axi_araddr          = {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}};
                axi_arlen           = LINE_SIZE / 4 - 1;
                axi_arsize          = 3'b010;
                axi_arvalid         = 1'b1;
            end
        end

        REPLACE_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            lfsr_stall              = 1'b1;
            if (axi_arready) begin
                master_next_state   = REFILL_STATE;
            end else begin
                master_next_state   = REPLACE_STATE;
            end
        end

        REFILL_STATE: begin
            axi_rready              = 1'b1;
            lfsr_stall              = 1'b1;
            cpu_d_cache_stall       = 1'b1;
            if (axi_rvalid & axi_rlast) begin
                master_next_state   = IDLE_STATE;
            end else begin
                master_next_state   = REFILL_STATE;
            end
        end
        
        default: begin
            
        end

        endcase
    end

    always @(*) begin
        case (slave_state)
        IDLE_STATE: begin
            if (wbuffer_en_i) begin
                slave_next_state = WRITE_STATE;
            end else begin
                slave_next_state = IDLE_STATE;
            end
        end

        WRITE_STATE: begin
            if (wbuffer_en_reg) begin
                slave_next_state = WRITE_STATE;
            end else begin
                slave_next_state = IDLE_STATE;
            end
        end 

        default: begin
            
        end
        endcase 
    end

endmodule