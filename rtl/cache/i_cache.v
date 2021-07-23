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
    parameter WAY       = 2,
    parameter LINE_SIZE = 16,
    parameter LINE_NUM  = 256
)(
        input   wire        clk,
        input   wire        rst, 

        input   wire        cpu_en,
        input   wire        cpu_uncached,
        input   wire [31:0] cpu_vaddr,
        input   wire [31:0] cpu_psyaddr,    

        output  wire [31:0] cpu_rdata1,
        output  wire [31:0] cpu_rdata2,
        output  wire        cpu_ok_1,
        output  wire        cpu_ok_2,
        output  reg         cpu_i_cache_stall,

        output  reg  [31:0] axi_araddr,
        output  reg  [7 :0] axi_arlen,
        output  reg  [1 :0] axi_arburst,
        output  reg         axi_arvalid,
        input   wire        axi_arready,
        input   wire [31:0] axi_rdata,
        input   wire        axi_rlast,
        input   wire        axi_rvalid,
        output  reg         axi_rready
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

    always @(posedge clk) begin
        if (rst) begin
            master_state <= IDLE_STATE; 
        end else begin
            master_state <= master_next_state;
        end
    end

    // instances

    wire [WAY      -1:0]        tagv_ena    ;
    wire                        tagv_wea    ;
    wire [INDEX_LOG-1:0]        tagv_addra  ;
    wire [20         :0]        tagv_dina   ;
    wire [20         :0]        tagv_douta  [WAY-1:0];

    wire [WAY*WORD_NUM-1:0]     bank_ena    ;
    wire [3          :0]        bank_wea    ;
    wire [INDEX_LOG-1:0]        bank_addra  ;
    wire [31         :0]        bank_dina   ;
    wire [32*WORD_NUM-1 :0]     bank_douta  [WAY-1:0];

    wire [31         :0]        refill_dina ;

    genvar i, j;
    generate
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
                .douta  (bank_douta [i][j*32+:32]   )
                );             
            end
        end
    endgenerate

    wire        en_reg;
    wire        uncached_reg;
    wire [31:0] vaddr_reg;
    wire [31:0] psyaddr_reg;

    request_buffer request_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        .stall      (cpu_i_cache_stall  | 
                    ~cpu_en),
        
        .en_i       (cpu_en             ),
        .wen_i      (),
        .uncached_i (cpu_uncached       ),
        .load_type_i(),
        .vaddr_i    (cpu_vaddr          ),
        .psyaddr_i  (cpu_psyaddr        ),
        .wdata_i    (),

        .en_o       (en_reg             ),
        .wen_o      (),
        .uncached_o (uncached_reg       ),
        .load_type_o(),
        .vaddr_o    (vaddr_reg          ),
        .psyaddr_o  (psyaddr_reg        ),
        .wdata_o    ()
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

    wire [WAY       -1:0] hit_sel       = {
        (tag_reg == tagv_douta[1][TAG_INDEX:1]) & tagv_douta[1][0],
        (tag_reg == tagv_douta[0][TAG_INDEX:1]) & tagv_douta[0][0]
    };
    wire miss                           = (hit_sel == 2'b00) | uncached_reg;

    reg  [OFFSET_LOG-1:0] write_line_counter;
    wire [WORD_NUM  -1:0] refill_offset_sel;
    // REFILL
    decoder decoder2_4 (
        .in     (write_line_counter ),
        .out    (refill_offset_sel  )
    );
    assign refill_dina              = axi_rdata;

    reg is_lookup;
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
        {lfsr_sel_reg, ~lfsr_sel_reg} & {WAY{is_refill}};
    assign tagv_wea             = 
        is_refill;
    assign tagv_addra           = 
        {INDEX_LOG{is_lookup}} & cpu_index |
        {INDEX_LOG{is_refill}} & index_reg;
    assign tagv_dina            =
        {tag_reg, 1'b1};

    assign bank_ena             = 
        {WAY*WORD_NUM{is_lookup}} |
        {{4{lfsr_sel_reg}} & refill_offset_sel, {4{~lfsr_sel_reg}} & refill_offset_sel} & {WAY*WORD_NUM{is_refill}};
    assign bank_wea             = 
        {4{is_refill}} & 4'b1111;
    assign bank_addra           = 
        {INDEX_LOG{is_lookup}} & cpu_index |
        {INDEX_LOG{is_refill}} & index_reg;
    assign bank_dina            =
        {32{is_refill}} & refill_dina;


    reg [31:0]  miss_refill_data1;
    reg [31:0]  miss_refill_data2;
    reg         miss_ok_1;
    reg         miss_ok_2;

    assign      cpu_ok_1 = miss ? miss_ok_1 : 1'b1;
    assign      cpu_ok_2 = miss ? miss_ok_2 : ~offset_reg[0];

    // assign cpu_ok_1 = 1'b1;
    // assign cpu_ok_2 = 1'b1;

    reg         miss_uncached_counter;

    always @(posedge clk) begin
        if (rst) begin
            miss_refill_data1   <= 32'h0;
            miss_refill_data2   <= 32'h0;
            miss_ok_1           <= 1'b0;
            miss_ok_2           <= 1'b0;
        end else if(is_uncached_refill) begin
            if (is_uncached_refill & (write_line_counter == 0)) begin
                miss_refill_data1   <= axi_rdata;
                miss_ok_1           <= 1'b1;
            end
            if (is_uncached_refill & (write_line_counter == 1)) begin
                miss_refill_data2   <= axi_rdata;
                miss_ok_2           <= ~offset_reg[0];
            end
        end else if (master_state == LOOKUP_STATE) begin
            miss_ok_1 <= 1'b0;
            miss_ok_2 <= 1'b0;
        end
    end
    
    assign {cpu_rdata2, cpu_rdata1} = 
        ~uncached_reg ? 
            ~offset_reg[0] ? 
                bank_douta[1][offset_reg*32+:64] & {64{hit_sel[1]}} | bank_douta[0][offset_reg*32+:64] & {64{hit_sel[0]}} :
                {{32'h0}, bank_douta[1][offset_reg*32+:32] & {32{hit_sel[1]}} | bank_douta[0][offset_reg*32+:32] & {32{hit_sel[0]}}}
            : {miss_refill_data2, miss_refill_data1};

    always @(*) begin
        lfsr_stall          = 1'b0;
        master_next_state   = IDLE_STATE;
        cpu_i_cache_stall   = 1'b0;

        is_lookup           = 1'b0;
        is_replace          = 1'b0;
        is_refill           = 1'b0;
        is_uncached_refill  = 1'b0;

        axi_araddr          = 32'h0;
        axi_arburst         = 2'b00;
        axi_arlen           = 8'h0;
        axi_arvalid         = 1'b0;
        axi_rready          = 1'b1;

        miss_uncached_counter = 1'b0;
        case (master_state)
        IDLE_STATE: begin
            lfsr_stall      = 1'b0;
            if (~cpu_en) begin
                master_next_state = IDLE_STATE;
                cpu_i_cache_stall = 1'b0; 
            end else begin
                master_next_state = LOOKUP_STATE;
                is_lookup         = ~cpu_uncached;
                cpu_i_cache_stall = 1'b0; 
            end 
        end

        LOOKUP_STATE: begin
            lfsr_stall      = 1'b0;
            if (~miss & ~cpu_en) begin
                master_next_state = IDLE_STATE;
                cpu_i_cache_stall = 1'b0;
            end else if (~miss & cpu_en) begin
                master_next_state = LOOKUP_STATE;
                is_lookup         = ~cpu_uncached;
                cpu_i_cache_stall = 1'b0;
            end else begin
                master_next_state = MISS_STATE;
                cpu_i_cache_stall = 1'b1;
            end
        end

        MISS_STATE: begin
            cpu_i_cache_stall       = 1'b1;
            lfsr_stall              = 1'b0;
            master_next_state   = REPLACE_STATE;
            lfsr_stall          = 1'b1;
            is_replace          = 1'b1;
        end

        REPLACE_STATE: begin
            cpu_i_cache_stall       = 1'b1;
            lfsr_stall              = 1'b1;
            
            axi_araddr          = ~uncached_reg ? {psyaddr_reg[31:2+OFFSET_LOG], {(2 + OFFSET_LOG){1'b0}}} : {psyaddr_reg[31:2], 2'b00};
            axi_arburst         = ~uncached_reg ? 2'b10 : 2'b01;
            axi_arlen           = ~uncached_reg ? LINE_SIZE / 4 - 1 : 1;
            axi_arvalid         = 1'b1;
            if (axi_arready) begin
                master_next_state   = REFILL_STATE;
            end else begin
                master_next_state   = REPLACE_STATE;
            end
        end

        REFILL_STATE: begin
            axi_rready              = 1'b1;
            lfsr_stall              = 1'b1;
            cpu_i_cache_stall       = 1'b1;
            if (axi_rvalid & ~uncached_reg)
                is_refill           = 1'b1;
            else if (axi_rvalid & uncached_reg) begin
                is_uncached_refill  = 1'b1;
            end
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