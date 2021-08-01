`timescale 1ns / 1ps

module write_axi_buffer #(
    parameter LINE_SIZE = 16
) (
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        en,
    input   wire                        uncached,
    input   wire [31                :0] addr,
    input   wire [2                 :0] size,
    input   wire [3                 :0] wstrb,
    input   wire [31                :0] data,
    input   wire [LINE_SIZE * 8-1   :0] cache_line,
    output  wire                        empty,

    output  reg  [31                :0] axi_awaddr,
    output  reg  [7                 :0] axi_awlen,
    output  reg  [1                 :0] axi_awburst,
    output  reg  [2                 :0] axi_awsize,
    output  reg                         axi_awvalid,
    input   wire                        axi_awready,
    output  reg  [31                :0] axi_wdata,
    output  reg  [3                 :0] axi_wstrb,
    output  reg                         axi_wlast,
    output  reg                         axi_wvalid,
    input   wire                        axi_wready,
    input   wire                        axi_bvalid,
    output  reg                         axi_bready
);

    (*mark_debug = "true"*) reg                        uncached_reg;
    (*mark_debug = "true"*) reg [31                :0] addr_reg;
    (*mark_debug = "true"*) reg [3                 :0] size_reg;
    (*mark_debug = "true"*) reg [3                 :0] wstrb_reg;
    (*mark_debug = "true"*) reg [31                :0] data_reg;
    (*mark_debug = "true"*) reg [LINE_SIZE * 8-1   :0] cache_line_reg;

    localparam IDLE         = 0;
    localparam WAIT_ADDR    = 1;
    localparam WAIT_DATA    = 2;
    localparam WAIT_RESP    = 3;

    reg [1:0] cur_state;
    reg [1:0] next_state;

    reg [3:0] counter;
    reg [3:0] next_counter;
    reg       finished;
    reg       next_finished;

    always @(posedge clk) begin
        if (rst) begin
            cur_state   <= IDLE;
            finished    <= 1'b1;
            counter     <= 4'h0;
        end else begin
            cur_state   <= next_state;
            finished    <= next_finished;
            if (!next_finished) begin
                counter <= next_counter;
            end
        end
    end

    assign empty    = cur_state == IDLE;

    always @(*) begin
        axi_awaddr  = 32'h0;
        axi_awburst = 2'b00;
        axi_awlen   = 8'h0;
        axi_awsize  = 3'h0;
        axi_awvalid = 1'b0;
        axi_wdata   = 32'h0;
        axi_wstrb   = 4'h0;
        axi_wlast   = 1'b0;
        axi_wvalid  = 1'b0;
        axi_bready  = 1'b1;
        next_finished   = 1'b1;
        next_counter    = 4'h0;
        next_state      = IDLE;
        case (cur_state)
        IDLE: begin
            if (en) begin
                axi_awaddr  = addr;
                axi_awlen   = uncached ? 8'h0 : LINE_SIZE / 4 - 1;
                axi_awburst = uncached ? 2'h0 : 2'b01;
                axi_awsize  = uncached ? size : 3'b010;
                axi_awvalid = 1'b1;
                if (axi_awready) begin
                    next_state  = WAIT_DATA;
                    next_counter= 4'd0;
                    next_finished   = 1'b0;
                end else begin
                    next_state  = WAIT_ADDR;
                end
            end else begin
                next_state = IDLE; 
            end
        end

        WAIT_ADDR: begin
            axi_awaddr  = addr_reg;
            axi_awlen   = uncached_reg ? 8'h0       : LINE_SIZE / 4 - 1;
            axi_awburst = uncached_reg ? 2'h0       : 2'b01;
            axi_awsize  = uncached_reg ? size_reg   : 3'b010;
            axi_awvalid = 1'b1;
            if (axi_awready) begin
                next_state  = WAIT_DATA;
                next_counter= 4'd0;
                next_finished   = 1'b0;
            end else begin
                next_state  = WAIT_ADDR;
            end
        end

        WAIT_DATA: begin
            axi_wdata   = uncached_reg ? data_reg  : cache_line_reg[counter * 32 +: 32];
            axi_wstrb   = uncached_reg ? wstrb_reg : 4'b1111;
            axi_wlast   = uncached_reg | ~uncached_reg & (counter == (LINE_SIZE/4 - 1));
            axi_wvalid  = 1'b1;

            if (~uncached_reg & (counter == (LINE_SIZE/4 - 1)) & axi_wready | uncached_reg & axi_wready) begin
                next_state = WAIT_RESP;
            end else begin
                next_state = WAIT_DATA;         
            end
            
            if (~uncached_reg & axi_wready) begin
                next_counter    = counter + 4'h1;
            end else begin
                next_counter    = counter;
            end
        end

        WAIT_RESP: begin
            if (axi_bvalid) begin
                next_state      = IDLE;
            end else begin
                next_state      = WAIT_RESP;
            end
        end

        default: begin
            
        end 
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            data_reg        <= 32'h0;
            cache_line_reg  <= {LINE_SIZE*8-1{1'b0}};
            uncached_reg    <= 1'b0;
            addr_reg        <= 32'h0;
            size_reg        <= 3'h0;
            wstrb_reg       <= 4'h0;
        end else if (en & (cur_state == IDLE)) begin
            data_reg        <= data;
            cache_line_reg  <= cache_line;
            uncached_reg    <= uncached;
            addr_reg        <= addr;
            size_reg        <= size;
            wstrb_reg       <= wstrb;
        end
    end

endmodule