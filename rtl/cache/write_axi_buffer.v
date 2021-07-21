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

    reg                        uncached_reg;
    reg [31                :0] addr_reg;
    reg [3                 :0] size_reg;
    reg [3                 :0] wstrb_reg;
    reg [31                :0] data_reg;
    reg [LINE_SIZE * 8-1   :0] cache_line_reg;

    localparam IDLE         = 0;
    localparam WAIT_ADDR    = 1;
    localparam WAIT_DATA    = 2;

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
            counter     <= next_counter;
        end
    end

    assign empty    = cur_state == IDLE;

    always @(*) begin
        axi_awaddr  = 32'h0;
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
        case (cur_state)
        IDLE: begin
            if (en) begin
                next_state  = WAIT_ADDR;
                axi_awaddr  = addr;
                axi_awlen   = uncached ? 8'h0 : LINE_SIZE / 4 - 1;
                axi_awsize  = size;
                axi_awvalid = 1'b1;
            end else begin
                next_state = IDLE; 
            end
        end

        WAIT_ADDR: begin
            axi_awvalid = 1'b1;
            axi_awaddr  = addr_reg;
            axi_awlen   = uncached_reg ? 8'h0 : LINE_SIZE / 4 - 1;
            axi_awsize  = size_reg;
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
            axi_wlast   = ~finished & (uncached_reg | ~uncached_reg & (counter == (LINE_SIZE/4 - 1)));
            axi_wvalid  = ~finished;
            if (axi_wready & ~finished) begin
                next_counter    = counter + 4'h1;
                next_finished   = counter == LINE_SIZE/4 | uncached_reg;
            end else begin
                next_counter    = counter;
                next_finished   = finished;
            end
            if (finished & axi_bready & axi_bvalid)
                next_state = IDLE;
            else
                next_state = WAIT_DATA;
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