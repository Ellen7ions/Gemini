`timescale 1ns / 1ps

module ex_mem (
    input   wire            clk,
    input   wire            rst,
    input   wire            flush,
    input   wire            stall,
    input   wire [31:0]     ex_pc_o,
    input   wire [31:0]     ex_alu_res_o,
    input   wire [1 :0]     ex_w_hilo_ena_o,
    input   wire [31:0]     ex_hi_res_o,
    input   wire [31:0]     ex_lo_res_o,
    input   wire [31:0]     ex_w_reg_ena_o,
    input   wire [4 :0]     ex_w_reg_dst_o,
    input   wire            ex_ls_ena_o,
    input   wire [3 :0]     ex_ls_sel_o,
    input   wire            ex_wb_reg_sel_o,
    output  reg  [31:0]     ex_pc_i,
    output  reg  [31:0]     ex_alu_res_i,
    output  reg  [1 :0]     ex_w_hilo_ena_i,
    output  reg  [31:0]     ex_hi_res_i,
    output  reg  [31:0]     ex_lo_res_i,
    output  reg  [31:0]     ex_w_reg_ena_i,
    output  reg  [4 :0]     ex_w_reg_dst_i,
    output  reg             ex_ls_ena_i,
    output  reg  [3 :0]     ex_ls_sel_i,
    output  reg             ex_wb_reg_sel_i
);

    always @(posedge clk) begin
        if (rst || (flush & !stall)) begin
            ex_alu_res_i    <= 32'h0            ;
            ex_w_hilo_ena_i <= 2'h0             ;
            ex_hi_res_i     <= 32'h0            ;
            ex_lo_res_i     <= 32'h0            ;
            ex_w_reg_ena_i  <= 1'h0             ;
            ex_w_reg_dst_i  <= 5'h0             ;
            ex_ls_ena_i     <= 1'h0             ;
            ex_ls_sel_i     <= 4'h0             ;
            ex_wb_reg_sel_i <= 1'h0             ;
            ex_pc_i         <= 32'h0            ;
        end else begin
            ex_alu_res_i    <= ex_alu_res_o     ;
            ex_w_hilo_ena_i <= ex_w_hilo_ena_o  ;
            ex_hi_res_i     <= ex_hi_res_o      ;
            ex_lo_res_i     <= ex_lo_res_o      ;
            ex_w_reg_ena_i  <= ex_w_reg_ena_o   ;
            ex_w_reg_dst_i  <= ex_w_reg_dst_o   ;
            ex_ls_ena_i     <= ex_ls_ena_o      ;
            ex_ls_sel_i     <= ex_ls_sel_o      ;
            ex_wb_reg_sel_i <= ex_wb_reg_sel_o  ;
            ex_pc_i         <= ex_pc_o          ;
        end
    end
    
endmodule