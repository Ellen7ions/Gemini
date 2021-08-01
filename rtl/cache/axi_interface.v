`timescale 1ns / 1ps

`include "../idu/id_def.v"

module axi_interface (
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

    output  reg  [31:0] axi_awaddr,
    output  reg  [7 :0] axi_awlen,
    output  reg  [1 :0] axi_awburst,
    output  reg  [2 :0] axi_awsize,
    output  reg         axi_awvalid,
    input   wire        axi_awready,
    output  reg  [31:0] axi_wdata,
    output  reg  [3 :0] axi_wstrb,
    output  reg         axi_wlast,
    output  reg         axi_wvalid,
    input   wire        axi_wready,
    output  reg  [31:0] axi_araddr,
    output  reg  [7 :0] axi_arlen,
    output  reg  [1 :0] axi_arburst,
    output  reg  [2 :0] axi_arsize,
    output  reg         axi_arvalid,
    input   wire        axi_arready,
    input   wire [31:0] axi_rdata,
    input   wire        axi_rlast,
    input   wire        axi_rvalid,
    output  reg         axi_rready,
    input   wire        axi_bvalid,
    output  reg         axi_bready
);

    localparam IDLE    = 0;
    localparam RADDR   = 1;
    localparam RDATA   = 2;
    localparam WADDR   = 3;
    localparam WDATA   = 4;
    localparam WRESP   = 5;

    reg [2:0] cur_state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        if (rst) begin
            cur_state   <= IDLE;
        end else begin
            cur_state   <= next_state;
        end
    end

    wire        en_reg;
    wire [3 :0] wen_reg;
    wire        uncached_reg;
    wire [3 :0] load_type_reg;
    wire [31:0] vaddr_reg;
    wire [31:0] psyaddr_reg;
    wire [31:0] wdata_reg;
    wire [2 :0] _size;
    wire [2 :0] _size_reg;

    assign _size = 
        {3{ cpu_load_type == `LS_SEL_LB     |
            cpu_load_type == `LS_SEL_LBU    |
            cpu_load_type == `LS_SEL_SB     
        }} & 3'h0   |
        {3{ cpu_load_type == `LS_SEL_LH     |
            cpu_load_type == `LS_SEL_LHU    |
            cpu_load_type == `LS_SEL_SH     
        }} & 3'h1   |
        {3{ cpu_load_type == `LS_SEL_LW     |
            cpu_load_type == `LS_SEL_LWL    |
            cpu_load_type == `LS_SEL_LWR    |
            cpu_load_type == `LS_SEL_SW     |
            cpu_load_type == `LS_SEL_SWL    |
            cpu_load_type == `LS_SEL_SWR    
        }} & 3'h2;

    request_buffer request_buffer0 (
        .clk        (clk                ),
        .rst        (rst                ),
        .stall      (cpu_d_cache_stall  |
                    ~cpu_en),
        
        .en_i       (cpu_en             ),
        .wen_i      (cpu_wen            ),
        ._size_i    (_size              ),
        .uncached_i (cpu_uncached       ),
        .load_type_i(cpu_load_type      ),
        .vaddr_i    (cpu_vaddr          ),
        .psyaddr_i  (cpu_psyaddr        ),
        .wdata_i    (cpu_wdata          ),

        .en_o       (en_reg             ),
        .wen_o      (wen_reg            ),
        ._size_o    (_size_reg          ),
        .uncached_o (uncached_reg       ),
        .load_type_o(load_type_reg      ),
        .vaddr_o    (vaddr_reg          ),
        .psyaddr_o  (psyaddr_reg        ),
        .wdata_o    (wdata_reg          )
    );

    reg [31:0] result;
    always @(posedge clk) begin
        if (rst) begin
            result = 32'h0; 
        end else if (cur_state == RDATA && axi_rvalid) begin
            result = axi_rdata;
        end
    end

    assign cpu_rdata = result;

    always @(*) begin
        next_state  = IDLE;
        axi_awaddr  = 32'h0;
        axi_awlen   = 8'h0;
        axi_awburst = 2'h0;
        axi_awsize  = 3'h0;
        axi_awvalid = 1'h0;

        axi_wdata = 32'h0;
        axi_wstrb = 4'h0;
        axi_wlast = 1'b0;
        axi_wvalid = 1'b0;
        
        axi_araddr = 32'h0;
        axi_arlen = 8'h0;
        axi_arburst = 2'h0;
        axi_arsize = 3'h0;
        axi_arvalid = 1'b0;
        axi_rready = 1'b1;
        axi_bready = 1'b1;

        cpu_d_cache_stall = 1'b0;

        case (cur_state)
        IDLE: begin
            if (cpu_en) begin
                if (|cpu_wen) begin
                    axi_awaddr  = cpu_psyaddr;
                    axi_awsize  = _size;
                    axi_awvalid = 1'b1;
                    if (axi_awready) begin
                        next_state = WDATA;
                    end else begin
                        next_state = WADDR;
                    end
                end else begin
                    axi_araddr = cpu_psyaddr;
                    axi_arsize = _size;
                    axi_arvalid = 1'b1;
                    if (axi_arready) begin
                        next_state = RDATA;
                    end else begin
                        next_state = RADDR;
                    end
                end
            end else begin
                next_state = IDLE;
            end
        end

        RADDR: begin
            cpu_d_cache_stall = 1'b1;
            axi_araddr = psyaddr_reg;
            axi_arsize = _size_reg;
            axi_arvalid = 1'b1;
            if (axi_arready) begin
                next_state = RDATA;
            end else begin
                next_state = RADDR;
            end
        end

        RDATA: begin
            cpu_d_cache_stall = 1'b1;
            if (axi_rvalid) begin
                next_state = IDLE;
            end else begin
                next_state = RDATA;
            end
        end

        WADDR: begin
            cpu_d_cache_stall = 1'b1;
            axi_awaddr  = psyaddr_reg;
            axi_awsize  = _size_reg;
            axi_awvalid = 1'b1;
            if (axi_awready) begin
                next_state = WDATA;
            end else begin
                next_state = WADDR;
            end
        end

        WDATA: begin
            cpu_d_cache_stall = 1'b1;
            axi_wdata = wdata_reg;
            axi_wlast = 1'b1;
            axi_wvalid = 1'b1;
            axi_wstrb = wen_reg;
            if (axi_wready) begin
                next_state = WRESP;
            end else begin
                next_state = WDATA;
            end
        end

        WRESP: begin
            cpu_d_cache_stall = 1'b1;
            if (axi_bvalid) begin
                next_state = IDLE;
            end else begin
                next_state = WRESP;
            end
        end

        default: begin
            
        end
        endcase
    end

endmodule