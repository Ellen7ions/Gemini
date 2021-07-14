`timescale 1ns / 1ps

module id2_exp (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        exception_flush,
    input   wire        stall,
    
    input   wire        id2_in_delay_slot_o,
    input   wire [4 :0] id2_rs_o,
    input   wire [4 :0] id2_rt_o,
    input   wire [4 :0] id2_rd_o,
    input   wire [4 :0] id2_w_reg_dst_o,
    input   wire [4 :0] id2_sa_o,
    input   wire [31:0] id2_rs_data_o,
    input   wire [31:0] id2_rt_data_o,
    input   wire [31:0] id2_ext_imme_o,
    input   wire [31:0] id2_pc_o,
    input   wire [2 :0] id2_src_a_sel_o,
    input   wire [2 :0] id2_src_b_sel_o,
    input   wire [5 :0] id2_alu_sel_o,
    input   wire [2 :0] id2_alu_res_sel_o,
    input   wire        id2_w_reg_ena_o,
    input   wire        id2_wb_reg_sel_o,

    output  reg         id2_in_delay_slot_i,
    output  reg  [4 :0] id2_rs_i,
    output  reg  [4 :0] id2_rt_i,
    output  reg  [4 :0] id2_rd_i,
    output  reg  [4 :0] id2_w_reg_dst_i,
    output  reg  [4 :0] id2_sa_i,
    output  reg  [31:0] id2_rs_data_i,
    output  reg  [31:0] id2_rt_data_i,
    output  reg  [31:0] id2_ext_imme_i,
    output  reg  [31:0] id2_pc_i,
    output  reg  [2 :0] id2_src_a_sel_i,
    output  reg  [2 :0] id2_src_b_sel_i,
    output  reg  [5 :0] id2_alu_sel_i,
    output  reg  [2 :0] id2_alu_res_sel_i,
    output  reg         id2_w_reg_ena_i,
    output  reg         id2_wb_reg_sel_i
);
    always @(posedge clk) begin
        if (rst || (flush & !stall) || exception_flush) begin
            id2_rs_i            <= 5'h0;
            id2_rt_i            <= 5'h0;
            id2_rd_i            <= 5'h0;
            id2_w_reg_dst_i     <= 5'h0;
            id2_sa_i            <= 5'h0;
            id2_rs_data_i       <= 32'h0;
            id2_rt_data_i       <= 32'h0;
            id2_ext_imme_i      <= 31'h0;
            id2_pc_i            <= 31'h0;
            id2_src_a_sel_i     <= 3'h0;
            id2_src_b_sel_i     <= 3'h0;
            id2_alu_sel_i       <= 6'h0;
            id2_alu_res_sel_i   <= 3'h0;
            id2_w_reg_ena_i     <= 1'h0;
            id2_wb_reg_sel_i    <= 1'h0;
            id2_in_delay_slot_i <= 1'h0;
        end else if (!flush & !stall) begin
            id2_rs_i            <= id2_rs_o;
            id2_rt_i            <= id2_rt_o;
            id2_rd_i            <= id2_rd_o;
            id2_w_reg_dst_i     <= id2_w_reg_dst_o;
            id2_sa_i            <= id2_sa_o;
            id2_rs_data_i       <= id2_rs_data_o;
            id2_rt_data_i       <= id2_rt_data_o;
            id2_ext_imme_i      <= id2_ext_imme_o;
            id2_pc_i            <= id2_pc_o;
            id2_src_a_sel_i     <= id2_src_a_sel_o;
            id2_src_b_sel_i     <= id2_src_b_sel_o;
            id2_alu_sel_i       <= id2_alu_sel_o;
            id2_alu_res_sel_i   <= id2_alu_res_sel_o;
            id2_w_reg_ena_i     <= id2_w_reg_ena_o;
            id2_wb_reg_sel_i    <= id2_wb_reg_sel_o;
            id2_in_delay_slot_i <= id2_in_delay_slot_o;
        end
    end
endmodule