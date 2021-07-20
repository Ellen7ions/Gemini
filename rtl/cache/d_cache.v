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
    wire [3          :0]        bank_wea    ;
    wire [INDEX_LOG-1:0]        bank_addra  ;
    wire [31         :0]        bank_dina   ;
    wire [31         :0]        bank_douta  [WAY-1:0];

    wire [WAY*WORD_NUM-1:0]     refill_en   ;
    wire [3          :0]        refill_wea  ;
    wire [INDEX_LOG-1:0]        refill_addra;
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
                .wea    (bank_wea                   ),
                .addra  (bank_addra                 ),
                .dina   (bank_dina                  ),
                .douta  (bank_douta [i*WORD_NUM+j]  )
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
        wbuffer_en_reg & (wbuffer_offset_reg == cpu_offset) | wbuffer_en_i & (wbuffer_offset_i == cpu_offset);
    
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
    assign refill_dina              =
        (offset_reg == write_line_counter) && (|wen_reg) ? 
            refill_store_data : axi_rdata;

    reg is_lookup;
    reg is_hit_write;
    reg is_replace;
    reg is_refill;

    always @(posedge clk) begin
        if (rst) begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end else if (master_state == REFILL_STATE && axi_rvalid) begin
            write_line_counter <= write_line_counter + {OFFSET_LOG{1'b1}};
        end else begin
            write_line_counter <= {OFFSET_LOG{1'b0}};
        end
    end


    wire [WORD_NUM-1:0] cpu_offset_sel;
    wire [WORD_NUM-1:0] offset_reg_sel;
    decoder decoder0 (
        .in     (cpu_offset     ),
        .out    (cpu_offset_sel )
    );
    decoder decoder1 (
        .in     (offset_reg     ),
        .out    (offset_reg_sel )
    );

    assign tagv_ena             = 
        {WAY{is_lookup}} |
        {lfsr_sel_reg, ~lfsr_sel_reg} & {WAY{is_replace | is_refill}};
    assign tagv_wea             = 
        is_refill;
    assign tagv_addra           = 
        {INDEX_LOG{is_lookup}} & cpu_index |
        {INDEX_LOG{is_replace | is_refill}} & index_reg;
    assign tagv_dina            =
        {tag_reg, 1'b1};

    assign bank_ena             = 
        {cpu_offset_sel, cpu_offset_sel} & {WAY*WORD_NUM{is_lookup}} |
        {wbuffer_offset_reg & {WORD_NUM{wbuffer_hit_sel_reg[1]}},
         wbuffer_offset_reg & {WORD_NUM{wbuffer_hit_sel_reg[0]}}} & {WAY*WORD_NUM{is_hit_write}} |
        {{WORD_NUM{lfsr_sel_reg}}, {WORD_NUM{~lfsr_sel_reg}}} & {WAY*WORD_NUM{is_replace}}  |
        {{4{lfsr_sel_reg}} & refill_offset_sel, {4{~lfsr_sel_reg}} & refill_offset_sel} & {WAY*WORD_NUM{is_refill}};
    assign bank_wea             = 
        {4{is_hit_write}} & wbuffer_wen_reg | 
        {4{is_refill}} & 4'b1111;
    assign bank_addra           = 
        {INDEX_LOG{is_lookup}} & cpu_index |
        {INDEX_LOG{is_hit_write}} & wbuffer_index_reg |
        {INDEX_LOG{is_replace | is_refill}} & index_reg;
    assign bank_dina            =
        {32{is_hit_write}} & wbuffer_wdata_reg |
        {32{is_refill}} & refill_dina;

    assign dirty_ena            = 
        {WAY{is_hit_write}} & wbuffer_hit_sel_reg |
        {WAY{is_refill | is_replace}} & {lfsr_sel_reg, ~lfsr_sel_reg};
    assign dirty_wea            =
        is_hit_write | is_refill;
    assign dirty_addra          =
        {INDEX_LOG{is_hit_write}} & wbuffer_index_reg |
        {INDEX_LOG{is_replace | is_refill}} & index_reg;
    assign dirty_dina           =
        is_hit_write | is_refill & |wen_reg;


    assign wbuffer_en_i         = ~miss & |wen_reg;
    assign wbuffer_hit_sel_i    = hit_sel;
    assign wbuffer_wen_i        = wen_reg;
    assign wbuffer_index_i      = index_reg;
    assign wbuffer_offset_i     = offset_reg;
    assign wbuffer_wdata_i      = wdata_reg;

    reg replace_flag;
    always @(*) begin
        replace_flag        = 1'b0;
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

        is_lookup           = 1'b0;
        is_replace          = 1'b0;
        is_refill           = 1'b0;

        case (master_state)
        IDLE_STATE: begin
            lfsr_stall      = 1'b0;
            if (~cpu_en | cpu_en & hit_write_conflict) begin
                master_next_state = IDLE_STATE;
                cpu_d_cache_stall = 1'b1; 
            end else begin
                master_next_state = LOOKUP_STATE;
                is_lookup         = 1'b1;
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
                is_lookup         = 1'b1;
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
                is_replace          = 1'b1;
                
                axi_araddr          = {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}};
                axi_arlen           = LINE_SIZE / 4 - 1;
                axi_arsize          = 3'b010;
                axi_arvalid         = 1'b1;
            end
        end

        REPLACE_STATE: begin
            cpu_d_cache_stall       = 1'b1;
            lfsr_stall              = 1'b1;
            if (~replace_flag) begin
                replace_flag = 1'b1;
                axi_buffer_en       = dirty_douta[lfsr_sel_reg];
                axi_buffer_addr     = {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}};
                axi_buffer_data     = {
                    bank_douta[lfsr_sel_reg*WAY+3],
                    bank_douta[lfsr_sel_reg*WAY+2],
                    bank_douta[lfsr_sel_reg*WAY+1],
                    bank_douta[lfsr_sel_reg*WAY+0]
                };
            end

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
            if (axi_rvalid)
                is_refill       = 1'b1;
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
            is_hit_write = 1'b1;
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