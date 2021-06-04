`timescale 1ns / 1ps

module alu (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] src_a,
    input   wire [31:0] src_b,
    input   wire [5 :0] alu_sel,
    output  wire [31:0] alu_res
);
endmodule