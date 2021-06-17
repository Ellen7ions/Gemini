`timescale 1ns / 1ps

`include "exception_def.v"

module exception_ctrl (
    input   wire            clk,
    input   wire            rst,

    // from pipeline
    input   wire [31:0]     pc_1,
    input   wire            in_delay_slot_1,

    input   wire            exception_is_eret_1,
    input   wire            exception_is_syscall_1,
    input   wire            exception_is_break_1,
    input   wire            exception_is_inst_adel_1,
    input   wire            exception_is_data_adel_1,
    input   wire            exception_is_data_ades_1,
    input   wire            exception_is_overflow_1,
    input   wire            exception_is_ri_1,

    input   wire [31:0]     pc_2,
    input   wire            in_delay_slot_2,

    input   wire            exception_is_eret_2,
    input   wire            exception_is_syscall_2,
    input   wire            exception_is_break_2,
    input   wire            exception_is_inst_adel_2,
    input   wire            exception_is_data_adel_2,
    input   wire            exception_is_data_ades_2,
    input   wire            exception_is_overflow_2,
    input   wire            exception_is_ri_2,

    // from cp0
    input   wire            exception_is_interrupt,
    input   wire [31:0]     r_cp0_epc,
    // update pc
    output  reg             exception_pc_ena,
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

    output  reg             cp0_cls_exl,

    output  reg             flush_pipline
);
    wire            exception_has_1;
    wire            exception_has_2;

    assign exception_has_1  =
            exception_is_eret_1         |     
            exception_is_syscall_1      |    
            exception_is_break_1        |    
            exception_is_inst_adel_1    |        
            exception_is_data_adel_1    |        
            exception_is_data_ades_1    |        
            exception_is_overflow_1     |    
            exception_is_ri_1           ;
    
    assign exception_has_2  =
            exception_is_eret_2         |     
            exception_is_syscall_2      |    
            exception_is_break_2        |    
            exception_is_inst_adel_2    |        
            exception_is_data_adel_2    |        
            exception_is_data_ades_2    |        
            exception_is_overflow_2     |    
            exception_is_ri_2           ;

    always @(*) begin
        cp0_cls_exl       = 1'b0;

        exception_pc_ena    = 1'b0;
        exception_pc        = 32'h0;

        w_cp0_update_ena    = 1'b0;
        w_cp0_exccode       = 5'h00;
        w_cp0_bd            = 1'b0;
        w_cp0_exl           = 1'b0;
        w_cp0_epc           = 32'h0;
        w_cp0_badvaddr_ena  = 1'b0;
        w_cp0_badvaddr      = 32'h0;
        flush_pipline       = 1'b1;
        if (exception_is_interrupt) begin
            exception_pc_ena        = 1'b1;
            exception_pc            = 32'hbfc0_0380;
            w_cp0_update_ena        = 1'b1;
            w_cp0_exccode           = 5'h00;
            w_cp0_bd                = in_delay_slot_1;
            w_cp0_exl               = 1'b1;
            w_cp0_epc               = in_delay_slot_1 ? pc_1 - 32'h4 : pc_1;
        end else begin
            if (exception_has_1) begin
                exception_pc_ena    = 1'b1;
                exception_pc        = 32'hbfc0_0380;
                w_cp0_update_ena    = 1'b1;
                w_cp0_bd            = in_delay_slot_1;
                w_cp0_exl           = 1'b1;
                w_cp0_epc           = in_delay_slot_1 ? pc_1 - 32'h4 : pc_1;
                if (exception_is_inst_adel_1) begin
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
                end else if (exception_is_data_adel_1) begin
                    w_cp0_exccode   = 5'h05;
                    w_cp0_badvaddr_ena = 1'b1;
                    w_cp0_badvaddr  = pc_1;
                end else if (exception_is_data_ades_1) begin
                    w_cp0_exccode   = 5'h05;
                    w_cp0_badvaddr_ena = 1'b1;
                    w_cp0_badvaddr  = pc_1;
                end
            end else if (exception_has_2) begin
                exception_pc_ena    = 1'b1;
                exception_pc        = 32'hbfc0_0380;
                w_cp0_update_ena    = 1'b1;
                w_cp0_bd            = in_delay_slot_2;
                w_cp0_exl           = 1'b1;
                w_cp0_epc           = in_delay_slot_2 ? pc_2 - 32'h4 : pc_2;
                if (exception_is_inst_adel_2) begin
                    w_cp0_exccode   = 5'h04;
                    w_cp0_badvaddr_ena = 1'b1;
                    w_cp0_badvaddr  = pc_2;
                end else if (exception_is_ri_2) begin
                    w_cp0_exccode   = 5'h0a;
                end else if (exception_is_overflow_2) begin
                    w_cp0_exccode   = 5'h0c;
                end else if (exception_is_syscall_2) begin
                    w_cp0_exccode   = 5'h08;
                end else if (exception_is_break_2) begin
                    w_cp0_exccode   = 5'h09;
                end else if (exception_is_eret_2) begin
                    w_cp0_update_ena    = 1'b0;
                    cp0_cls_exl         = 1'b1;
                    exception_pc        = r_cp0_epc;
                end else if (exception_is_data_adel_2) begin
                    w_cp0_exccode       = 5'h05;
                    w_cp0_badvaddr_ena  = 1'b1;
                    w_cp0_badvaddr      = pc_2;
                end else if (exception_is_data_ades_2) begin
                    w_cp0_exccode       = 5'h05;
                    w_cp0_badvaddr_ena  = 1'b1;
                    w_cp0_badvaddr      = pc_2;
                end
            end else begin
                flush_pipline = 1'b0;
            end
        end
    end

endmodule