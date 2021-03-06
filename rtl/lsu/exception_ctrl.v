`timescale 1ns / 1ps

`include "exception_def.v"

module exception_ctrl (
    input   wire            clk,
    input   wire            rst,

    // from pipeline
    (*mark_debug="true"*) input   wire [31:0]     pc_1,
    (*mark_debug="true"*) input   wire            refetch,
    (*mark_debug="true"*) input   wire [31:0]     mem_badvaddr_1,
    (*mark_debug="true"*) input   wire            in_delay_slot_1,
    (*mark_debug="true"*) input   wire            exception_is_eret_1,
    (*mark_debug="true"*) input   wire            exception_is_syscall_1,
    (*mark_debug="true"*) input   wire            exception_is_break_1,
    (*mark_debug="true"*) input   wire            exception_is_inst_adel_1,
    (*mark_debug="true"*) input   wire            exception_is_data_adel_1,
    (*mark_debug="true"*) input   wire            exception_is_data_ades_1,
    (*mark_debug="true"*) input   wire            exception_is_overflow_1,
    (*mark_debug="true"*) input   wire            exception_is_ri_1,
    (*mark_debug="true"*) input   wire            exception_is_int_1,
    (*mark_debug="true"*) input   wire            exception_is_i_refill_tlbl_1,
    (*mark_debug="true"*) input   wire            exception_is_i_invalid_tlbl_1,
    (*mark_debug="true"*) input   wire            exception_is_d_refill_tlbl_1,
    (*mark_debug="true"*) input   wire            exception_is_d_invalid_tlbl_1,
    (*mark_debug="true"*) input   wire            exception_is_d_refill_tlbs_1,
    (*mark_debug="true"*) input   wire            exception_is_d_invalid_tlbs_1,
    (*mark_debug="true"*) input   wire            exception_is_modify_1,
    (*mark_debug="true"*) input   wire            exception_has_exp_1,

    // from cp0
    input   wire [31:0]     r_cp0_epc,
    input   wire [31:0]     r_cp0_ebase,
    input   wire            bev,
    // update pc
    output  wire            exception_pc_ena,
    output  reg  [31:0]     exception_pc,

    // to cp0
    // update cp0
    output  reg             w_cp0_update_ena,
    output  reg  [4 :0]     w_cp0_exccode,
    output  reg             w_cp0_bd,
    output  reg             w_cp0_exl,
    output  reg  [31:0]     w_cp0_epc,
    output  reg             w_cp0_badvaddr_ena,
    output  reg  [31:0]     w_cp0_badvaddr,
    output  reg             w_cp0_entryhi_ena,
    output  reg  [31:0]     w_cp0_entryhi,

    output  reg             cp0_cls_exl,

    output  wire            flush_pipline
);
    wire            exception_has_1;

    assign exception_has_1  = 
        ~refetch & (
            exception_has_exp_1             |
            exception_is_d_refill_tlbl_1    |
            exception_is_d_invalid_tlbl_1   |
            exception_is_d_refill_tlbs_1    |
            exception_is_d_invalid_tlbs_1   |
            exception_is_modify_1
        );

    assign flush_pipline    = exception_has_1 | refetch;
    assign exception_pc_ena = exception_has_1 | refetch;
        
    wire [31:0] exp_ebase = bev ? 32'hbfc0_0200 : r_cp0_ebase;

    always @(*) begin
        cp0_cls_exl         = 1'b0;
        exception_pc        = exp_ebase + 32'h180;
        w_cp0_update_ena    = 1'b1;
        w_cp0_exccode       = 5'h00;
        w_cp0_bd            = 1'b0;
        w_cp0_exl           = 1'b0;
        w_cp0_epc           = 32'h0;
        w_cp0_badvaddr_ena  = 1'b0;
        w_cp0_badvaddr      = 32'h0;
        w_cp0_entryhi_ena   = 1'b0;
        w_cp0_entryhi       = 32'h0;
        if (refetch) begin
            w_cp0_update_ena= 1'b0;
            exception_pc    = pc_1;
        end else if (exception_has_1) begin
            w_cp0_bd            = in_delay_slot_1;
            w_cp0_exl           = 1'b1;
            w_cp0_epc           = in_delay_slot_1 ? pc_1 - 32'h4 : pc_1;
            if (exception_is_int_1) begin
                w_cp0_exccode           = 5'h00;
            end else if (exception_is_i_refill_tlbl_1) begin
                w_cp0_exccode   = 5'h02;
                exception_pc    = exp_ebase;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = pc_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = pc_1;
            end else if (exception_is_i_invalid_tlbl_1) begin
                w_cp0_exccode   = 5'h02;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = pc_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = pc_1;
            end else if (exception_is_inst_adel_1) begin
                w_cp0_exccode   = 5'h04;
                w_cp0_badvaddr_ena = 1'b1;
                w_cp0_badvaddr  = pc_1;
            end else if (exception_is_ri_1) begin
                w_cp0_exccode   = 5'h0a;
            end else if (exception_is_overflow_1) begin
                w_cp0_exccode   = 5'h0c;
            end else if (exception_is_syscall_1) begin
                w_cp0_exccode   = 5'h08;
            end else if (exception_is_break_1) begin
                w_cp0_exccode   = 5'h09;
            end else if (exception_is_eret_1) begin
                w_cp0_update_ena    = 1'b0;
                cp0_cls_exl         = 1'b1;
                exception_pc        = r_cp0_epc;
            end else if (exception_is_d_refill_tlbl_1) begin
                w_cp0_exccode   = 5'h02;
                exception_pc    = exp_ebase;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = mem_badvaddr_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = mem_badvaddr_1;
            end else if (exception_is_d_invalid_tlbl_1) begin
                w_cp0_exccode   = 5'h02;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = mem_badvaddr_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = mem_badvaddr_1;
            end else if (exception_is_d_refill_tlbs_1) begin
                w_cp0_exccode   = 5'h03;
                exception_pc    = exp_ebase;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = mem_badvaddr_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = mem_badvaddr_1;
            end else if (exception_is_d_invalid_tlbs_1) begin
                w_cp0_exccode   = 5'h03;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = mem_badvaddr_1[31:13];
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = mem_badvaddr_1;
            end else if (exception_is_data_adel_1) begin
                w_cp0_exccode   = 5'h04;
                w_cp0_badvaddr_ena = 1'b1;
                w_cp0_badvaddr  = mem_badvaddr_1;
            end else if (exception_is_data_ades_1) begin
                w_cp0_exccode   = 5'h05;
                w_cp0_badvaddr_ena = 1'b1;
                w_cp0_badvaddr  = mem_badvaddr_1;
            end else if (exception_is_modify_1) begin
                w_cp0_exccode   = 5'h01;
                w_cp0_badvaddr_ena      = 1'b1;
                w_cp0_badvaddr          = mem_badvaddr_1;
                w_cp0_entryhi_ena       = 1'b1;
                w_cp0_entryhi[31:13]    = mem_badvaddr_1[31:13];
            end
        end else begin
            w_cp0_update_ena    = 1'b0;
        end
    end

endmodule