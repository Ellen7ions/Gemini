`timescale 1ns / 1ps

module request_buffer (
    input   wire        clk,
    input   wire        rst,
    input   wire        en_i,
    input   wire [3 :0] wen_i,
    input   wire        uncached_i,
    input   wire [3 :0] load_type_i,
    input   wire [31:0] vaddr_i,
    input   wire [31:0] psyaddr_i,
    input   wire [31:0] wdata_i,
    output  reg         en_o,
    output  reg  [3 :0] wen_o,
    output  reg         uncached_o,
    output  reg  [3 :0] load_type_o,
    output  reg  [31:0] vaddr_o,
    output  reg  [31:0] psyaddr_o,
    output  reg  [31:0] wdata_o
);

    always @(posedge clk) begin
        if (rst) begin
            en_o        <= 1'b0;
            wen_o       <= 4'h0;
            load_type_o <= 4'h0;
            vaddr_o     <= 32'h0;
            psyaddr_o   <= 32'h0;
            wdata_o     <= 32'h0;
            uncached_o  <= 1'b0;
        end else begin
            en_o        <= en_i;
            wen_o       <= wen_i;
            uncached_o  <= uncached_i;
            load_type_o <= load_type_i;
            vaddr_o     <= vaddr_i;
            psyaddr_o   <= psyaddr_i;
            wdata_o     <= wdata_i;
        end
    end

endmodule