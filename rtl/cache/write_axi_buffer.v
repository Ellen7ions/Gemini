`timescale 1ns / 1ps

module write_axi_buffer #(
    parameter LINE_SIZE = 16
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire                        en,
    input   wire                        addr,
    input   wire [LINE_SIZE * 8-1   :0] data,
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

    reg [LINE_SIZE*8-1:0] data_reg;

    localparam IDLE         = 0;
    localparam WAIT_ADDR    = 1;
    localparam WAIT_DATA    = 2;

    reg [1:0] cur_state;
    reg [1:0] next_state;

    reg [3:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            cur_state <= IDLE;
        end else begin
            cur_state <= next_state;
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
        case (cur_state)
        IDLE: begin
            if (en) begin
                next_state  = WAIT_ADDR;
                axi_awaddr  = addr;
                axi_awlen   = LINE_SIZE / 4 - 1;
                axi_awsize  = 3'b010;
                axi_awvalid = 1'b1;
            end else begin
                next_state = IDLE; 
            end
        end

        WAIT_ADDR: begin
            if (axi_wready) begin
                next_state  = WAIT_DATA;
                counter     = 4'd0;
                axi_wdata   = data_reg[counter * 32 +: 32];
                axi_wstrb   = 4'b1111;
                axi_wlast   = 1'b0;
                axi_wvalid  = 1'b1;
            end else begin
                next_state  = WAIT_ADDR;
                axi_awaddr  = addr;
                axi_awlen   = LINE_SIZE / 4 - 1;
                axi_awsize  = 3'b010;
                axi_awvalid = 1'b1;
            end
        end

        WAIT_DATA: begin
            counter     = counter + 4'h1;
            axi_wdata   = data_reg[counter * 32 +: 32];
            axi_wstrb   = 4'b1111;
            axi_wlast   = counter == (LINE_SIZE/4 - 1);
            axi_wvalid  = 1'b1;
            if (counter == (LINE_SIZE/4 - 1))
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
            data_reg <= {LINE_SIZE*8-1{1'b0}};
        end else if (en & (cur_state == IDLE)) begin
            data_reg <= data;
        end
    end

endmodule