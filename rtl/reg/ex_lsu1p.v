`timescale 1ns / 1ps

module ex_lsu1p (
    input   wire            clk,
    input   wire            rst,
    input   wire            flush,
    input   wire            exception_flush,
    input   wire            stall,
    
    input   wire [31:0]     ex_pc_o,
    input   wire [31:0]     ex_alu_res_o,
    input   wire            ex_in_delay_slot_o,
    input   wire            ex_w_reg_ena_o,
    input   wire [4 :0]     ex_w_reg_dst_o,
    input   wire            ex_wb_reg_sel_o,
    input   wire [31:0]     ex_rt_data_o,

    output  reg  [31:0]     ex_pc_i,
    output  reg  [31:0]     ex_alu_res_i,
    output  reg             ex_in_delay_slot_i,
    output  reg             ex_w_reg_ena_i,
    output  reg  [4 :0]     ex_w_reg_dst_i,
    output  reg             ex_wb_reg_sel_i,
    output  reg  [31:0]     ex_rt_data_i
);

    always @(posedge clk) begin
        if (rst || (flush & !stall) || exception_flush) begin
            ex_alu_res_i            <= 32'h0                ;
            ex_w_reg_ena_i          <= 1'h0                 ;
            ex_w_reg_dst_i          <= 5'h0                 ;
            ex_wb_reg_sel_i         <= 1'h0                 ;
            ex_pc_i                 <= 32'h0                ;
            ex_rt_data_i            <= 32'h0                ;
            ex_in_delay_slot_i      <= 1'b0                 ;
        end else if (!flush & !stall) begin
            ex_pc_i                 <= ex_pc_o              ;
            ex_alu_res_i            <= ex_alu_res_o         ;
            ex_in_delay_slot_i      <= ex_in_delay_slot_o   ;
            ex_w_reg_ena_i          <= ex_w_reg_ena_o       ;
            ex_w_reg_dst_i          <= ex_w_reg_dst_o       ;
            ex_wb_reg_sel_i         <= ex_wb_reg_sel_o      ;
            ex_rt_data_i            <= ex_rt_data_o         ;
        end
    end
    
endmodule