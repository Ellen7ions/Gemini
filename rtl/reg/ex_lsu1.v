`timescale 1ns / 1ps

module ex_lsu1 (
    input   wire            clk,
    input   wire            rst,
    input   wire            flush,
    input   wire            exception_flush,
    input   wire            stall,
    input   wire [31:0]     ex_pc_o,
    input   wire [31:0]     ex_alu_res_o,
    input   wire [31:0]     ex_ls_addr_o,
    input   wire [31:0]     ex_psyaddr_o,
    input   wire [1 :0]     ex_w_hilo_ena_o,
    input   wire [31:0]     ex_hi_res_o,
    input   wire [31:0]     ex_lo_res_o,

    input   wire            ex_in_delay_slot_o,
    input   wire            ex_is_eret_o,
    input   wire            ex_is_syscall_o,
    input   wire            ex_is_break_o,
    input   wire            ex_is_inst_adel_o,
    input   wire            ex_is_data_adel_o,
    input   wire            ex_is_data_ades_o,
    input   wire            ex_is_overflow_o,
    input   wire            ex_is_ri_o,
    input   wire            ex_is_int_o,
    input   wire            ex_is_i_refill_tlbl_o,
    input   wire            ex_is_i_invalid_tlbl_o,
    input   wire            ex_is_d_refill_tlbl_o,
    input   wire            ex_is_d_invalid_tlbl_o,
    input   wire            ex_is_d_refill_tlbs_o,
    input   wire            ex_is_d_invalid_tlbs_o,
    input   wire            ex_is_modify_o,
    input   wire            ex_is_refetch_o,
    input   wire            ex_is_tlbp_o,
    input   wire            ex_is_tlbr_o,
    input   wire            ex_is_tlbwi_o,
    input   wire            ex_has_exception_o,

    input   wire            ex_w_reg_ena_o,
    input   wire [4 :0]     ex_w_reg_dst_o,
    input   wire            ex_ls_ena_o,
    input   wire [3 :0]     ex_ls_sel_o,
    input   wire            ex_wb_reg_sel_o,
    input   wire [31:0]     ex_rt_data_o,
    input   wire            ex_w_cp0_ena_o,
    input   wire [7 :0]     ex_w_cp0_addr_o,
    input   wire [31:0]     ex_w_cp0_data_o,
    output  reg  [31:0]     ex_pc_i,
    output  reg  [31:0]     ex_alu_res_i,
    output  reg  [31:0]     ex_ls_addr_i,
    output  reg  [31:0]     ex_psyaddr_i,
    output  reg  [1 :0]     ex_w_hilo_ena_i,
    output  reg  [31:0]     ex_hi_res_i,
    output  reg  [31:0]     ex_lo_res_i,

    output  reg             ex_in_delay_slot_i,
    output  reg             ex_is_eret_i,
    output  reg             ex_is_syscall_i,
    output  reg             ex_is_break_i,
    output  reg             ex_is_inst_adel_i,
    output  reg             ex_is_data_adel_i,
    output  reg             ex_is_data_ades_i,
    output  reg             ex_is_overflow_i,
    output  reg             ex_is_ri_i,
    output  reg             ex_is_int_i,
    output  reg             ex_is_i_refill_tlbl_i,
    output  reg             ex_is_i_invalid_tlbl_i,
    output  reg             ex_is_d_refill_tlbl_i,
    output  reg             ex_is_d_invalid_tlbl_i,
    output  reg             ex_is_d_refill_tlbs_i,
    output  reg             ex_is_d_invalid_tlbs_i,
    output  reg             ex_is_modify_i,
    output  reg             ex_is_refetch_i,
    output  reg             ex_is_tlbp_i,
    output  reg             ex_is_tlbr_i,
    output  reg             ex_is_tlbwi_i,
    output  reg             ex_has_exception_i,

    output  reg             ex_w_reg_ena_i,
    output  reg  [4 :0]     ex_w_reg_dst_i,
    output  reg             ex_ls_ena_i,
    output  reg  [3 :0]     ex_ls_sel_i,
    output  reg             ex_wb_reg_sel_i,
    output  reg  [31:0]     ex_rt_data_i,
    output  reg             ex_w_cp0_ena_i,
    output  reg  [7 :0]     ex_w_cp0_addr_i,
    output  reg  [31:0]     ex_w_cp0_data_i
);

    always @(posedge clk) begin
        if (rst || (flush & !stall) || exception_flush) begin
            ex_alu_res_i            <= 32'h0                ;
            ex_w_hilo_ena_i         <= 2'h0                 ;
            ex_hi_res_i             <= 32'h0                ;
            ex_lo_res_i             <= 32'h0                ;
            ex_w_reg_ena_i          <= 1'h0                 ;
            ex_w_reg_dst_i          <= 5'h0                 ;
            ex_ls_ena_i             <= 1'h0                 ;
            ex_ls_sel_i             <= 4'h0                 ;
            ex_wb_reg_sel_i         <= 1'h0                 ;
            ex_pc_i                 <= 32'h0                ;
            ex_rt_data_i            <= 32'h0                ;
            ex_w_cp0_ena_i          <= 1'h0                 ;
            ex_w_cp0_addr_i         <= 8'h0                 ;
            ex_w_cp0_data_i         <= 32'h0                ;
            ex_in_delay_slot_i      <= 1'b0                 ;
            ex_is_eret_i            <= 1'b0                 ;
            ex_is_syscall_i         <= 1'b0                 ;
            ex_is_break_i           <= 1'b0                 ;
            ex_is_inst_adel_i       <= 1'b0                 ;
            ex_is_overflow_i        <= 1'b0                 ;
            ex_is_ri_i              <= 1'b0                 ;
            ex_is_data_adel_i       <= 1'b0                 ;
            ex_is_data_ades_i       <= 1'b0                 ;
            ex_is_int_i             <= 1'h0                 ;
            ex_ls_addr_i            <= 32'h0                ;
            ex_has_exception_i      <= 1'h0                 ;
            ex_is_i_refill_tlbl_i   <= 1'b0                 ;
            ex_is_i_invalid_tlbl_i  <= 1'b0                 ;
            ex_is_d_refill_tlbl_i   <= 1'b0                 ;
            ex_is_d_invalid_tlbl_i  <= 1'b0                 ;
            ex_is_d_refill_tlbs_i   <= 1'b0                 ;
            ex_is_d_invalid_tlbs_i  <= 1'b0                 ;
            ex_is_modify_i          <= 1'b0                 ;
            // ex_is_tlbp_i            <= 1'b0                 ;
            ex_is_tlbr_i            <= 1'b0                 ;
            ex_is_tlbwi_i           <= 1'b0                 ;
            ex_is_refetch_i         <= 1'b0                 ;
            ex_is_tlbp_i            <= 1'b0                 ;
            ex_psyaddr_i            <= 32'h0                ;
        end else if (!flush & !stall) begin
            ex_alu_res_i            <= ex_alu_res_o         ;
            ex_w_hilo_ena_i         <= ex_w_hilo_ena_o      ;
            ex_hi_res_i             <= ex_hi_res_o          ;
            ex_lo_res_i             <= ex_lo_res_o          ;
            ex_w_reg_ena_i          <= ex_w_reg_ena_o       ;
            ex_w_reg_dst_i          <= ex_w_reg_dst_o       ;
            ex_ls_ena_i             <= ex_ls_ena_o          ;
            ex_ls_sel_i             <= ex_ls_sel_o          ;
            ex_wb_reg_sel_i         <= ex_wb_reg_sel_o      ;
            ex_pc_i                 <= ex_pc_o              ;
            ex_rt_data_i            <= ex_rt_data_o         ;
            ex_w_cp0_ena_i          <= ex_w_cp0_ena_o       ;
            ex_w_cp0_addr_i         <= ex_w_cp0_addr_o      ;
            ex_w_cp0_data_i         <= ex_w_cp0_data_o      ;
            ex_in_delay_slot_i      <= ex_in_delay_slot_o   ;
            ex_is_eret_i            <= ex_is_eret_o         ;
            ex_is_syscall_i         <= ex_is_syscall_o      ;
            ex_is_break_i           <= ex_is_break_o        ;
            ex_is_inst_adel_i       <= ex_is_inst_adel_o    ;
            ex_is_overflow_i        <= ex_is_overflow_o     ;
            ex_is_ri_i              <= ex_is_ri_o           ;
            ex_is_data_adel_i       <= ex_is_data_adel_o    ;
            ex_is_data_ades_i       <= ex_is_data_ades_o    ;
            ex_is_int_i             <= ex_is_int_o          ;
            ex_ls_addr_i            <= ex_ls_addr_o         ;
            ex_has_exception_i      <= ex_has_exception_o   ;
            ex_is_i_refill_tlbl_i   <= ex_is_i_refill_tlbl_o    ;
            ex_is_i_invalid_tlbl_i  <= ex_is_i_invalid_tlbl_o   ;
            ex_is_d_refill_tlbl_i   <= ex_is_d_refill_tlbl_o    ;
            ex_is_d_invalid_tlbl_i  <= ex_is_d_invalid_tlbl_o   ;
            ex_is_d_refill_tlbs_i   <= ex_is_d_refill_tlbs_o    ;
            ex_is_d_invalid_tlbs_i  <= ex_is_d_invalid_tlbs_o   ;
            ex_is_modify_i          <= ex_is_modify_o       ;
            ex_is_refetch_i         <= ex_is_refetch_o      ;
            // ex_is_tlbp_i            <= ex_is_tlbp_o         ;
            ex_is_tlbr_i            <= ex_is_tlbr_o         ;
            ex_is_tlbwi_i           <= ex_is_tlbwi_o        ;
            ex_is_tlbp_i            <= ex_is_tlbp_o         ;
            ex_psyaddr_i            <= ex_psyaddr_o         ;
        end
    end
    
endmodule