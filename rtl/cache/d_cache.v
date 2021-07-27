`timescale 1ns / 1ps

`include "../idu/id_def.v"

module d_cache #(
    parameter WAY       = 2,
    parameter LINE_SIZE = 16,
    parameter LINE_NUM  = 256
) (
    input   wire        clk,
    input   wire        rst,

    input   wire        cpu_en,
    input   wire [3 :0] cpu_wen,
    input   wire        cpu_uncached,
    input   wire [3 :0] cpu_load_type,
    input   wire [31:0] cpu_vaddr,
    input   wire [31:0] cpu_psyaddr,
    input   wire [31:0] cpu_wdata,
    output  wire [31:0] cpu_rdata,
    output  reg         cpu_d_cache_stall,

    output  wire [31:0] axi_awaddr,
    output  wire [7 :0] axi_awlen,
    output  wire [2 :0] axi_awsize,
    output  wire        axi_awvalid,
    input   wire        axi_awready,
    output  wire [31:0] axi_wdata,
    output  wire [3 :0] axi_wstrb,
    output  wire        axi_wlast,
    output  wire        axi_wvalid,
    input   wire        axi_wready,
    output  reg  [31:0] axi_araddr,
    output  reg  [7 :0] axi_arlen,
    output  reg  [2 :0] axi_arsize,
    output  reg         axi_arvalid,
    input   wire        axi_arready,
    input   wire [31:0] axi_rdata,
    input   wire        axi_rlast,
    input   wire        axi_rvalid,
    output  reg         axi_rready,
    input   wire        axi_bvalid,
    output  wire        axi_bready
);

    //  parameters
    
    localparam OFFSET_LOG   = $clog2(LINE_SIZE / 4);
    localparam WORD_NUM     = LINE_SIZE / 4;
    localparam INDEX_LOG    = $clog2(LINE_NUM);
    localparam WAY_LOG      = $clog2(WAY);
    localparam TAG_INDEX    = 32 - 2 - OFFSET_LOG - INDEX_LOG;

    localparam [2 :0] IDLE_STATE   = 0;
    localparam [2 :0] LOOKUP_STATE = 1;
    localparam [2 :0] MISS_STATE   = 2;
    localparam [2 :0] REPLACE_STATE= 3;
    localparam [2 :0] REFILL_STATE = 4;
    localparam [2 :0] WRITE_STATE  = 5;
    localparam [2 :0] WAIT_STATE   = 6;

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

    always @(posedge clk) begin
        if (rst) begin
            master_state    <= IDLE_STATE;
            slave_state     <= IDLE_STATE;
        end else begin
            master_state    <= master_next_state;
            slave_state     <= slave_next_state;
        end
    end


    // instances
    wire [WAY      -1:0]        dirty_ena   ;
    wire                        dirty_wea   ;
    wire [INDEX_LOG-1:0]        dirty_addra ;
    wire                        dirty_dina  ;
    wire [WAY      -1:0]        dirty_douta ;

    wire [WAY      -1:0]        tagv_ena    ;
    wire                        tagv_wea    ;
    wire [INDEX_LOG-1:0]        tagv_addra  ;
    wire [20         :0]        tagv_dina   ;
    wire [20         :0]        tagv_douta  [WAY-1:0];

    wire [WAY*WORD_NUM-1:0]     bank_ena    ;
    wire [4  *WORD_NUM-1:0]     bank_wea    ;
    wire [INDEX_LOG*WORD_NUM-1:0]bank_addra  ;
    wire [31         :0]        bank_dina   ;
    wire [32*WORD_NUM-1 :0]     bank_douta  [WAY-1:0];

    wire [31         :0]        refill_dina ;

    genvar i, j;
    generate
        for (i = 0; i < WAY; i = i + 1) begin: dirty
            D dirty_inst (
                .clka   (clk            ),
                .ena    (dirty_ena[i]   ),
                .wea    (dirty_wea      ),
                .addra  (dirty_addra    ),
                .dina   (dirty_dina     ),
                .douta  (dirty_douta[i] )
            );
        end

        for (i = 0; i < WAY; i = i + 1) begin: tagv
            TAGV tagv_inst (
                .clka   (clk            ),
                .ena    (tagv_ena[i]    ),
                .wea    (tagv_wea       ),
                .addra  (tagv_addra     ),
                .dina   (tagv_dina      ),
                .douta  (tagv_douta[i]  )
            );
        end

        for (i = 0; i < WAY; i = i + 1) begin: data
            for (j = 0; j < LINE_SIZE / 4; j = j + 1) begin: bank
                DATA bank_inst (
                .clka   (clk                        ),
                .ena    (bank_ena   [i*WORD_NUM+j]  ),
                .wea    (bank_wea   [j*4+:4] ),
                .addra  (bank_addra [j*INDEX_LOG+:INDEX_LOG]),
                .dina   (bank_dina                  ),
                .douta  (bank_douta [i][j*32+:32]   )
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
        .stall      (1'b0               ),
        
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
    wire        uncached_reg;
    wire [3 :0] load_type_reg;
    wire [31:0] vaddr_reg;
    wire [31:0] psyaddr_reg;
    wire [31:0] wdata_reg;

    request_buffer request_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        .stall      (cpu_d_cache_stall  |
                    ~cpu_en),
        
        .en_i       (cpu_en             ),
        .wen_i      (cpu_wen            ),
        .uncached_i (cpu_uncached       ),
        .load_type_i(cpu_load_type      ),
        .vaddr_i    (cpu_vaddr          ),
        .psyaddr_i  (cpu_psyaddr        ),
        .wdata_i    (cpu_wdata          ),

        .en_o       (en_reg             ),
        .wen_o      (wen_reg            ),
        .uncached_o (uncached_reg       ),
        .load_type_o(load_type_reg      ),
        .vaddr_o    (vaddr_reg          ),
        .psyaddr_o  (psyaddr_reg        ),
        .wdata_o    (wdata_reg          )
    );

    reg                     axi_buffer_en;
    reg                     axi_buffer_uncached;
    reg  [2 :0]             axi_buffer_size;
    reg  [3 :0]             axi_buffer_wstrb;
    reg  [31:0]             axi_buffer_addr;
    reg  [31:0]             axi_buffer_data;
    reg  [LINE_SIZE*8-1:0]  axi_buffer_cache_line;
    wire                    axi_buffer_free;

    write_axi_buffer #(LINE_SIZE) write_axi_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        
        .en         (axi_buffer_en      ),
        .uncached   (axi_buffer_uncached),
        .addr       (axi_buffer_addr    ),
        .size       (axi_buffer_size    ),
        .wstrb      (axi_buffer_wstrb   ),
        .data       (axi_buffer_data    ),
        .cache_line (axi_buffer_cache_line),
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
        wbuffer_en_reg & (wbuffer_offset_reg == cpu_offset) | wbuffer_en_i & (wbuffer_offset_i == cpu_offset);
    
    wire hit_write_conflict_wait        =
        wbuffer_en_reg & (wbuffer_offset_reg == offset_reg) | wbuffer_en_i & (wbuffer_offset_i == offset_reg);

    wire [WAY       -1:0] hit_sel       = {
        (tag_reg == tagv_douta[1][TAG_INDEX:1]) & tagv_douta[1][0],
        (tag_reg == tagv_douta[0][TAG_INDEX:1]) & tagv_douta[0][0]
    };
    wire miss                           = (hit_sel == 2'b00) | uncached_reg;

    reg  [OFFSET_LOG-1:0] write_line_counter;
    wire [WORD_NUM  -1:0] refill_offset_sel;

    // REFILL
    wire [31:0] refill_wen32        = 
        {{8{wen_reg[3]}}, {8{wen_reg[2]}}, {8{wen_reg[1]}}, {8{wen_reg[0]}}};
    wire [31:0] refill_store_data   =
        wdata_reg & refill_wen32 | axi_rdata & ~refill_wen32;
    decoder decoder2_4 (
        .in     (write_line_counter ),
        .out    (refill_offset_sel  )
    );
    assign refill_dina              =
        (offset_reg == write_line_counter) && (|wen_reg) ? 
            refill_store_data : axi_rdata;

    reg is_lookup;
    reg is_wait_lookup;
    reg is_hit_write;
    reg is_replace;
    reg is_refill;
    reg is_uncached_refill;

    always @(posedge clk) begin
        if (rst) begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end else if (master_state == REFILL_STATE && axi_rvalid) begin
            write_line_counter <= write_line_counter + 1;
        end else if (master_state != REFILL_STATE) begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end
    end


    wire [WORD_NUM-1:0] cpu_offset_sel;
    wire [WORD_NUM-1:0] offset_reg_sel;
    wire [WORD_NUM-1:0] wbuffer_offset_reg_sel;
    decoder decoder0 (
        .in     (cpu_offset     ),
        .out    (cpu_offset_sel )
    );
    decoder decoder1 (
        .in     (offset_reg     ),
        .out    (offset_reg_sel )
    );
    decoder decoder2 (
        .in     (wbuffer_offset_reg     ),
        .out    (wbuffer_offset_reg_sel )
    );

    assign tagv_ena             = 
        {WAY{is_lookup | is_wait_lookup}} |
        {lfsr_sel_reg, ~lfsr_sel_reg} & {WAY{is_replace | is_refill}};
    assign tagv_wea             = 
        is_refill;
    assign tagv_addra           = 
        {INDEX_LOG{is_lookup}} & cpu_index |
        {INDEX_LOG{is_wait_lookup| is_replace | is_refill}} & index_reg;
    assign tagv_dina            =
        {tag_reg, 1'b1};

    assign bank_ena             = 
        {cpu_offset_sel, cpu_offset_sel} & {WAY*WORD_NUM{is_lookup}} |
        {offset_reg_sel, offset_reg_sel} & {WAY*WORD_NUM{is_wait_lookup}} |
        {wbuffer_offset_reg_sel & {WORD_NUM{wbuffer_hit_sel_reg[1]}},
         wbuffer_offset_reg_sel & {WORD_NUM{wbuffer_hit_sel_reg[0]}}} & {WAY*WORD_NUM{is_hit_write}} |
        {{WORD_NUM{lfsr_sel_reg}}, {WORD_NUM{~lfsr_sel_reg}}} & {WAY*WORD_NUM{is_replace}}  |
        {{4{lfsr_sel_reg}} & refill_offset_sel, {4{~lfsr_sel_reg}} & refill_offset_sel} & {WAY*WORD_NUM{is_refill}};
    assign bank_wea             = 
        {
            wbuffer_wen_reg & {4{is_hit_write & wbuffer_offset_reg_sel[3]}},
            wbuffer_wen_reg & {4{is_hit_write & wbuffer_offset_reg_sel[2]}},
            wbuffer_wen_reg & {4{is_hit_write & wbuffer_offset_reg_sel[1]}},
            wbuffer_wen_reg & {4{is_hit_write & wbuffer_offset_reg_sel[0]}}
        } |
        {WORD_NUM*4{is_refill}};
    assign bank_addra           = 
        {
            cpu_index & {INDEX_LOG{is_lookup & cpu_offset_sel[3]}},
            cpu_index & {INDEX_LOG{is_lookup & cpu_offset_sel[2]}},
            cpu_index & {INDEX_LOG{is_lookup & cpu_offset_sel[1]}},
            cpu_index & {INDEX_LOG{is_lookup & cpu_offset_sel[0]}}
        } |
        {
            wbuffer_index_reg & {INDEX_LOG{is_hit_write & wbuffer_offset_reg_sel[3]}},
            wbuffer_index_reg & {INDEX_LOG{is_hit_write & wbuffer_offset_reg_sel[2]}},
            wbuffer_index_reg & {INDEX_LOG{is_hit_write & wbuffer_offset_reg_sel[1]}},
            wbuffer_index_reg & {INDEX_LOG{is_hit_write & wbuffer_offset_reg_sel[0]}}
        } |
        {   
            index_reg & {INDEX_LOG{is_wait_lookup & offset_reg_sel[3] | is_refill | is_replace}},
            index_reg & {INDEX_LOG{is_wait_lookup & offset_reg_sel[2] | is_refill | is_replace}},
            index_reg & {INDEX_LOG{is_wait_lookup & offset_reg_sel[1] | is_refill | is_replace}},
            index_reg & {INDEX_LOG{is_wait_lookup & offset_reg_sel[0] | is_refill | is_replace}}
        } ;
    assign bank_dina            =
        {32{is_hit_write}} & wbuffer_wdata_reg |
        {32{is_refill}} & refill_dina;

    assign dirty_ena            = 
        {WAY{is_hit_write}} & wbuffer_hit_sel_reg |
        {WAY{is_refill | is_replace}} & {lfsr_sel_reg, ~lfsr_sel_reg};
    assign dirty_wea            =
        is_hit_write | is_refill & |wen_reg;
    assign dirty_addra          =
        {INDEX_LOG{is_hit_write}} & wbuffer_index_reg |
        {INDEX_LOG{is_replace | is_refill}} & index_reg;
    assign dirty_dina           =
        is_hit_write | is_refill & |wen_reg;


    assign wbuffer_en_i         = (master_state == LOOKUP_STATE) & ~miss & |wen_reg & ~uncached_reg;
    assign wbuffer_hit_sel_i    = hit_sel;
    assign wbuffer_wen_i        = wen_reg;
    assign wbuffer_index_i      = index_reg;
    assign wbuffer_offset_i     = offset_reg;
    assign wbuffer_wdata_i      = wdata_reg;

    reg [31:0] miss_refill_data;

    always @(posedge clk) begin
        if (rst) begin
            miss_refill_data <= 32'h0;
        end else if (is_uncached_refill | is_refill & (write_line_counter == offset_reg)) begin
            miss_refill_data <= axi_rdata;
        end
    end

    assign cpu_rdata            = 
        ~miss ? 
            bank_douta[1][offset_reg*32+:32] & {32{hit_sel[1]}} | bank_douta[0][offset_reg*32+:32] & {32{hit_sel[0]}} : 
            miss_refill_data;

    wire [3 :0] _size;

    assign _size = 
        {3{ load_type_reg == `LS_SEL_LB     |
            load_type_reg == `LS_SEL_LBU    |
            load_type_reg == `LS_SEL_SB     
        }} & 3'h0   |
        {3{ load_type_reg == `LS_SEL_LH     |
            load_type_reg == `LS_SEL_LHU    |
            load_type_reg == `LS_SEL_SH     
        }} & 3'h1   |
        {3{ load_type_reg == `LS_SEL_LW     |
            load_type_reg == `LS_SEL_LWL    |
            load_type_reg == `LS_SEL_LWR    |
            load_type_reg == `LS_SEL_SW     |
            load_type_reg == `LS_SEL_SWL    |
            load_type_reg == `LS_SEL_SWR    
        }} & 3'h2;

    reg replace_flag;
    always @(*) begin
        replace_flag        = 1'b0;
        lfsr_stall          = 1'b0;
        cpu_d_cache_stall   = 1'b0;
        master_next_state   = IDLE_STATE;

        axi_buffer_en       = 1'b0;
        axi_buffer_addr     = 32'h0;
        axi_buffer_uncached = 1'b0;
        axi_buffer_size     = 3'h0;
        axi_buffer_wstrb    = 4'h0;
        axi_buffer_cache_line= {LINE_SIZE*8{1'b0}};
        axi_buffer_data     = 32'h0;

        axi_araddr          = 32'h0;
        axi_arlen           = 8'h0;
        axi_arsize          = 3'h0;
        axi_arvalid         = 1'b0;

        axi_rready          = 1'b1;

        is_lookup           = 1'b0;
        is_wait_lookup      = 1'b0;
        is_replace          = 1'b0;
        is_refill           = 1'b0;
        is_uncached_refill  = 1'b0;

        case (master_state)
        IDLE_STATE: begin
            lfsr_stall      = 1'b0;
            if (~cpu_en) begin
                master_next_state = IDLE_STATE; 
            end else if (cpu_uncached) begin
                master_next_state = axi_buffer_free ? REPLACE_STATE : MISS_STATE;
            end else if (hit_write_conflict) begin
                master_next_state = WAIT_STATE;
            end else begin
                master_next_state = LOOKUP_STATE;
                is_lookup         = ~cpu_uncached;
            end 
        end

        LOOKUP_STATE: begin
            lfsr_stall      = 1'b0;
            if (~miss & ~cpu_en) begin
                master_next_state = IDLE_STATE;
            end else if (~miss & cpu_uncached) begin
                master_next_state = axi_buffer_free ? REPLACE_STATE : MISS_STATE;
            end else if (~miss & cpu_en & hit_write_conflict) begin
                master_next_state = WAIT_STATE;
            end else if (~miss & cpu_en) begin
                master_next_state = LOOKUP_STATE;
                is_lookup         = ~cpu_uncached;
            end else begin
                master_next_state = MISS_STATE;
                cpu_d_cache_stall = 1'b1;
            end
        end

        WAIT_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            if (hit_write_conflict_wait) begin
                master_next_state   = WAIT_STATE;
            end else begin
                master_next_state   = LOOKUP_STATE;
                is_wait_lookup      = 1'b1;
            end
        end

        MISS_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            lfsr_stall              = 1'b1;
            if (~axi_buffer_free) begin
                master_next_state   = MISS_STATE;
            end else begin
                master_next_state   = REPLACE_STATE;
                lfsr_stall          = 1'b1;
                is_replace          = 1'b1;
                
                // axi_araddr          = ~uncached_reg ? {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}} : {psyaddr_reg[31:2], 2'b00};
                // axi_arlen           = ~uncached_reg ? LINE_SIZE / 4 - 1 : 0;
                // axi_arsize          = ~uncached_reg ? 3'b010 : _size;
                // axi_arvalid         = ~uncached_reg | uncached_reg & (wen_reg == 4'h0);
            end
        end

        REPLACE_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            lfsr_stall              = 1'b1;
            axi_araddr          = ~uncached_reg ? {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}} : {psyaddr_reg[31:2], 2'b00};
            axi_arlen           = ~uncached_reg ? LINE_SIZE / 4 - 1 : 0;
            axi_arsize          = ~uncached_reg ? 3'b010 : _size;
            axi_arvalid         = ~uncached_reg ? 1'b1 : ~(|wen_reg);
            if (~replace_flag) begin
                replace_flag = 1'b1;
                axi_buffer_en       = tagv_douta[lfsr_sel_reg][0] & dirty_douta[lfsr_sel_reg] & ~uncached_reg | uncached_reg & |wen_reg;
                axi_buffer_uncached = uncached_reg;
                axi_buffer_size     = _size;
                axi_buffer_wstrb    = wen_reg;
                axi_buffer_addr     = uncached_reg ? psyaddr_reg : {tagv_douta[lfsr_sel_reg][20:1], index_reg, {(2 + OFFSET_LOG){1'b0}}};
                axi_buffer_data     = wdata_reg;
                axi_buffer_cache_line   = {
                    bank_douta[lfsr_sel_reg][96+:32],
                    bank_douta[lfsr_sel_reg][64+:32],
                    bank_douta[lfsr_sel_reg][32+:32],
                    bank_douta[lfsr_sel_reg][0 +:32]
                };
            end

            if (axi_arready | uncached_reg & (|wen_reg)) begin
                master_next_state   = REFILL_STATE;
            end else begin
                master_next_state   = REPLACE_STATE;
            end
        end

        REFILL_STATE: begin
            axi_rready              = 1'b1;
            lfsr_stall              = 1'b1;
            cpu_d_cache_stall       = 1'b1;
            if (axi_rvalid & ~uncached_reg)
                is_refill       = 1'b1;
            else if (axi_rvalid & uncached_reg)
                is_uncached_refill = 1'b1;
            if (axi_rvalid & axi_rlast | uncached_reg & |wen_reg) begin
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
        is_hit_write    = wbuffer_en_reg;
    end

    reg [31:0] total_counter;
    reg [31:0] miss_counter;

    always @(posedge clk) begin
        if (rst) begin
            total_counter   <= 32'h0;
            miss_counter    <= 32'h0;
        end else begin
            if (is_lookup) begin
                total_counter <= total_counter + 32'h1;
            end

            if (master_state == LOOKUP_STATE & miss & ~uncached_reg) begin
                miss_counter <= miss_counter + 32'h1;
            end
        end
    end

endmodule