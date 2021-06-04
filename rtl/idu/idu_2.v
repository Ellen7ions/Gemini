`timescale 1ns / 1ps

module idu_2 (
    input  wire [5 :0]      id1_op_code,
    input  wire [4 :0]      id1_rs,
    input  wire [4 :0]      id1_rt,
    input  wire [4 :0]      id1_rd,
    input  wire [4 :0]      id1_sa,
    input  wire [5 :0]      id1_funct,
    input  wire             id1_w_reg_dst,
    input  wire [15:0]      id1_imme,
    input  wire [25:0]      id1_j_imme,
    input  wire             id1_is_branch,
    input  wire             id1_is_j_imme,
    input  wire             id1_is_jr,
    input  wire             id1_is_ls,

    input  wire [1 :0]      forward_rs,
    input  wire [1 :0]      forward_rt,

    output wire [4 :0]      id2_rs,
    output wire [4 :0]      id2_rt,
    output wire [4 :0]      id2_rd,
    output wire [4 :0]      id2_sa,
    output wire [5 :0]      id2_funct,
    output wire             id2_w_reg_dst,
    output wire [15:0]      id2_imme,
    output wire [25:0]      id2_j_imme,
    output wire             id2_is_branch,
    output wire             id2_is_j_imme,
    output wire             id2_is_jr,
    output wire             id2_is_ls,

    output wire [31:0]      id2_rs_data,
    output wire [31:0]      id2_rt_data,
    output wire [31:0]      id2_rd_data,
    output wire [31:0]      id2_ext_imme,
    
    output wire [2 :0]      id2_src_a_sel,
    output wire [2 :0]      id2_src_b_sel,
    output wire [5 :0]      id2_alu_sel,
    output wire [2 :0]      id2_alu_res_sel,
    output wire             id2_w_reg_ena,
    output wire [1 :0]      id2_w_hilo_ena,
    output wire [3 :0]      id2_ls_sel,
    output wire             id2_wb_sel
);

endmodule