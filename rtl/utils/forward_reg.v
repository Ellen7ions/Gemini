`timescale 1ns / 1ps

`include "forward_def.v"

module forward_reg (
    input   wire [4 :0] id_reg,
    input   wire        exc_w_reg_ena,
    input   wire [4 :0] exc_w_reg_dst,
    input   wire        exp_w_reg_ena,
    input   wire [4 :0] exp_w_reg_dst,
    input   wire        lsu1c_w_reg_ena,
    input   wire [4 :0] lsu1c_w_reg_dst,
    input   wire        lsu1p_w_reg_ena,
    input   wire [4 :0] lsu1p_w_reg_dst,
    input   wire        lsu2c_w_reg_ena,
    input   wire [4 :0] lsu2c_w_reg_dst,
    input   wire        lsu2p_w_reg_ena,
    input   wire [4 :0] lsu2p_w_reg_dst,
    input   wire        lsu2c_ls_ena,
    output  reg  [2 :0] forward
);

    always @(*) begin
        forward = `FORWARD_NOP;
        if (exp_w_reg_ena & (id_reg == exp_w_reg_dst)) begin
            forward = `FORWARD_EXP_ALU_RES;
        end else if (exc_w_reg_ena & (id_reg == exc_w_reg_dst)) begin
            forward = `FORWARD_EXC_ALU_RES;
        end else if (lsu1p_w_reg_ena & (id_reg == lsu1p_w_reg_dst)) begin
            forward = `FORWARD_LS1P_ALU_RES;
        end else if (lsu1c_w_reg_ena & (id_reg == lsu1c_w_reg_dst)) begin
            forward = `FORWARD_LS1C_ALU_RES;
        end else if (lsu2p_w_reg_ena & (id_reg == lsu2p_w_reg_dst)) begin
            forward = `FORWARD_LS2P_ALU_RES;
        end else if (lsu2c_ls_ena & lsu2c_w_reg_ena & (id_reg == lsu2c_w_reg_dst)) begin
            forward = `FORWARD_LS2C_MEM_DATA;
        end else if (lsu2c_w_reg_ena & (id_reg == lsu2c_w_reg_dst)) begin
            forward = `FORWARD_LS2C_ALU_RES;
        end
    end 

endmodule