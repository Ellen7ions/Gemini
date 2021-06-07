`timescale 1ns / 1ps

module issue_id2 (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        stall,

    input   wire        id1_valid_o,

    input   wire [31:0] id1_pc_o,
    input   wire [31:0] id1_inst_o,
    input   wire [5 :0] id1_op_code_o,
    input   wire [4 :0] id1_rs_o,
    input   wire [4 :0] id1_rt_o,
    input   wire [4 :0] id1_rd_o,
    input   wire [4 :0] id1_sa_o,
    input   wire [5 :0] id1_funct_o,
    input   wire        id1_w_reg_ena_o,
    input   wire [4 :0] id1_w_reg_dst_o,
    input   wire [15:0] id1_imme_o,
    input   wire [25:0] id1_j_imme_o,
    input   wire        id1_is_branch_o,
    input   wire        id1_is_j_imme_o,
    input   wire        id1_is_jr_o,
    input   wire        id1_is_ls_o,

    output  reg  [31:0] id1_pc_i,
    output  reg  [31:0] id1_inst_i,
    output  reg  [5 :0] id1_op_code_i,
    output  reg  [4 :0] id1_rs_i,
    output  reg  [4 :0] id1_rt_i,
    output  reg  [4 :0] id1_rd_i,
    output  reg  [4 :0] id1_sa_i,
    output  reg  [5 :0] id1_funct_i,
    output  reg         id1_w_reg_ena_i,
    output  reg  [4 :0] id1_w_reg_dst_i,
    output  reg  [15:0] id1_imme_i,
    output  reg  [25:0] id1_j_imme_i,
    output  reg         id1_is_branch_i,
    output  reg         id1_is_j_imme_i,
    output  reg         id1_is_jr_i,
    output  reg         id1_is_ls_i
);

    always @(posedge clk) begin
        if (rst || (flush & !stall) || !id1_valid_o) begin
            id1_pc_i           <=  32'h0;
            id1_inst_i         <=  32'h0;
            id1_op_code_i      <=  6'h0;
            id1_rs_i           <=  5'h0;
            id1_rt_i           <=  5'h0;
            id1_rd_i           <=  5'h0;
            id1_sa_i           <=  5'h0;
            id1_funct_i        <=  6'h0;
            id1_w_reg_ena_i    <=  1'b0;
            id1_w_reg_dst_i    <=  5'h0;
            id1_imme_i         <=  16'h0;
            id1_j_imme_i       <=  26'h0;
            id1_is_branch_i    <=  1'b0;
            id1_is_j_imme_i    <=  1'b0;
            id1_is_jr_i        <=  1'b0;
            id1_is_ls_i        <=  1'b0;
        end else if (!flush & !stall) begin
            id1_pc_i           <=  id1_pc_o;
            id1_inst_i         <=  id1_inst_o;
            id1_op_code_i      <=  id1_op_code_o;    
            id1_rs_i           <=  id1_rs_o;
            id1_rt_i           <=  id1_rt_o;
            id1_rd_i           <=  id1_rd_o;
            id1_sa_i           <=  id1_sa_o;
            id1_funct_i        <=  id1_funct_o;    
            id1_w_reg_ena_i    <=  id1_w_reg_ena_o;        
            id1_w_reg_dst_i    <=  id1_w_reg_dst_o;        
            id1_imme_i         <=  id1_imme_o;
            id1_j_imme_i       <=  id1_j_imme_o;    
            id1_is_branch_i    <=  id1_is_branch_o;        
            id1_is_j_imme_i    <=  id1_is_j_imme_o;        
            id1_is_jr_i        <=  id1_is_jr_o;    
            id1_is_ls_i        <=  id1_is_ls_o;    
        end
    end
    
endmodule