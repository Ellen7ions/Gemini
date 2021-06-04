`timescale 1ns / 1ps

`include "id_def.v"

module idu_1 (
    input   wire [31:0]     inst,
    output  wire [5 :0]     id1_op_code,
    output  wire [4 :0]     id1_rs,
    output  wire [4 :0]     id1_rt,
    output  wire [4 :0]     id1_rd,
    output  wire [4 :0]     id1_sa,
    output  wire [5 :0]     id1_funct,
    output  wire            id1_w_reg_dst,
    output  wire [15:0]     id1_imme,
    output  wire [25:0]     id1_j_imme,
    output  wire            id1_is_branch,
    output  wire            id1_is_j_imme,
    output  wire            id1_is_jr,
    output  wire            id1_is_ls
);

    assign id1_op_code   = inst[31:26];
    assign id1_rs        = inst[25:21];
    assign id1_rt        = inst[20:16];
    assign id1_rd        = inst[15:11];
    assign id1_sa        = inst[10: 6];
    assign id1_funct     = inst[5 : 0];
    assign id1_imme      = inst[15: 0];
    assign id1_j_imme    = inst[25: 0];

    assign id1_w_reg_dst     = 1'b1;
    assign id1_imme          = 16'h0;
    assign id1_is_branch     = 1'b0;
    assign id1_is_j_imme     = 1'b0;
    assign id1_is_jr         = 1'b0;
    assign id1_is_ls         = 1'b0;
    
endmodule