`timescale 1ns / 1ps

module write_buffer #(
    parameter OFFSET_LOG= 2,
    parameter INDEX_LOG = 8
) (
    input   wire                    clk,
    input   wire                    rst,
    input   wire                    stall,

    input   wire                    en_i,
    input   wire [1             :0] hit_sel_i,
    input   wire [3             :0] wen_i,
    input   wire [INDEX_LOG -1  :0] index_i,
    input   wire [OFFSET_LOG-1  :0] offset_i,
    input   wire [31            :0] wdata_i,

    output  reg                     en_o,
    output  reg  [1             :0] hit_sel_o,
    output  reg  [3             :0] wen_o,
    output  reg  [INDEX_LOG -1  :0] index_o,
    output  reg  [OFFSET_LOG-1  :0] offset_o,
    output  reg  [31            :0] wdata_o
);

    always @(posedge clk) begin
        if (rst) begin
            en_o        <= 1'b0;
            hit_sel_o   <= 2'b00;
            wen_o       <= 4'h0;
            index_o     <= {INDEX_LOG{1'b0}};
            offset_o    <= {OFFSET_LOG{1'b0}};
            wdata_o     <= 32'h0;
        end else if (~stall) begin
            en_o        <= en_i;
            hit_sel_o   <= hit_sel_i;
            wen_o       <= wen_i;
            index_o     <= index_i;
            offset_o    <= offset_i;
            wdata_o     <= wdata_i;
        end
    end

endmodule