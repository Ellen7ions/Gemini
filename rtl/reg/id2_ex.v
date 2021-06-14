`timescale 1ns / 1ps

module id2_ex (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        stall,
    
    input   wire        id2_is_branch_o,
    input   wire        id2_is_j_imme_o,
    input   wire        id2_is_jr_o,
    input   wire        id2_is_ls_o,
    input   wire [3 :0] id2_branch_sel_o,
    input   wire [4 :0] id2_rs_o,
    input   wire [4 :0] id2_rt_o,
    input   wire [4 :0] id2_rd_o,
    input   wire [4 :0] id2_w_reg_dst_o,
    input   wire [4 :0] id2_sa_o,
    input   wire [31:0] id2_rs_data_o,
    input   wire [31:0] id2_rt_data_o,
    input   wire [15:0] id2_imme_o,
    input   wire [25:0] id2_j_imme_o,
    input   wire [31:0] id2_ext_imme_o,
    input   wire [31:0] id2_pc_o,
    input   wire [2 :0] id2_src_a_sel_o,
    input   wire [2 :0] id2_src_b_sel_o,
    input   wire [5 :0] id2_alu_sel_o,
    input   wire [2 :0] id2_alu_res_sel_o,
    input   wire        id2_w_reg_ena_o,
    input   wire [1 :0] id2_w_hilo_ena_o,
    input   wire        id2_w_cp0_ena_o,
    input   wire        id2_ls_ena_o,
    input   wire [3 :0] id2_ls_sel_o,
    input   wire        id2_wb_reg_sel_o,

    output  reg         id2_is_branch_i,
    output  reg         id2_is_j_imme_i,
    output  reg         id2_is_jr_i,
    output  reg         id2_is_ls_i,
    output  reg  [3 :0] id2_branch_sel_i,
    output  reg  [4 :0] id2_rs_i,
    output  reg  [4 :0] id2_rt_i,
    output  reg  [4 :0] id2_rd_i,
    output  reg  [4 :0] id2_w_reg_dst_i,
    output  reg  [4 :0] id2_sa_i,
    output  reg  [31:0] id2_rs_data_i,
    output  reg  [31:0] id2_rt_data_i,
    output  reg  [15:0] id2_imme_i,
    output  reg  [25:0] id2_j_imme_i,
    output  reg  [31:0] id2_ext_imme_i,
    output  reg  [31:0] id2_pc_i,
    output  reg  [2 :0] id2_src_a_sel_i,
    output  reg  [2 :0] id2_src_b_sel_i,
    output  reg  [5 :0] id2_alu_sel_i,
    output  reg  [2 :0] id2_alu_res_sel_i,
    output  reg         id2_w_reg_ena_i,
    output  reg  [1 :0] id2_w_hilo_ena_i,
    output  reg         id2_w_cp0_ena_i,
    output  reg         id2_ls_ena_i,
    output  reg  [3 :0] id2_ls_sel_i,
    output  reg         id2_wb_reg_sel_i
);
    always @(posedge clk) begin
        if (rst || (flush & !stall)) begin
            id2_is_branch_i     <= 1'h0;
            id2_is_j_imme_i     <= 1'h0;
            id2_is_jr_i         <= 1'h0;
            id2_is_ls_i         <= 1'h0;
            id2_rs_i            <= 5'h0;
            id2_rt_i            <= 5'h0;
            id2_rd_i            <= 5'h0;
            id2_w_reg_dst_i     <= 5'h0;
            id2_sa_i            <= 5'h0;
            id2_rs_data_i       <= 32'h0;
            id2_rt_data_i       <= 32'h0;
            id2_imme_i          <= 16'h0;
            id2_j_imme_i        <= 26'h0;
            id2_ext_imme_i      <= 31'h0;
            id2_pc_i            <= 31'h0;
            id2_src_a_sel_i     <= 3'h0;
            id2_src_b_sel_i     <= 3'h0;
            id2_alu_sel_i       <= 6'h0;
            id2_alu_res_sel_i   <= 3'h0;
            id2_w_reg_ena_i     <= 1'h0;
            id2_w_hilo_ena_i    <= 2'h0;
            id2_w_cp0_ena_i     <= 1'h0;
            id2_ls_ena_i        <= 1'h0;
            id2_ls_sel_i        <= 4'h0;
            id2_wb_reg_sel_i    <= 1'h0;
            id2_branch_sel_i    <= 4'h0;
        end else if (!flush & !stall) begin
            id2_is_branch_i     <= id2_is_branch_o;
            id2_is_j_imme_i     <= id2_is_j_imme_o;
            id2_is_jr_i         <= id2_is_jr_o;
            id2_is_ls_i         <= id2_is_ls_o;
            id2_rs_i            <= id2_rs_o;
            id2_rt_i            <= id2_rt_o;
            id2_rd_i            <= id2_rd_o;
            id2_w_reg_dst_i     <= id2_w_reg_dst_o;
            id2_sa_i            <= id2_sa_o;
            id2_rs_data_i       <= id2_rs_data_o;
            id2_rt_data_i       <= id2_rt_data_o;
            id2_imme_i          <= id2_imme_o;
            id2_j_imme_i        <= id2_j_imme_o;
            id2_ext_imme_i      <= id2_ext_imme_o;
            id2_pc_i            <= id2_pc_o;
            id2_src_a_sel_i     <= id2_src_a_sel_o;
            id2_src_b_sel_i     <= id2_src_b_sel_o;
            id2_alu_sel_i       <= id2_alu_sel_o;
            id2_alu_res_sel_i   <= id2_alu_res_sel_o;
            id2_w_reg_ena_i     <= id2_w_reg_ena_o;
            id2_w_hilo_ena_i    <= id2_w_hilo_ena_o;
            id2_w_cp0_ena_i     <= id2_w_cp0_ena_o;
            id2_ls_ena_i        <= id2_ls_ena_o;
            id2_ls_sel_i        <= id2_ls_sel_o;
            id2_wb_reg_sel_i    <= id2_wb_reg_sel_o;
            id2_branch_sel_i    <= id2_branch_sel_o;
        end
    end
endmodule