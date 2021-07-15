`timescale 1ns / 1ps

`include "../idu/id_def.v"

module lsu2p (
    input   wire [31:0] ex_mem_pc,
    input   wire [31:0] ex_mem_alu_res,
    input   wire        ex_mem_w_reg_ena,
    input   wire [4 :0] ex_mem_w_reg_dst,
    input   wire        ex_mem_wb_reg_sel,
    
    output  wire [31:0] mem_pc,
    output  wire [31:0] mem_alu_res,
    output  wire        mem_w_reg_ena,
    output  wire [4 :0] mem_w_reg_dst,
    output  wire        mem_wb_reg_sel
);
    
    assign mem_pc           = ex_mem_pc;
    assign mem_w_reg_ena    = ex_mem_w_reg_ena;
    assign mem_wb_reg_sel   = ex_mem_wb_reg_sel;
    assign mem_alu_res      = ex_mem_alu_res;
    assign mem_w_reg_dst    = ex_mem_w_reg_dst;

endmodule