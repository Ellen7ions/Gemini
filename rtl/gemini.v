`timescale 1ns / 1ps

module gemini (
    input   wire        clk,
    input   wire        rst,
    input   wire [5 :0] interrupt,
    output  wire        inst_ena,
    output  wire [31:0] inst_addr_next_pc,
    output  wire [31:0] inst_addr_pc,
    input   wire [31:0] inst_rdata_1,
    input   wire [31:0] inst_rdata_2,
    input   wire        inst_rdata_1_ok,
    input   wire        inst_rdata_2_ok,
    input   wire        i_cache_stall_req,
    output  wire        data_ena,
    output  wire [3 :0] data_wea,
    output  wire [31:0] data_waddr,
    output  wire [31:0] data_wdata,
    input   wire [31:0] data_rdata,
    input   wire        d_cache_stall_req,
    
    output  wire [31:0] debug_wb_pc_1,
    output  wire [3 :0] debug_wb_rf_wen_1,
    output  wire [4 :0] debug_wb_rf_wnum_1,
    output  wire [31:0] debug_wb_rf_wdata_1,
    output  wire [31:0] debug_wb_pc_2,
    output  wire [3 :0] debug_wb_rf_wen_2,
    output  wire [4 :0] debug_wb_rf_wnum_2,
    output  wire [31:0] debug_wb_rf_wdata_2
);

    // pipeline regs
    wire [31:0]     pc_cur_pc;
    wire [31:0]     npc_next_pc;
    wire            p_data_1;
    wire            p_data_2;
    wire [63:0]     fifo_r_data_1;
    wire [63:0]     fifo_r_data_2;
    wire            fifo_r_data_1_ok;
    wire            fifo_r_data_2_ok;
    wire [2 :0]     forwardc_rs;
    wire [2 :0]     forwardc_rt;
    wire [2 :0]     forwardp_rs;
    wire [2 :0]     forwardp_rt;
    wire [2 :0]     forwardc_hi;
    wire [2 :0]     forwardc_lo;
    wire [2 :0]     forwardp_hi;
    wire [2 :0]     forwardp_lo;

    wire [4 :0]     id2c_r_addr_1;
    wire [4 :0]     id2c_r_addr_2;
    wire [31:0]     id2c_r_data_1;
    wire [31:0]     id2c_r_data_2;
    wire [4 :0]     id2p_r_addr_1;
    wire [4 :0]     id2p_r_addr_2;
    wire [31:0]     id2p_r_data_1;
    wire [31:0]     id2p_r_data_2;

    wire [63:0]     fifo_w_data_1;
    wire [63:0]     fifo_w_data_2;

    // ii => id2
    wire            pc_stall;
    wire            pc_flush;
    wire            fifo_flush;
    wire            issue_stall;
    wire            ii_id2_flush;
    wire            ii_id2_stall;
    wire            id2_ex_flush;
    wire            id2_ex_stall;
    wire            ex_mem_flush;
    wire            ex_mem_stall;
    wire            mem_wb_flush;
    wire            mem_wb_stall;
    wire            wb_stall;
    wire            fifo_stall_req;
    wire            forwardc_stall_req;
    wire            forwardc_flush_req;
    wire            forwardp_stall_req;
    wire            forwardp_flush_req;
    // wire            id2c_flush_req;
    wire            b_ctrl_flush_req;
    wire            exc_stall_req;
    wire            exp_stall_req;

    wire            ii_id2_exception_flush;
    wire            id2_ex_exception_flush;
    wire            ex_mem_exception_flush;
    wire            mem_wb_exception_flush;

    wire            cp0_has_int;
    wire            exc_is_int_i;
    wire            exc_is_int_o;
    wire            exp_is_int_i;
    wire            exp_is_int_o;
    wire            id2p_is_int_i;
    wire            id2p_is_int_o;
    wire            id2c_is_int_i;
    wire            id2c_is_int_o;

    wire [31:0]     r_hi_data;
    wire [31:0]     r_lo_data;
    wire [31:0]     wbc_pc_o;
    wire            wbc_w_reg_ena_o;
    wire [4 :0]     wbc_w_reg_addr_o;
    wire [31:0]     wbc_w_reg_data_o;
    wire [31:0]     wbp_pc_o;
    wire            wbp_w_reg_ena_o;
    wire [4 :0]     wbp_w_reg_addr_o;
    wire [31:0]     wbp_w_reg_data_o;

    wire            id1c_valid_o;
    wire [28:0]     id1c_op_codes_o;
    wire [28:0]     id1c_func_codes_o;
    wire [31:0]     id1c_pc_o;
    wire [31:0]     id1c_inst_o;
    wire [4 :0]     id1c_rs_o;
    wire [4 :0]     id1c_rt_o;
    wire [4 :0]     id1c_rd_o;
    wire [4 :0]     id1c_sa_o;
    wire            id1c_w_reg_ena_o;
    wire [4 :0]     id1c_w_reg_dst_o;
    wire [15:0]     id1c_imme_o;
    wire [25:0]     id1c_j_imme_o;
    wire            id1c_is_branch_o;
    wire            id1c_is_j_imme_o;
    wire            id1c_is_jr_o;
    wire            id1c_is_ls_o;
    wire            id1c_in_delay_slot_o;
    wire            id1c_is_inst_adel_o;

    wire            id1c_valid_i;
    wire [31:0]     id1c_pc_i;
    wire [31:0]     id1c_inst_i;
    wire [28:0]     id1c_op_codes_i;
    wire [28:0]     id1c_func_codes_i;
    wire [4 :0]     id1c_rs_i;
    wire [4 :0]     id1c_rt_i;
    wire [4 :0]     id1c_rd_i;
    wire [4 :0]     id1c_sa_i;
    wire            id1c_w_reg_ena_i;
    wire [4 :0]     id1c_w_reg_dst_i;
    wire [15:0]     id1c_imme_i;
    wire [25:0]     id1c_j_imme_i;
    wire            id1c_is_branch_i;
    wire            id1c_is_j_imme_i;
    wire            id1c_is_jr_i;
    wire            id1c_is_ls_i;
    wire            id1c_in_delay_slot_i;
    wire            id1c_is_inst_adel_i;

    wire            id1p_valid_o;
    wire [31:0]     id1p_pc_o;
    wire [28:0]     id1p_op_codes_o;
    wire [28:0]     id1p_func_codes_o;
    wire [31:0]     id1p_inst_o;
    wire [4 :0]     id1p_rs_o;
    wire [4 :0]     id1p_rt_o;
    wire [4 :0]     id1p_rd_o;
    wire [4 :0]     id1p_sa_o;
    wire            id1p_w_reg_ena_o;
    wire [4 :0]     id1p_w_reg_dst_o;
    wire [15:0]     id1p_imme_o;
    wire [25:0]     id1p_j_imme_o;
    wire            id1p_is_branch_o;
    wire            id1p_is_j_imme_o;
    wire            id1p_is_jr_o;
    wire            id1p_is_ls_o;
    wire            id1p_in_delay_slot_o;
    wire            id1p_is_inst_adel_o;

    wire            id1p_valid_i;
    wire [31:0]     id1p_pc_i;
    wire [28:0]     id1p_op_codes_i;
    wire [28:0]     id1p_func_codes_i;
    wire [31:0]     id1p_inst_i;
    wire [4 :0]     id1p_rs_i;
    wire [4 :0]     id1p_rt_i;
    wire [4 :0]     id1p_rd_i;
    wire [4 :0]     id1p_sa_i;
    wire            id1p_w_reg_ena_i;
    wire [4 :0]     id1p_w_reg_dst_i;
    wire [15:0]     id1p_imme_i;
    wire [25:0]     id1p_j_imme_i;
    wire            id1p_is_branch_i;
    wire            id1p_is_j_imme_i;
    wire            id1p_is_jr_i;
    wire            id1p_is_ls_i;
    wire            id1p_in_delay_slot_i;
    wire            id1p_is_inst_adel_i;
    
    // id2 => ex   
    wire            id2c_in_delay_slot_o;
    wire            id2c_is_eret_o;
    wire            id2c_is_syscall_o;
    wire            id2c_is_break_o;
    wire            id2c_is_inst_adel_o;
    wire            id2c_is_ri_o;
    wire            id2c_is_check_ov_o;
    wire            id2c_is_branch_o;
    wire            id2c_is_j_imme_o;
    wire            id2c_is_jr_o;
    wire            id2c_is_ls_o;
    wire [3 :0]     id2c_branch_sel_o;
    wire [4 :0]     id2c_rs_o;
    wire [4 :0]     id2c_rt_o;
    wire [4 :0]     id2c_rd_o;
    wire [4 :0]     id2c_w_reg_dst_o;
    wire [4 :0]     id2c_sa_o;
    wire [31:0]     id2c_rs_data_o;
    wire [31:0]     id2c_rt_data_o;
    wire [15:0]     id2c_imme_o;
    wire [25:0]     id2c_j_imme_o;
    wire [31:0]     id2c_ext_imme_o;
    wire [31:0]     id2c_pc_o;
    wire [2 :0]     id2c_src_a_sel_o;
    wire [2 :0]     id2c_src_b_sel_o;
    wire [5 :0]     id2c_alu_sel_o;
    wire [2 :0]     id2c_alu_res_sel_o;
    wire            id2c_w_reg_ena_o;
    wire [1 :0]     id2c_w_hilo_ena_o;
    wire            id2c_w_cp0_ena_o;
    wire [7 :0]     id2c_w_cp0_addr_o;
    wire            id2c_ls_ena_o;
    wire [3 :0]     id2c_ls_sel_o;
    wire            id2c_wb_reg_sel_o;
    wire            id2c_in_delay_slot_i;
    wire            id2c_is_eret_i;
    wire            id2c_is_syscall_i;
    wire            id2c_is_break_i;
    wire            id2c_is_inst_adel_i;
    wire            id2c_is_ri_i;
    wire            id2c_is_check_ov_i;
    wire            id2c_is_branch_i;
    wire            id2c_is_j_imme_i;
    wire            id2c_is_jr_i;
    wire            id2c_is_ls_i;
    wire [3 :0]     id2c_branch_sel_i;
    wire [4 :0]     id2c_rs_i;
    wire [4 :0]     id2c_rt_i;
    wire [4 :0]     id2c_rd_i;
    wire [4 :0]     id2c_w_reg_dst_i;
    wire [4 :0]     id2c_sa_i;
    wire [31:0]     id2c_rs_data_i;
    wire [31:0]     id2c_rt_data_i;
    wire [15:0]     id2c_imme_i;
    wire [25:0]     id2c_j_imme_i;
    wire [31:0]     id2c_ext_imme_i;
    wire [31:0]     id2c_pc_i;
    wire [2 :0]     id2c_src_a_sel_i;
    wire [2 :0]     id2c_src_b_sel_i;
    wire [5 :0]     id2c_alu_sel_i;
    wire [2 :0]     id2c_alu_res_sel_i;
    wire            id2c_w_reg_ena_i;
    wire [1 :0]     id2c_w_hilo_ena_i;
    wire            id2c_w_cp0_ena_i;
    wire [7 :0]     id2c_w_cp0_addr_i;
    wire            id2c_ls_ena_i;
    wire [3 :0]     id2c_ls_sel_i;
    wire            id2c_wb_reg_sel_i;
    wire            id2p_in_delay_slot_o;
    wire            id2p_is_eret_o;
    wire            id2p_is_syscall_o;
    wire            id2p_is_break_o;
    wire            id2p_is_inst_adel_o;
    wire            id2p_is_ri_o;
    wire            id2p_is_check_ov_o;
    wire            id2p_is_branch_o;
    wire            id2p_is_j_imme_o;
    wire            id2p_is_jr_o;
    wire            id2p_is_ls_o;
    wire [4 :0]     id2p_rs_o;
    wire [4 :0]     id2p_rt_o;
    wire [4 :0]     id2p_rd_o;
    wire [4 :0]     id2p_w_reg_dst_o;
    wire [4 :0]     id2p_sa_o;
    wire [31:0]     id2p_rs_data_o;
    wire [31:0]     id2p_rt_data_o;
    wire [15:0]     id2p_imme_o;
    wire [25:0]     id2p_j_imme_o;
    wire [31:0]     id2p_ext_imme_o;
    wire [31:0]     id2p_pc_o;
    wire [2 :0]     id2p_src_a_sel_o;
    wire [2 :0]     id2p_src_b_sel_o;
    wire [5 :0]     id2p_alu_sel_o;
    wire [2 :0]     id2p_alu_res_sel_o;
    wire            id2p_w_reg_ena_o;
    wire [1 :0]     id2p_w_hilo_ena_o;
    wire            id2p_w_cp0_ena_o;
    wire [7 :0]     id2p_w_cp0_addr_o;
    wire            id2p_ls_ena_o;
    wire [3 :0]     id2p_ls_sel_o;
    wire            id2p_wb_reg_sel_o;
    wire            id2p_in_delay_slot_i;
    wire            id2p_is_eret_i;
    wire            id2p_is_syscall_i;
    wire            id2p_is_break_i;
    wire            id2p_is_inst_adel_i;
    wire            id2p_is_ri_i;
    wire            id2p_is_check_ov_i;
    wire            id2p_is_branch_i;
    wire            id2p_is_j_imme_i;
    wire            id2p_is_jr_i;
    wire            id2p_is_ls_i;
    wire [4 :0]     id2p_rs_i;
    wire [4 :0]     id2p_rt_i;
    wire [4 :0]     id2p_rd_i;
    wire [4 :0]     id2p_w_reg_dst_i;
    wire [4 :0]     id2p_sa_i;
    wire [31:0]     id2p_rs_data_i;
    wire [31:0]     id2p_rt_data_i;
    wire [15:0]     id2p_imme_i;
    wire [25:0]     id2p_j_imme_i;
    wire [31:0]     id2p_ext_imme_i;
    wire [31:0]     id2p_pc_i;
    wire [2 :0]     id2p_src_a_sel_i;
    wire [2 :0]     id2p_src_b_sel_i;
    wire [5 :0]     id2p_alu_sel_i;
    wire [2 :0]     id2p_alu_res_sel_i;
    wire            id2p_w_reg_ena_i;
    wire [1 :0]     id2p_w_hilo_ena_i;
    wire            id2p_w_cp0_ena_i;
    wire [7 :0]     id2p_w_cp0_addr_i;
    wire            id2p_ls_ena_i;
    wire [3 :0]     id2p_ls_sel_i;
    wire            id2p_wb_reg_sel_i;
    // wire            id2c_take_branch;
    // wire            id2c_take_j_imme;
    // wire            id2c_take_jr;

    // b_ctrl
    wire            take_branch;
    wire            take_j_imme;
    wire            take_jr;

    // ex => mem
    wire            to_exc_is_data_adel;
    wire            to_exc_is_data_ades;
    wire            exc_has_exception;
    wire            memc_has_exception_i;
    wire            memc_has_exception_o;
    wire            to_exp_is_data_adel;
    wire            to_exp_is_data_ades;
    wire            exp_has_exception;
    wire            memp_has_exception_i;
    wire            memp_has_exception_o;

    wire            exc_in_delay_slot_o;
    wire            exc_is_eret_o;
    wire            exc_is_syscall_o;
    wire            exc_is_break_o;
    wire            exc_is_inst_adel_o;
    wire            exc_is_data_adel_o;
    wire            exc_is_data_ades_o;
    wire            exc_is_overflow_o;
    wire            exc_is_ri_o;
    wire            exc_cp0_w_ena;
    wire [7 :0]     exc_cp0_w_addr;
    wire [31:0]     exc_cp0_w_data;
    wire            exc_cp0_r_ena;
    wire [7 :0]     exc_cp0_r_addr;
    wire [31:0]     cp0_r_data;

    wire [31:0]     exc_alu_res_o;
    wire [31:0]     exc_pc_o;
    wire [1 :0]     exc_w_hilo_ena_o;
    wire [31:0]     exc_hi_res_o;
    wire [31:0]     exc_lo_res_o;
    wire [31:0]     exc_rt_data_o;
    wire            exc_w_reg_ena_o;
    wire [4 :0]     exc_w_reg_dst_o;
    wire            exc_ls_ena_o;
    wire [3 :0]     exc_ls_sel_o;
    wire            exc_wb_reg_sel_o;
    wire            exc_w_cp0_ena_o;
    wire [7 :0]     exc_w_cp0_addr_o;
    wire [31:0]     exc_w_cp0_data_o;
    wire            exc_in_delay_slot_i;
    wire            exc_is_eret_i;
    wire            exc_is_syscall_i;
    wire            exc_is_break_i;
    wire            exc_is_inst_adel_i;
    wire            exc_is_data_adel_i;
    wire            exc_is_data_ades_i;
    wire            exc_is_overflow_i;
    wire            exc_is_ri_i;
    wire [31:0]     exc_pc_i;
    wire [31:0]     exc_alu_res_i;
    wire [1 :0]     exc_w_hilo_ena_i;
    wire [31:0]     exc_hi_res_i;
    wire [31:0]     exc_lo_res_i;
    wire            exc_w_reg_ena_i;
    wire [4 :0]     exc_w_reg_dst_i;
    wire [31:0]     exc_rt_data_i;
    wire            exc_ls_ena_i;
    wire [3 :0]     exc_ls_sel_i;
    wire            exc_wb_reg_sel_i;
    wire            exc_w_cp0_ena_i;
    wire [7 :0]     exc_w_cp0_addr_i;
    wire [31:0]     exc_w_cp0_data_i;

    wire            exp_in_delay_slot_o;
    wire            exp_is_eret_o;
    wire            exp_is_syscall_o;
    wire            exp_is_break_o;
    wire            exp_is_inst_adel_o;
    wire            exp_is_data_adel_o;
    wire            exp_is_data_ades_o;
    wire            exp_is_overflow_o;
    wire            exp_is_ri_o;
    wire [31:0]     exp_pc_o;
    wire [31:0]     exp_alu_res_o;
    wire            exp_w_reg_ena_o;
    wire [4 :0]     exp_w_reg_dst_o;
    wire            exp_wb_reg_sel_o;
    wire            exp_ls_ena_o;
    wire [3 :0]     exp_ls_sel_o;
    wire [31:0]     exp_rt_data_o;
    wire [1 :0]     exp_w_hilo_ena_o;
    wire [31:0]     exp_hi_res_o;
    wire [31:0]     exp_lo_res_o;
    wire            exp_w_cp0_ena_o;
    wire [7 :0]     exp_w_cp0_addr_o;
    wire [31:0]     exp_w_cp0_data_o;
    wire            exp_cp0_r_ena;
    wire [7 :0]     exp_cp0_r_addr;
    wire            exp_in_delay_slot_i;
    wire            exp_is_eret_i;
    wire            exp_is_syscall_i;
    wire            exp_is_break_i;
    wire            exp_is_inst_adel_i;
    wire            exp_is_data_adel_i;
    wire            exp_is_data_ades_i;
    wire            exp_is_overflow_i;
    wire            exp_is_ri_i;
    wire [31:0]     exp_pc_i;
    wire [31:0]     exp_alu_res_i;
    wire            exp_w_reg_ena_i;
    wire [4 :0]     exp_w_reg_dst_i;
    wire            exp_wb_reg_sel_i;
    wire            exp_ls_ena_i;
    wire [31:0]     exp_rt_data_i;
    wire [3 :0]     exp_ls_sel_i;
    wire [1 :0]     exp_w_hilo_ena_i;
    wire [31:0]     exp_hi_res_i;
    wire [31:0]     exp_lo_res_i;
    wire            exp_w_cp0_ena_i;
    wire [7 :0]     exp_w_cp0_addr_i;
    wire [31:0]     exp_w_cp0_data_i;

    // mem => wb
    wire [31:0]     memc_alu_res_o;
    wire            memc_w_reg_ena_o;
    wire [4 :0]     memc_w_reg_dst_o;
    wire [31:0]     memc_r_data_o;
    wire            memc_wb_reg_sel_o;
    wire [1 :0]     memc_w_hilo_ena_o;
    wire [31:0]     memc_pc_o;
    wire [31:0]     memc_hi_res_o;
    wire [31:0]     memc_lo_res_o;
    wire            memc_w_cp0_ena_o;
    wire [7 :0]     memc_w_cp0_addr_o;
    wire [31:0]     memc_w_cp0_data_o;
    wire            memc_in_delay_slot_o;
    wire            memc_is_eret_o;
    wire            memc_is_syscall_o;
    wire            memc_is_break_o;
    wire            memc_is_inst_adel_o;
    wire            memc_is_data_adel_o;
    wire            memc_is_data_ades_o;
    wire            memc_is_overflow_o;
    wire            memc_is_ri_o;
    wire [31:0]     memc_alu_res_i;
    wire            memc_w_reg_ena_i;
    wire [4 :0]     memc_w_reg_dst_i;
    wire [31:0]     memc_r_data_i;
    wire            memc_wb_reg_sel_i;
    wire [1 :0]     memc_w_hilo_ena_i;
    wire [31:0]     memc_hi_res_i;
    wire [31:0]     memc_lo_res_i;
    wire [31:0]     memc_pc_i;
    wire [31:0]     memp_alu_res_o;
    wire            memp_w_reg_ena_o;
    wire [4 :0]     memp_w_reg_dst_o;
    wire [31:0]     memp_r_data_o;
    wire            memp_wb_reg_sel_o;
    wire [31:0]     memp_pc_o;
    wire [1 :0]     memp_w_hilo_ena_o;
    wire [31:0]     memp_hi_res_o;
    wire [31:0]     memp_lo_res_o;
    wire            memp_in_delay_slot_o;
    wire            memp_is_eret_o;
    wire            memp_is_syscall_o;
    wire            memp_is_break_o;
    wire            memp_is_inst_adel_o;
    wire            memp_is_data_adel_o;
    wire            memp_is_data_ades_o;
    wire            memp_is_overflow_o;
    wire            memp_is_ri_o;
    wire            memp_w_cp0_ena_o;
    wire [7 :0]     memp_w_cp0_addr_o;
    wire [31:0]     memp_w_cp0_data_o;
    wire [31:0]     memp_alu_res_i;
    wire            memp_w_reg_ena_i;
    wire [4 :0]     memp_w_reg_dst_i;
    wire [31:0]     memp_r_data_i;
    wire            memp_wb_reg_sel_i;
    wire [31:0]     memp_pc_i;
    wire [1 :0]     memp_w_hilo_ena_i;
    wire [31:0]     memp_hi_res_i;
    wire [31:0]     memp_lo_res_i;

    wire            memc_data_ena;
    wire [3 :0]     memc_data_wea;
    wire [31:0]     memc_data_waddr;
    wire [31:0]     memc_data_wdata;
    wire [31:0]     memc_data_rdata;
    wire            memp_data_ena;
    wire [3 :0]     memp_data_wea;
    wire [31:0]     memp_data_waddr;
    wire [31:0]     memp_data_wdata;
    wire [31:0]     memp_data_rdata;

    wire            exception_pc_ena;
    wire [31:0]     exception_pc;
    wire            w_cp0_update_ena;
    wire [4 :0]     w_cp0_exccode;
    wire            w_cp0_bd;
    wire            w_cp0_exl;
    wire [31:0]     w_cp0_epc;
    wire            w_cp0_badvaddr_ena;
    wire [31:0]     w_cp0_badvaddr;
    wire            cp0_cls_exl;
    wire            exception_flush;
    wire [31:0]     cp0_epc;

    issue_id2 issue_id2c (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (ii_id2_flush       ),
        .exception_flush    (ii_id2_exception_flush),
        .stall              (ii_id2_stall       ),

        .id1_valid_o        (id1c_valid_o       ),

        .id1_op_codes_o     (id1c_op_codes_o    ),
        .id1_func_codes_o   (id1c_func_codes_o  ),
        .id1_pc_o           (id1c_pc_o          ),
        .id1_inst_o         (id1c_inst_o        ),
        .id1_rs_o           (id1c_rs_o          ),
        .id1_rt_o           (id1c_rt_o          ),
        .id1_rd_o           (id1c_rd_o          ),
        .id1_sa_o           (id1c_sa_o          ),
        .id1_w_reg_ena_o    (id1c_w_reg_ena_o   ),
        .id1_w_reg_dst_o    (id1c_w_reg_dst_o   ),
        .id1_imme_o         (id1c_imme_o        ),
        .id1_j_imme_o       (id1c_j_imme_o      ),
        .id1_is_branch_o    (id1c_is_branch_o   ),
        .id1_is_j_imme_o    (id1c_is_j_imme_o   ),
        .id1_is_jr_o        (id1c_is_jr_o       ),
        .id1_is_ls_o        (id1c_is_ls_o       ),
        .id1_in_delay_slot_o(id1c_in_delay_slot_o),
        .id1_is_inst_adel_o (id1c_is_inst_adel_o),

        .id1_valid_i        (id1c_valid_i       ),
        .id1_op_codes_i     (id1c_op_codes_i    ),
        .id1_func_codes_i   (id1c_func_codes_i  ),
        .id1_pc_i           (id1c_pc_i          ),
        .id1_inst_i         (id1c_inst_i        ),
        .id1_rs_i           (id1c_rs_i          ),
        .id1_rt_i           (id1c_rt_i          ),
        .id1_rd_i           (id1c_rd_i          ),
        .id1_sa_i           (id1c_sa_i          ),
        .id1_w_reg_ena_i    (id1c_w_reg_ena_i   ),
        .id1_w_reg_dst_i    (id1c_w_reg_dst_i   ),
        .id1_imme_i         (id1c_imme_i        ),
        .id1_j_imme_i       (id1c_j_imme_i      ),
        .id1_is_branch_i    (id1c_is_branch_i   ),
        .id1_is_j_imme_i    (id1c_is_j_imme_i   ),
        .id1_is_jr_i        (id1c_is_jr_i       ),
        .id1_is_ls_i        (id1c_is_ls_i       ),
        .id1_in_delay_slot_i(id1c_in_delay_slot_i),
        .id1_is_inst_adel_i (id1c_is_inst_adel_i)
    );

    issue_id2 issue_id2p (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (ii_id2_flush       ),
        .exception_flush    (ii_id2_exception_flush),
        .stall              (ii_id2_stall       ),

        .id1_valid_o        (id1p_valid_o       ),

        .id1_op_codes_o     (id1p_op_codes_o    ),
        .id1_func_codes_o   (id1p_func_codes_o  ),
        .id1_pc_o           (id1p_pc_o          ),
        .id1_inst_o         (id1p_inst_o        ),
        .id1_rs_o           (id1p_rs_o          ),
        .id1_rt_o           (id1p_rt_o          ),
        .id1_rd_o           (id1p_rd_o          ),
        .id1_sa_o           (id1p_sa_o          ),
        .id1_w_reg_ena_o    (id1p_w_reg_ena_o   ),
        .id1_w_reg_dst_o    (id1p_w_reg_dst_o   ),
        .id1_imme_o         (id1p_imme_o        ),
        .id1_j_imme_o       (id1p_j_imme_o      ),
        .id1_is_branch_o    (id1p_is_branch_o   ),
        .id1_is_j_imme_o    (id1p_is_j_imme_o   ),
        .id1_is_jr_o        (id1p_is_jr_o       ),
        .id1_is_ls_o        (id1p_is_ls_o       ),
        .id1_in_delay_slot_o(id1p_in_delay_slot_o),
        .id1_is_inst_adel_o (id1p_is_inst_adel_o),

        .id1_valid_i        (id1p_valid_i       ),
        .id1_op_codes_i     (id1p_op_codes_i    ),
        .id1_func_codes_i   (id1p_func_codes_i  ),
        .id1_pc_i           (id1p_pc_i          ),
        .id1_inst_i         (id1p_inst_i        ),
        .id1_rs_i           (id1p_rs_i          ),
        .id1_rt_i           (id1p_rt_i          ),
        .id1_rd_i           (id1p_rd_i          ),
        .id1_sa_i           (id1p_sa_i          ),
        .id1_w_reg_ena_i    (id1p_w_reg_ena_i   ),
        .id1_w_reg_dst_i    (id1p_w_reg_dst_i   ),
        .id1_imme_i         (id1p_imme_i        ),
        .id1_j_imme_i       (id1p_j_imme_i      ),
        .id1_is_branch_i    (id1p_is_branch_i   ),
        .id1_is_j_imme_i    (id1p_is_j_imme_i   ),
        .id1_is_jr_i        (id1p_is_jr_i       ),
        .id1_is_ls_i        (id1p_is_ls_i       ),
        .id1_in_delay_slot_i(id1p_in_delay_slot_i),
        .id1_is_inst_adel_i (id1p_is_inst_adel_i)
    );

    id2_ex id2_exc (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (id2_ex_flush       ),
        .exception_flush    (id2_ex_exception_flush),
        .stall              (id2_ex_stall       ),

        .id2_in_delay_slot_o(id2c_in_delay_slot_o),
        .id2_is_eret_o      (id2c_is_eret_o     ),
        .id2_is_syscall_o   (id2c_is_syscall_o  ),
        .id2_is_break_o     (id2c_is_break_o    ),
        .id2_is_inst_adel_o (id2c_is_inst_adel_o),
        .id2_is_ri_o        (id2c_is_ri_o       ),
        .id2_is_int_o       (id2c_is_int_o      ),
        .id2_is_check_ov_o  (id2c_is_check_ov_o ),

        .id2_is_branch_o    (id2c_is_branch_o   ),
        .id2_is_j_imme_o    (id2c_is_j_imme_o   ),
        .id2_is_jr_o        (id2c_is_jr_o       ),
        .id2_is_ls_o        (id2c_is_ls_o       ),
        .id2_branch_sel_o   (id2c_branch_sel_o  ),
        .id2_rs_o           (id2c_rs_o          ),
        .id2_rt_o           (id2c_rt_o          ),
        .id2_rd_o           (id2c_rd_o          ),
        .id2_w_reg_dst_o    (id2c_w_reg_dst_o   ),
        .id2_sa_o           (id2c_sa_o          ),
        .id2_rs_data_o      (id2c_rs_data_o     ),
        .id2_rt_data_o      (id2c_rt_data_o     ),
        .id2_imme_o         (id2c_imme_o        ),
        .id2_j_imme_o       (id2c_j_imme_o      ),
        .id2_ext_imme_o     (id2c_ext_imme_o    ),
        .id2_pc_o           (id2c_pc_o          ),
        .id2_src_a_sel_o    (id2c_src_a_sel_o   ),
        .id2_src_b_sel_o    (id2c_src_b_sel_o   ),
        .id2_alu_sel_o      (id2c_alu_sel_o     ),
        .id2_alu_res_sel_o  (id2c_alu_res_sel_o ),
        .id2_w_reg_ena_o    (id2c_w_reg_ena_o   ),
        .id2_w_hilo_ena_o   (id2c_w_hilo_ena_o  ),
        .id2_w_cp0_ena_o    (id2c_w_cp0_ena_o   ),
        .id2_w_cp0_addr_o   (id2c_w_cp0_addr_o  ),
        .id2_ls_ena_o       (id2c_ls_ena_o      ),
        .id2_ls_sel_o       (id2c_ls_sel_o      ),
        .id2_wb_reg_sel_o   (id2c_wb_reg_sel_o  ),

        .id2_in_delay_slot_i(id2c_in_delay_slot_i),
        .id2_is_eret_i      (id2c_is_eret_i     ),
        .id2_is_syscall_i   (id2c_is_syscall_i  ),
        .id2_is_break_i     (id2c_is_break_i    ),
        .id2_is_inst_adel_i (id2c_is_inst_adel_i),
        .id2_is_ri_i        (id2c_is_ri_i       ),
        .id2_is_int_i       (id2c_is_int_i      ),
        .id2_is_check_ov_i  (id2c_is_check_ov_i ),

        .id2_is_branch_i    (id2c_is_branch_i   ),
        .id2_is_j_imme_i    (id2c_is_j_imme_i   ),
        .id2_is_jr_i        (id2c_is_jr_i       ),
        .id2_is_ls_i        (id2c_is_ls_i       ),
        .id2_branch_sel_i   (id2c_branch_sel_i  ),
        .id2_rs_i           (id2c_rs_i          ),
        .id2_rt_i           (id2c_rt_i          ),
        .id2_rd_i           (id2c_rd_i          ),
        .id2_w_reg_dst_i    (id2c_w_reg_dst_i   ),
        .id2_sa_i           (id2c_sa_i          ),
        .id2_rs_data_i      (id2c_rs_data_i     ),
        .id2_rt_data_i      (id2c_rt_data_i     ),
        .id2_imme_i         (id2c_imme_i        ),
        .id2_j_imme_i       (id2c_j_imme_i      ),
        .id2_ext_imme_i     (id2c_ext_imme_i    ),
        .id2_pc_i           (id2c_pc_i          ),
        .id2_src_a_sel_i    (id2c_src_a_sel_i   ),
        .id2_src_b_sel_i    (id2c_src_b_sel_i   ),
        .id2_alu_sel_i      (id2c_alu_sel_i     ),
        .id2_alu_res_sel_i  (id2c_alu_res_sel_i ),
        .id2_w_reg_ena_i    (id2c_w_reg_ena_i   ),
        .id2_w_hilo_ena_i   (id2c_w_hilo_ena_i  ),
        .id2_w_cp0_ena_i    (id2c_w_cp0_ena_i   ),
        .id2_w_cp0_addr_i   (id2c_w_cp0_addr_i  ),
        .id2_ls_ena_i       (id2c_ls_ena_i      ),
        .id2_ls_sel_i       (id2c_ls_sel_i      ),
        .id2_wb_reg_sel_i   (id2c_wb_reg_sel_i  )
    );

    id2_ex id2_exp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (id2_ex_flush       ),
        .exception_flush    (id2_ex_exception_flush),
        .stall              (id2_ex_stall       ),

        .id2_in_delay_slot_o(id2p_in_delay_slot_o),
        .id2_is_eret_o      (id2p_is_eret_o     ),
        .id2_is_syscall_o   (id2p_is_syscall_o  ),
        .id2_is_break_o     (id2p_is_break_o    ),
        .id2_is_inst_adel_o (id2p_is_inst_adel_o),
        .id2_is_ri_o        (id2p_is_ri_o       ),
        .id2_is_int_o       (id2p_is_int_o      ),
        .id2_is_check_ov_o  (id2p_is_check_ov_o ),

        .id2_is_branch_o    (id2p_is_branch_o   ),
        .id2_is_j_imme_o    (id2p_is_j_imme_o   ),
        .id2_is_jr_o        (id2p_is_jr_o       ),
        .id2_is_ls_o        (id2p_is_ls_o       ),
        .id2_rs_o           (id2p_rs_o          ),
        .id2_rt_o           (id2p_rt_o          ),
        .id2_rd_o           (id2p_rd_o          ),
        .id2_w_reg_dst_o    (id2p_w_reg_dst_o   ),
        .id2_sa_o           (id2p_sa_o          ),
        .id2_rs_data_o      (id2p_rs_data_o     ),
        .id2_rt_data_o      (id2p_rt_data_o     ),
        .id2_imme_o         (id2p_imme_o        ),
        .id2_j_imme_o       (id2p_j_imme_o      ),
        .id2_ext_imme_o     (id2p_ext_imme_o    ),
        .id2_pc_o           (id2p_pc_o          ),
        .id2_src_a_sel_o    (id2p_src_a_sel_o   ),
        .id2_src_b_sel_o    (id2p_src_b_sel_o   ),
        .id2_alu_sel_o      (id2p_alu_sel_o     ),
        .id2_alu_res_sel_o  (id2p_alu_res_sel_o ),
        .id2_w_reg_ena_o    (id2p_w_reg_ena_o   ),
        .id2_w_hilo_ena_o   (id2p_w_hilo_ena_o  ),
        .id2_w_cp0_ena_o    (id2p_w_cp0_ena_o   ),
        .id2_w_cp0_addr_o   (id2p_w_cp0_addr_o  ),
        .id2_ls_ena_o       (id2p_ls_ena_o      ),
        .id2_ls_sel_o       (id2p_ls_sel_o      ),
        .id2_wb_reg_sel_o   (id2p_wb_reg_sel_o  ),

        .id2_in_delay_slot_i(id2p_in_delay_slot_i),
        .id2_is_eret_i      (id2p_is_eret_i     ),
        .id2_is_syscall_i   (id2p_is_syscall_i  ),
        .id2_is_break_i     (id2p_is_break_i    ),
        .id2_is_inst_adel_i (id2p_is_inst_adel_i),
        .id2_is_ri_i        (id2p_is_ri_i       ),
        .id2_is_int_i       (id2p_is_int_i      ),
        .id2_is_check_ov_i  (id2p_is_check_ov_i ),

        .id2_is_branch_i    (id2p_is_branch_i   ),
        .id2_is_j_imme_i    (id2p_is_j_imme_i   ),
        .id2_is_jr_i        (id2p_is_jr_i       ),
        .id2_is_ls_i        (id2p_is_ls_i       ),
        .id2_rs_i           (id2p_rs_i          ),
        .id2_rt_i           (id2p_rt_i          ),
        .id2_rd_i           (id2p_rd_i          ),
        .id2_w_reg_dst_i    (id2p_w_reg_dst_i   ),
        .id2_sa_i           (id2p_sa_i          ),
        .id2_rs_data_i      (id2p_rs_data_i     ),
        .id2_rt_data_i      (id2p_rt_data_i     ),
        .id2_imme_i         (id2p_imme_i        ),
        .id2_j_imme_i       (id2p_j_imme_i      ),
        .id2_ext_imme_i     (id2p_ext_imme_i    ),
        .id2_pc_i           (id2p_pc_i          ),
        .id2_src_a_sel_i    (id2p_src_a_sel_i   ),
        .id2_src_b_sel_i    (id2p_src_b_sel_i   ),
        .id2_alu_sel_i      (id2p_alu_sel_i     ),
        .id2_alu_res_sel_i  (id2p_alu_res_sel_i ),
        .id2_w_reg_ena_i    (id2p_w_reg_ena_i   ),
        .id2_w_hilo_ena_i   (id2p_w_hilo_ena_i  ),
        .id2_w_cp0_ena_i    (id2p_w_cp0_ena_i   ),
        .id2_w_cp0_addr_i   (id2p_w_cp0_addr_i  ),
        .id2_ls_ena_i       (id2p_ls_ena_i      ),
        .id2_ls_sel_i       (id2p_ls_sel_i      ),
        .id2_wb_reg_sel_i   (id2p_wb_reg_sel_i  )
    );

    ex_mem ex_memc (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (ex_mem_flush       ),
        .exception_flush    (ex_mem_exception_flush),
        .stall              (ex_mem_stall       ),
        .ex_pc_o            (exc_pc_o           ),
        .ex_alu_res_o       (exc_alu_res_o      ),
        .ex_w_hilo_ena_o    (exc_w_hilo_ena_o   ),
        .ex_hi_res_o        (exc_hi_res_o       ),
        .ex_lo_res_o        (exc_lo_res_o       ),

        .ex_in_delay_slot_o (exc_in_delay_slot_o),
        .ex_is_eret_o       (exc_is_eret_o      ),
        .ex_is_syscall_o    (exc_is_syscall_o   ),
        .ex_is_break_o      (exc_is_break_o     ),
        .ex_is_inst_adel_o  (exc_is_inst_adel_o ),
        .ex_is_data_adel_o  (exc_is_data_adel_o ),
        .ex_is_data_ades_o  (exc_is_data_ades_o ),
        .ex_is_overflow_o   (exc_is_overflow_o  ),
        .ex_is_ri_o         (exc_is_ri_o        ),
        .ex_is_int_o        (exc_is_int_o       ),

        .ex_w_reg_ena_o     (exc_w_reg_ena_o    ),
        .ex_w_reg_dst_o     (exc_w_reg_dst_o    ),
        .ex_ls_ena_o        (exc_ls_ena_o       ),
        .ex_ls_sel_o        (exc_ls_sel_o       ),
        .ex_wb_reg_sel_o    (exc_wb_reg_sel_o   ),
        .ex_rt_data_o       (exc_rt_data_o      ),
        .ex_w_cp0_ena_o     (exc_w_cp0_ena_o    ),
        .ex_w_cp0_addr_o    (exc_w_cp0_addr_o   ),
        .ex_w_cp0_data_o    (exc_w_cp0_data_o   ),
        .ex_pc_i            (exc_pc_i           ),
        .ex_alu_res_i       (exc_alu_res_i      ),
        .ex_w_hilo_ena_i    (exc_w_hilo_ena_i   ),
        .ex_hi_res_i        (exc_hi_res_i       ),
        .ex_lo_res_i        (exc_lo_res_i       ),

        .ex_in_delay_slot_i (exc_in_delay_slot_i),
        .ex_is_eret_i       (exc_is_eret_i      ),
        .ex_is_syscall_i    (exc_is_syscall_i   ),
        .ex_is_break_i      (exc_is_break_i     ),
        .ex_is_inst_adel_i  (exc_is_inst_adel_i ),
        .ex_is_data_adel_i  (exc_is_data_adel_i ),
        .ex_is_data_ades_i  (exc_is_data_ades_i ),
        .ex_is_overflow_i   (exc_is_overflow_i  ),
        .ex_is_ri_i         (exc_is_ri_i        ),
        .ex_is_int_i        (exc_is_int_i       ),

        .ex_w_reg_ena_i     (exc_w_reg_ena_i    ),
        .ex_w_reg_dst_i     (exc_w_reg_dst_i    ),
        .ex_ls_ena_i        (exc_ls_ena_i       ),
        .ex_ls_sel_i        (exc_ls_sel_i       ),
        .ex_wb_reg_sel_i    (exc_wb_reg_sel_i   ),
        .ex_rt_data_i       (exc_rt_data_i      ),
        .ex_w_cp0_ena_i     (exc_w_cp0_ena_i    ),
        .ex_w_cp0_addr_i    (exc_w_cp0_addr_i   ),
        .ex_w_cp0_data_i    (exc_w_cp0_data_i   )
    );

    ex_mem ex_memp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (ex_mem_flush       ),
        .exception_flush    (ex_mem_exception_flush),
        .stall              (ex_mem_stall       ),
        .ex_pc_o            (exp_pc_o           ),
        .ex_alu_res_o       (exp_alu_res_o      ),
        .ex_w_hilo_ena_o    (exp_w_hilo_ena_o   ),
        .ex_hi_res_o        (exp_hi_res_o       ),
        .ex_lo_res_o        (exp_lo_res_o       ),

        .ex_in_delay_slot_o (exp_in_delay_slot_o),
        .ex_is_eret_o       (exp_is_eret_o      ),
        .ex_is_syscall_o    (exp_is_syscall_o   ),
        .ex_is_break_o      (exp_is_break_o     ),
        .ex_is_inst_adel_o  (exp_is_inst_adel_o ),
        .ex_is_data_adel_o  (exp_is_data_adel_o ),
        .ex_is_data_ades_o  (exp_is_data_ades_o ),
        .ex_is_overflow_o   (exp_is_overflow_o  ),
        .ex_is_ri_o         (exp_is_ri_o        ),
        .ex_is_int_o        (exp_is_int_o       ),

        .ex_w_reg_ena_o     (exp_w_reg_ena_o    ),
        .ex_w_reg_dst_o     (exp_w_reg_dst_o    ),
        .ex_ls_ena_o        (exp_ls_ena_o       ),
        .ex_ls_sel_o        (exp_ls_sel_o       ),
        .ex_wb_reg_sel_o    (exp_wb_reg_sel_o   ),
        .ex_rt_data_o       (exp_rt_data_o      ),
        .ex_w_cp0_ena_o     (exp_w_cp0_ena_o    ),
        .ex_w_cp0_addr_o    (exp_w_cp0_addr_o   ),
        .ex_w_cp0_data_o    (exp_w_cp0_data_o   ),
        .ex_pc_i            (exp_pc_i           ),
        .ex_alu_res_i       (exp_alu_res_i      ),
        .ex_w_hilo_ena_i    (exp_w_hilo_ena_i   ),
        .ex_hi_res_i        (exp_hi_res_i       ),
        .ex_lo_res_i        (exp_lo_res_i       ),

        .ex_in_delay_slot_i (exp_in_delay_slot_i),
        .ex_is_eret_i       (exp_is_eret_i      ),
        .ex_is_syscall_i    (exp_is_syscall_i   ),
        .ex_is_break_i      (exp_is_break_i     ),
        .ex_is_inst_adel_i  (exp_is_inst_adel_i ),
        .ex_is_data_adel_i  (exp_is_data_adel_i ),
        .ex_is_data_ades_i  (exp_is_data_ades_i ),
        .ex_is_overflow_i   (exp_is_overflow_i  ),
        .ex_is_ri_i         (exp_is_ri_i        ),
        .ex_is_int_i        (exp_is_int_i       ),

        .ex_w_reg_ena_i     (exp_w_reg_ena_i    ),
        .ex_w_reg_dst_i     (exp_w_reg_dst_i    ),
        .ex_ls_ena_i        (exp_ls_ena_i       ),
        .ex_ls_sel_i        (exp_ls_sel_i       ),
        .ex_wb_reg_sel_i    (exp_wb_reg_sel_i   ),
        .ex_rt_data_i       (exp_rt_data_i      ),
        .ex_w_cp0_ena_i     (exp_w_cp0_ena_i    ),
        .ex_w_cp0_addr_i    (exp_w_cp0_addr_i   ),
        .ex_w_cp0_data_i    (exp_w_cp0_data_i   )
    );

    mem_wb mem_wbc (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (mem_wb_flush       ),
        .exception_flush    (mem_wb_exception_flush),
        .stall              (mem_wb_stall       ),
        .mem_has_exception_o(memc_has_exception_o),
        .mem_pc_o           (memc_pc_o          ),
        .mem_alu_res_o      (memc_alu_res_o     ),
        .mem_w_reg_ena_o    (memc_w_reg_ena_o   ),
        .mem_w_reg_dst_o    (memc_w_reg_dst_o   ),
        .mem_r_data_o       (memc_r_data_o      ),
        .mem_wb_reg_sel_o   (memc_wb_reg_sel_o  ),
        .mem_w_hilo_ena_o   (memc_w_hilo_ena_o  ),    
        .mem_hi_res_o       (memc_hi_res_o      ),
        .mem_lo_res_o       (memc_lo_res_o      ),
        .mem_has_exception_i(memc_has_exception_i),
        .mem_pc_i           (memc_pc_i          ),
        .mem_alu_res_i      (memc_alu_res_i     ),
        .mem_w_reg_ena_i    (memc_w_reg_ena_i   ),
        .mem_w_reg_dst_i    (memc_w_reg_dst_i   ),
        .mem_r_data_i       (memc_r_data_i      ),
        .mem_wb_reg_sel_i   (memc_wb_reg_sel_i  ),
        .mem_w_hilo_ena_i   (memc_w_hilo_ena_i  ),    
        .mem_hi_res_i       (memc_hi_res_i      ),
        .mem_lo_res_i       (memc_lo_res_i      )
    );

    mem_wb mem_wbp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (mem_wb_flush       ),
        .exception_flush    (mem_wb_exception_flush),
        .stall              (mem_wb_stall       ),
        .mem_has_exception_o(memp_has_exception_o),
        .mem_pc_o           (memp_pc_o          ),
        .mem_alu_res_o      (memp_alu_res_o     ),        
        .mem_w_reg_ena_o    (memp_w_reg_ena_o   ),            
        .mem_w_reg_dst_o    (memp_w_reg_dst_o   ),            
        .mem_r_data_o       (memp_r_data_o      ),        
        .mem_wb_reg_sel_o   (memp_wb_reg_sel_o  ),
        .mem_w_hilo_ena_o   (memp_w_hilo_ena_o  ),    
        .mem_hi_res_o       (memp_hi_res_o      ),
        .mem_lo_res_o       (memp_lo_res_o      ),
        .mem_has_exception_i(memp_has_exception_i),        
        .mem_pc_i           (memp_pc_i          ),
        .mem_alu_res_i      (memp_alu_res_i     ),
        .mem_w_reg_ena_i    (memp_w_reg_ena_i   ),
        .mem_w_reg_dst_i    (memp_w_reg_dst_i   ),
        .mem_r_data_i       (memp_r_data_i      ),
        .mem_wb_reg_sel_i   (memp_wb_reg_sel_i  ),
        .mem_w_hilo_ena_i   (memp_w_hilo_ena_i  ),    
        .mem_hi_res_i       (memp_hi_res_i      ),
        .mem_lo_res_i       (memp_lo_res_i      )
    );
    
    // 

    npc npc_cp (
        .id_take_j_imme     (take_j_imme        ),
        .id_j_imme          (id2c_j_imme_i      ),
        .id_take_branch     (take_branch        ),
        .id_branch_offset   (id2c_imme_i        ),
        .id_take_jr         (take_jr            ),
        .id_rs_data         (id2c_rs_data_i     ),
        .exception_pc_ena   (exception_pc_ena   ),
        .exception_pc       (exception_pc       ),
        .id_pc              (id2c_pc_i          ),
        .pc                 (pc_cur_pc          ),
        .inst_rdata_1_ok    (inst_rdata_1_ok    ),
        .inst_rdata_2_ok    (inst_rdata_2_ok    ),
        .next_pc            (npc_next_pc        )
    );

    assign inst_ena             = ~(rst | pc_stall);
    assign inst_addr_next_pc    = npc_next_pc;
    assign inst_addr_pc         = pc_cur_pc;
    // assign inst_addr_2          = npc_next_pc + 32'h4;

    pc pc_cp (
        .clk                (clk                ),
        .rst                (rst                ),
        .stall              (pc_stall           ),
        .flush              (pc_flush           ),
        .exception_pc_ena   (exception_pc_ena   ),
        .next_pc            (npc_next_pc        ),
        .pc                 (pc_cur_pc          )
    );

    assign fifo_w_data_1    = 
            {64{inst_rdata_1_ok}} & {pc_cur_pc        , inst_rdata_1};
    assign fifo_w_data_2    = 
            {64{inst_rdata_2_ok}} & {pc_cur_pc + 32'h4, inst_rdata_2};

    i_fifo i_fifo_cp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (fifo_flush         ),
        .p_data_1           (p_data_1           ),
        .p_data_2           (p_data_2           ),
        .r_data_1           (fifo_r_data_1      ),
        .r_data_2           (fifo_r_data_2      ),
        .r_data_1_ok        (fifo_r_data_1_ok   ),
        .r_data_2_ok        (fifo_r_data_2_ok   ),
        .fifo_stall_req     (fifo_stall_req     ),
        .w_ena_1            (inst_rdata_1_ok & ~pc_stall),
        .w_ena_2            (inst_rdata_2_ok & ~pc_stall),
        .w_data_1           (fifo_w_data_1      ),
        .w_data_2           (fifo_w_data_2      ) 
    );

    issue issue_inst (
        .clk                (clk                ),
        .rst                (rst                ),
        .stall              (issue_stall        ),

        .fifo_r_data_1      (fifo_r_data_1      ),
        .fifo_r_data_1_ok   (fifo_r_data_1_ok   ),
        .fifo_r_data_2      (fifo_r_data_2      ),
        .fifo_r_data_2_ok   (fifo_r_data_2_ok   ),

        .p_data_1           (p_data_1           ),
        .p_data_2           (p_data_2           ),

        .id1_valid_1        (id1c_valid_o       ),
        .id1_op_codes_1     (id1c_op_codes_o    ),
        .id1_func_codes_1   (id1c_func_codes_o  ),
        .id1_pc_1           (id1c_pc_o          ),
        .id1_inst_1         (id1c_inst_o        ),
        .id1_rs_1           (id1c_rs_o          ),
        .id1_rt_1           (id1c_rt_o          ),
        .id1_rd_1           (id1c_rd_o          ),
        .id1_sa_1           (id1c_sa_o          ),
        .id1_w_reg_ena_1    (id1c_w_reg_ena_o   ),
        .id1_w_reg_dst_1    (id1c_w_reg_dst_o   ),
        .id1_imme_1         (id1c_imme_o        ),
        .id1_j_imme_1       (id1c_j_imme_o      ),
        .id1_is_branch_1    (id1c_is_branch_o   ),
        .id1_is_j_imme_1    (id1c_is_j_imme_o   ),
        .id1_is_jr_1        (id1c_is_jr_o       ),
        .id1_is_ls_1        (id1c_is_ls_o       ),
        .id1_in_delay_slot_1(id1c_in_delay_slot_o),
        .id1_is_inst_adel_1 (id1c_is_inst_adel_o),

        .id1_valid_2        (id1p_valid_o       ),
        .id1_op_codes_2     (id1p_op_codes_o    ),
        .id1_func_codes_2   (id1p_func_codes_o  ),
        .id1_pc_2           (id1p_pc_o          ),
        .id1_inst_2         (id1p_inst_o        ),
        .id1_rs_2           (id1p_rs_o          ),
        .id1_rt_2           (id1p_rt_o          ),
        .id1_rd_2           (id1p_rd_o          ),
        .id1_sa_2           (id1p_sa_o          ),
        .id1_w_reg_ena_2    (id1p_w_reg_ena_o   ),
        .id1_w_reg_dst_2    (id1p_w_reg_dst_o   ),
        .id1_imme_2         (id1p_imme_o        ),
        .id1_j_imme_2       (id1p_j_imme_o      ),
        .id1_is_branch_2    (id1p_is_branch_o   ),
        .id1_is_j_imme_2    (id1p_is_j_imme_o   ),
        .id1_is_jr_2        (id1p_is_jr_o       ),
        .id1_is_ls_2        (id1p_is_ls_o       ),
        .id1_in_delay_slot_2(id1p_in_delay_slot_o),
        .id1_is_inst_adel_2 (id1p_is_inst_adel_o)
    );

    forward forward_c (
        .id_rs              (id2c_rs_o          ),
        .id_rt              (id2c_rt_o          ),
        .ex_w_reg_ena_1     (id2c_w_reg_ena_i   ),
        .ex_w_reg_dst_1     (id2c_w_reg_dst_i   ),
        .ex_ls_ena_1        (id2c_ls_ena_i      ),
        .ex_w_reg_ena_2     (id2p_w_reg_ena_i   ),
        .ex_w_reg_dst_2     (id2p_w_reg_dst_i   ),
        .ex_ls_ena_2        (id2p_ls_ena_i      ),
        .mem_w_reg_ena_1    (exc_w_reg_ena_i    ),
        .mem_w_reg_dst_1    (exc_w_reg_dst_i    ),
        .mem_ls_ena_1       (exc_ls_ena_i       ),
        .mem_w_reg_ena_2    (exp_w_reg_ena_i    ),
        .mem_w_reg_dst_2    (exp_w_reg_dst_i    ),
        .mem_ls_ena_2       (exp_ls_ena_i       ),

        .ex_mem_w_hilo_ena_1(exc_w_hilo_ena_i   ),
        .ex_mem_w_hilo_ena_2(exp_w_hilo_ena_i   ),

        .forward_rs         (forwardc_rs        ),
        .forward_rt         (forwardc_rt        ),
        .forward_hi         (forwardc_hi        ),
        .forward_lo         (forwardc_lo        ),

        .forward_stall_req  (forwardc_stall_req ),
        .forward_flush_req  (forwardc_flush_req )
    );

    forward forward_p (
        .id_rs              (id2p_rs_o          ),
        .id_rt              (id2p_rt_o          ),
        .ex_w_reg_ena_1     (id2c_w_reg_ena_i   ),
        .ex_w_reg_dst_1     (id2c_w_reg_dst_i   ),
        .ex_ls_ena_1        (id2c_ls_ena_i      ),
        .ex_w_reg_ena_2     (id2p_w_reg_ena_i   ),
        .ex_w_reg_dst_2     (id2p_w_reg_dst_i   ),
        .ex_ls_ena_2        (id2p_ls_ena_i      ),
        .mem_w_reg_ena_1    (exc_w_reg_ena_i    ),
        .mem_w_reg_dst_1    (exc_w_reg_dst_i    ),
        .mem_ls_ena_1       (exc_ls_ena_i       ),
        .mem_w_reg_ena_2    (exp_w_reg_ena_i    ),
        .mem_w_reg_dst_2    (exp_w_reg_dst_i    ),
        .mem_ls_ena_2       (exp_ls_ena_i       ),

        .ex_mem_w_hilo_ena_1(exc_w_hilo_ena_i   ),
        .ex_mem_w_hilo_ena_2(exp_w_hilo_ena_i   ),

        .forward_rs         (forwardp_rs        ),
        .forward_rt         (forwardp_rt        ),
        .forward_hi         (forwardp_hi        ),
        .forward_lo         (forwardp_lo        ),

        .forward_stall_req  (forwardp_stall_req ),
        .forward_flush_req  (forwardp_flush_req )
    );

    idu_2 idu2_c (
        .id1_valid          (id1c_valid_i       ),
        .cp0_has_int        (cp0_has_int        ),

        .id1_op_codes       (id1c_op_codes_i    ),
        .id1_func_codes     (id1c_func_codes_i  ),
        .id1_pc             (id1c_pc_i          ),
        .id1_rs             (id1c_rs_i          ),
        .id1_rt             (id1c_rt_i          ),
        .id1_rd             (id1c_rd_i          ),
        .id1_sa             (id1c_sa_i          ),
        .id1_w_reg_ena      (id1c_w_reg_ena_i   ),
        .id1_w_reg_dst      (id1c_w_reg_dst_i   ),
        .id1_imme           (id1c_imme_i        ),
        .id1_j_imme         (id1c_j_imme_i      ),
        .id1_is_branch      (id1c_is_branch_i   ),
        .id1_is_j_imme      (id1c_is_j_imme_i   ),
        .id1_is_jr          (id1c_is_jr_i       ),
        .id1_is_ls          (id1c_is_ls_i       ),
        .id1_in_delay_slot  (id1c_in_delay_slot_i),
        .id1_inst_adel      (id1c_is_inst_adel_i ),

        .forward_rs         (forwardc_rs        ),
        .forward_rt         (forwardc_rt        ),
        .exc_alu_res        (exc_alu_res_o      ),
        .exp_alu_res        (exp_alu_res_o      ),
        .memc_alu_res       (memc_alu_res_o     ),
        .memc_r_data        (memc_r_data_o      ),
        .memp_alu_res       (memp_alu_res_o     ),
        .memp_r_data        (memp_r_data_o      ),

        .reg_r_addr_1       (id2c_r_addr_1      ),
        .reg_r_addr_2       (id2c_r_addr_2      ),
        .reg_r_data_1       (id2c_r_data_1      ),
        .reg_r_data_2       (id2c_r_data_2      ),

        // output
        .id2_in_delay_slot  (id2c_in_delay_slot_o),        
        .id2_is_eret        (id2c_is_eret_o      ),    
        .id2_is_syscall     (id2c_is_syscall_o   ),    
        .id2_is_break       (id2c_is_break_o     ),    
        .id2_is_inst_adel   (id2c_is_inst_adel_o ),        
        .id2_is_ri          (id2c_is_ri_o        ),
        .id2_is_int         (id2c_is_int_o       ),
        .id2_is_check_ov    (id2c_is_check_ov_o  ),        

        .id2_is_branch      (id2c_is_branch_o   ),
        .id2_is_j_imme      (id2c_is_j_imme_o   ),
        .id2_is_jr          (id2c_is_jr_o       ),
        .id2_is_ls          (id2c_is_ls_o       ),
        .id2_branch_sel     (id2c_branch_sel_o  ),

        .id2_pc             (id2c_pc_o          ),
        .id2_rs             (id2c_rs_o          ),    
        .id2_rt             (id2c_rt_o          ),    
        .id2_rd             (id2c_rd_o          ),    
        .id2_w_reg_dst      (id2c_w_reg_dst_o   ),

        .id2_sa             (id2c_sa_o          ),
        .id2_rs_data        (id2c_rs_data_o     ),
        .id2_rt_data        (id2c_rt_data_o     ),
        .id2_imme           (id2c_imme_o        ),
        .id2_j_imme         (id2c_j_imme_o      ),
        .id2_ext_imme       (id2c_ext_imme_o    ),

        // .id2_take_branch    (id2c_take_branch   ),
        // .id2_take_j_imme    (id2c_take_j_imme   ),
        // .id2_take_jr        (id2c_take_jr       ),
        // .id2_flush_req      (id2c_flush_req     ),  // attention !

        .id2_src_a_sel      (id2c_src_a_sel_o   ),
        .id2_src_b_sel      (id2c_src_b_sel_o   ),
        .id2_alu_sel        (id2c_alu_sel_o     ),
        .id2_alu_res_sel    (id2c_alu_res_sel_o ),
        .id2_w_reg_ena      (id2c_w_reg_ena_o   ),
        .id2_w_hilo_ena     (id2c_w_hilo_ena_o  ),
        .id2_w_cp0_ena      (id2c_w_cp0_ena_o   ),
        .id2_w_cp0_addr     (id2c_w_cp0_addr_o  ),
        .id2_ls_ena         (id2c_ls_ena_o      ),
        .id2_ls_sel         (id2c_ls_sel_o      ),
        .id2_wb_reg_sel     (id2c_wb_reg_sel_o  )
    );

    idu_2 idu2_p (
        .id1_valid          (id1p_valid_i       ),
        .cp0_has_int        (1'b0               ),
        .id1_op_codes       (id1p_op_codes_i    ),
        .id1_func_codes     (id1p_func_codes_i  ),
        .id1_pc             (id1p_pc_i          ),
        .id1_rs             (id1p_rs_i          ),
        .id1_rt             (id1p_rt_i          ),
        .id1_rd             (id1p_rd_i          ),
        .id1_sa             (id1p_sa_i          ),
        .id1_w_reg_ena      (id1p_w_reg_ena_i   ),
        .id1_w_reg_dst      (id1p_w_reg_dst_i   ),
        .id1_imme           (id1p_imme_i        ),
        .id1_j_imme         (id1p_j_imme_i      ),
        .id1_is_branch      (id1p_is_branch_i   ),
        .id1_is_j_imme      (id1p_is_j_imme_i   ),
        .id1_is_jr          (id1p_is_jr_i       ),
        .id1_is_ls          (id1p_is_ls_i       ),
        .id1_in_delay_slot  (id1p_in_delay_slot_i),
        .id1_inst_adel      (id1p_is_inst_adel_i ),

        .forward_rs         (forwardp_rs        ),
        .forward_rt         (forwardp_rt        ),
        .exc_alu_res        (exc_alu_res_o      ),
        .exp_alu_res        (exp_alu_res_o      ),
        .memc_alu_res       (memc_alu_res_o     ),
        .memc_r_data        (memc_r_data_o      ),
        .memp_alu_res       (memp_alu_res_o     ),
        .memp_r_data        (memp_r_data_o      ),

        .reg_r_addr_1       (id2p_r_addr_1      ),
        .reg_r_addr_2       (id2p_r_addr_2      ),
        .reg_r_data_1       (id2p_r_data_1      ),
        .reg_r_data_2       (id2p_r_data_2      ),

        // output
        .id2_in_delay_slot  (id2p_in_delay_slot_o),        
        .id2_is_eret        (id2p_is_eret_o      ),    
        .id2_is_syscall     (id2p_is_syscall_o   ),    
        .id2_is_break       (id2p_is_break_o     ),    
        .id2_is_inst_adel   (id2p_is_inst_adel_o ),        
        .id2_is_ri          (id2p_is_ri_o        ),
        .id2_is_int         (id2p_is_int_o       ),
        .id2_is_check_ov    (id2p_is_check_ov_o  ),   

        .id2_is_branch      (id2p_is_branch_o   ),
        .id2_is_j_imme      (id2p_is_j_imme_o   ),
        .id2_is_jr          (id2p_is_jr_o       ),
        .id2_is_ls          (id2p_is_ls_o       ),
        .id2_branch_sel     (                   ),

        .id2_pc             (id2p_pc_o          ),
        .id2_rs             (id2p_rs_o          ),    
        .id2_rt             (id2p_rt_o          ),    
        .id2_rd             (id2p_rd_o          ),    
        .id2_w_reg_dst      (id2p_w_reg_dst_o   ),

        .id2_sa             (id2p_sa_o          ),
        .id2_rs_data        (id2p_rs_data_o     ),
        .id2_rt_data        (id2p_rt_data_o     ),
        .id2_imme           (id2p_imme_o        ),
        .id2_j_imme         (id2p_j_imme_o      ),
        .id2_ext_imme       (id2p_ext_imme_o    ),

        // .id2_take_branch    (                   ),
        // .id2_take_j_imme    (                   ),
        // .id2_take_jr        (                   ),
        // .id2_flush_req      (                   ),

        .id2_src_a_sel      (id2p_src_a_sel_o   ),
        .id2_src_b_sel      (id2p_src_b_sel_o   ),
        .id2_alu_sel        (id2p_alu_sel_o     ),
        .id2_alu_res_sel    (id2p_alu_res_sel_o ),
        .id2_w_reg_ena      (id2p_w_reg_ena_o   ),
        .id2_w_hilo_ena     (id2p_w_hilo_ena_o  ),
        .id2_w_cp0_ena      (id2p_w_cp0_ena_o   ),
        .id2_w_cp0_addr     (id2p_w_cp0_addr_o  ),
        .id2_ls_ena         (id2p_ls_ena_o      ),
        .id2_ls_sel         (id2p_ls_sel_o      ),
        .id2_wb_reg_sel     (id2p_wb_reg_sel_o  )
    );

    regfile rg (
        .clk                (clk                ),
        .rst                (rst                ),
        
        .r_addr_1           (id2c_r_addr_1      ),
        .r_data_1           (id2c_r_data_1      ),
        
        .r_addr_2           (id2c_r_addr_2      ),
        .r_data_2           (id2c_r_data_2      ),
        
        .r_addr_3           (id2p_r_addr_1      ),
        .r_data_3           (id2p_r_data_1      ),
        
        .r_addr_4           (id2p_r_addr_2      ),
        .r_data_4           (id2p_r_data_2      ),
        
        .w_ena_1            (wbc_w_reg_ena_o    ),
        .w_addr_1           (wbc_w_reg_addr_o   ),
        .w_data_1           (wbc_w_reg_data_o   ),

        .w_ena_2            (wbp_w_reg_ena_o    ),
        .w_addr_2           (wbp_w_reg_addr_o   ),
        .w_data_2           (wbp_w_reg_data_o   )
    );

    branch_ctrl b_ctrl (
        .id2_branch_sel     (id2c_branch_sel_i  ),
        .id2_is_branch      (id2c_is_branch_i   ),
        .id2_is_j_imme      (id2c_is_j_imme_i   ),
        .id2_is_jr          (id2c_is_jr_i       ),
        .id2_rs_data        (id2c_rs_data_i     ),
        .id2_rt_data        (id2c_rt_data_i     ),

        .take_branch        (take_branch        ),
        .take_j_imme        (take_j_imme        ),
        .take_jr            (take_jr            ),
        .flush_req          (b_ctrl_flush_req   )
    );

    ex exc (
        .clk                (clk                ),
        .rst                (rst                ),

        .id2_in_delay_slot  (id2c_in_delay_slot_i),
        .id2_is_eret        (id2c_is_eret_i      ),
        .id2_is_syscall     (id2c_is_syscall_i   ),
        .id2_is_break       (id2c_is_break_i     ),
        .id2_is_inst_adel   (id2c_is_inst_adel_i ),
        .id2_is_ri          (id2c_is_ri_i        ),
        .id2_is_int         (id2c_is_int_i       ),
        .id2_is_check_ov    (id2c_is_check_ov_i  ),

        .id2_rd             (id2c_rd_i          ),
        .id2_w_reg_dst      (id2c_w_reg_dst_i   ),
        .id2_sa             (id2c_sa_i          ),
        .id2_rs_data        (id2c_rs_data_i     ),
        .id2_rt_data        (id2c_rt_data_i     ),
        .id2_ext_imme       (id2c_ext_imme_i    ),
        .id2_pc             (id2c_pc_i          ),
        .forward_hi         (forwardc_hi        ),
        .forward_lo         (forwardc_lo        ),
        .hilo_hi            (r_hi_data          ),
        .hilo_lo            (r_lo_data          ),
        .memc_hi_res        (exc_hi_res_i       ),
        .memc_lo_res        (exc_lo_res_i       ),
        .memp_hi_res        (exp_hi_res_i       ),
        .memp_lo_res        (exp_lo_res_i       ),
        .ex_cp0_r_ena       (exc_cp0_r_ena      ),
        .ex_cp0_r_addr      (exc_cp0_r_addr     ),
        .ex_cp0_r_data      (cp0_r_data         ),
        .id2_src_a_sel      (id2c_src_a_sel_i   ),
        .id2_src_b_sel      (id2c_src_b_sel_i   ),
        .id2_alu_sel        (id2c_alu_sel_i     ),
        .id2_alu_res_sel    (id2c_alu_res_sel_i ),
        .id2_w_reg_ena      (id2c_w_reg_ena_i   ),
        .id2_w_hilo_ena     (id2c_w_hilo_ena_i  ),
        .id2_w_cp0_ena      (id2c_w_cp0_ena_i   ),
        .id2_w_cp0_addr     (id2c_w_cp0_addr_i  ),
        .id2_ls_ena         (id2c_ls_ena_i      ),
        .id2_ls_sel         (id2c_ls_sel_i      ),
        .id2_wb_reg_sel     (id2c_wb_reg_sel_i  ),
        .ex_stall_req       (exc_stall_req      ),
        .ex_alu_res         (exc_alu_res_o      ),
        .ex_w_hilo_ena      (exc_w_hilo_ena_o   ),
        .ex_hi_res          (exc_hi_res_o       ),
        .ex_lo_res          (exc_lo_res_o       ),

        // back from mem
        .ex_has_exception   (exc_has_exception  ),
        .to_ex_is_data_adel (to_exc_is_data_adel),
        .to_ex_is_data_ades (to_exc_is_data_ades),
        
        .ex_in_delay_slot   (exc_in_delay_slot_o),
        .ex_is_eret         (exc_is_eret_o      ),
        .ex_is_syscall      (exc_is_syscall_o   ),
        .ex_is_break        (exc_is_break_o     ),
        .ex_is_inst_adel    (exc_is_inst_adel_o ),
        .ex_is_data_adel    (exc_is_data_adel_o ),
        .ex_is_data_ades    (exc_is_data_ades_o ),
        .ex_is_overflow     (exc_is_overflow_o  ),
        .ex_is_ri           (exc_is_ri_o        ),
        .ex_is_int          (exc_is_int_o       ),

        .ex_pc              (exc_pc_o           ),
        .ex_rt_data         (exc_rt_data_o      ),
        .ex_w_reg_ena       (exc_w_reg_ena_o    ),
        .ex_w_reg_dst       (exc_w_reg_dst_o    ),
        .ex_ls_ena          (exc_ls_ena_o       ),
        .ex_ls_sel          (exc_ls_sel_o       ),
        .ex_wb_reg_sel      (exc_wb_reg_sel_o   ),
        .ex_w_cp0_ena       (exc_w_cp0_ena_o    ),
        .ex_w_cp0_addr      (exc_w_cp0_addr_o   ),
        .ex_w_cp0_data      (exc_w_cp0_data_o   )
    );

    ex exp (
        .clk                (clk                ),
        .rst                (rst                ),

        .id2_in_delay_slot  (id2p_in_delay_slot_i),
        .id2_is_eret        (id2p_is_eret_i      ),
        .id2_is_syscall     (id2p_is_syscall_i   ),
        .id2_is_break       (id2p_is_break_i     ),
        .id2_is_inst_adel   (id2p_is_inst_adel_i ),
        .id2_is_ri          (id2p_is_ri_i        ),
        .id2_is_int         (id2p_is_int_i       ),
        .id2_is_check_ov    (id2p_is_check_ov_i  ),

        .id2_rd             (id2p_rd_i          ),
        .id2_w_reg_dst      (id2p_w_reg_dst_i   ),
        .id2_sa             (id2p_sa_i          ),
        .id2_rs_data        (id2p_rs_data_i     ),
        .id2_rt_data        (id2p_rt_data_i     ),
        .id2_ext_imme       (id2p_ext_imme_i    ),
        .id2_pc             (id2p_pc_i          ),
        .forward_hi         (forwardp_hi        ),
        .forward_lo         (forwardp_lo        ),
        .hilo_hi            (r_hi_data          ),
        .hilo_lo            (r_lo_data          ),
        .memc_hi_res        (exc_hi_res_i       ),
        .memc_lo_res        (exc_lo_res_i       ),
        .memp_hi_res        (exp_hi_res_i       ),
        .memp_lo_res        (exp_lo_res_i       ),
        .ex_cp0_r_ena       (exp_cp0_r_ena      ),
        .ex_cp0_r_addr      (exp_cp0_r_addr     ),
        .ex_cp0_r_data      (cp0_r_data         ),
        .id2_src_a_sel      (id2p_src_a_sel_i   ),
        .id2_src_b_sel      (id2p_src_b_sel_i   ),
        .id2_alu_sel        (id2p_alu_sel_i     ),
        .id2_alu_res_sel    (id2p_alu_res_sel_i ),
        .id2_w_reg_ena      (id2p_w_reg_ena_i   ),
        .id2_w_hilo_ena     (id2p_w_hilo_ena_i  ),
        .id2_w_cp0_ena      (id2p_w_cp0_ena_i   ),
        .id2_w_cp0_addr     (id2p_w_cp0_addr_i  ),
        .id2_ls_ena         (id2p_ls_ena_i      ),
        .id2_ls_sel         (id2p_ls_sel_i      ),
        .id2_wb_reg_sel     (id2p_wb_reg_sel_i  ),
        .ex_stall_req       (exp_stall_req      ),
        .ex_alu_res         (exp_alu_res_o      ),
        .ex_w_hilo_ena      (exp_w_hilo_ena_o   ),
        .ex_hi_res          (exp_hi_res_o       ),
        .ex_lo_res          (exp_lo_res_o       ),
        
        // back from mem
        .ex_has_exception   (exp_has_exception  ),
        .to_ex_is_data_adel (to_exp_is_data_adel),
        .to_ex_is_data_ades (to_exp_is_data_ades),
        
        .ex_in_delay_slot   (exp_in_delay_slot_o),
        .ex_is_eret         (exp_is_eret_o      ),
        .ex_is_syscall      (exp_is_syscall_o   ),
        .ex_is_break        (exp_is_break_o     ),
        .ex_is_inst_adel    (exp_is_inst_adel_o ),
        .ex_is_data_adel    (exp_is_data_adel_o ),
        .ex_is_data_ades    (exp_is_data_ades_o ),
        .ex_is_overflow     (exp_is_overflow_o  ),
        .ex_is_ri           (exp_is_ri_o        ),
        .ex_is_int          (exp_is_int_o       ),

        .ex_pc              (exp_pc_o           ),
        .ex_rt_data         (exp_rt_data_o      ),
        .ex_w_reg_ena       (exp_w_reg_ena_o    ),
        .ex_w_reg_dst       (exp_w_reg_dst_o    ),
        .ex_ls_ena          (exp_ls_ena_o       ),
        .ex_ls_sel          (exp_ls_sel_o       ),
        .ex_wb_reg_sel      (exp_wb_reg_sel_o   ),
        .ex_w_cp0_ena       (exp_w_cp0_ena_o    ),
        .ex_w_cp0_addr      (exp_w_cp0_addr_o   ),
        .ex_w_cp0_data      (exp_w_cp0_data_o   )
    );

    lsu memc (
        .ex_pc              (exc_pc_i           ),
        .ex_alu_res         (exc_alu_res_o      ),
        .ex_rt_data         (exc_rt_data_o      ),
        .ex_ls_ena          (exc_ls_ena_o       ),
        .ex_ls_sel          (exc_ls_sel_o       ),
        .ex_has_exception   (exc_has_exception  
                            |exp_has_exception  ),
        .to_ex_is_data_adel (to_exc_is_data_adel),
        .to_ex_is_data_ades (to_exc_is_data_ades),

        .ex_mem_alu_res     (exc_alu_res_i      ),
        .ex_mem_rt_data     (exc_rt_data_i      ),
        .ex_mem_w_reg_ena   (exc_w_reg_ena_i    ),
        .ex_mem_w_reg_dst   (exc_w_reg_dst_i    ),
        .ex_mem_ls_ena      (exc_ls_ena_i       ),
        .ex_mem_ls_sel      (exc_ls_sel_i       ),
        .ex_mem_wb_reg_sel  (exc_wb_reg_sel_i   ),

        .ex_mem_w_cp0_ena   (exc_w_cp0_ena_i    ),
        .ex_mem_w_cp0_addr  (exc_w_cp0_addr_i   ),
        .ex_mem_w_cp0_data  (exc_w_cp0_data_i   ),

        .ex_mem_in_delay_slot(exc_in_delay_slot_i),
        .ex_mem_is_eret      (exc_is_eret_i      ),
        .ex_mem_is_syscall   (exc_is_syscall_i   ),
        .ex_mem_is_break     (exc_is_break_i     ),
        .ex_mem_is_inst_adel (exc_is_inst_adel_i ),
        .ex_mem_is_data_adel (exc_is_data_adel_i ),
        .ex_mem_is_data_ades (exc_is_data_ades_i ),
        .ex_mem_is_overflow  (exc_is_overflow_i  ),
        .ex_mem_is_ri        (exc_is_ri_i        ),
        .ex_mem_is_int       (exc_is_int_i       ),

        .ex_mem_w_hilo_ena  (exc_w_hilo_ena_i   ),
        .ex_mem_hi_res      (exc_hi_res_i       ),
        .ex_mem_lo_res      (exc_lo_res_i       ),

        .mem_pc             (memc_pc_o          ),
        .mem_alu_res        (memc_alu_res_o     ),
        .mem_w_reg_ena      (memc_w_reg_ena_o   ),
        .mem_w_reg_dst      (memc_w_reg_dst_o   ),
        .mem_r_data         (memc_r_data_o      ),
        .mem_wb_reg_sel     (memc_wb_reg_sel_o  ),

        .mem_w_cp0_ena      (memc_w_cp0_ena_o   ),
        .mem_w_cp0_addr     (memc_w_cp0_addr_o  ),
        .mem_w_cp0_data     (memc_w_cp0_data_o  ),

        .mem_has_exception  (memc_has_exception_o),

        .mem_w_hilo_ena     (memc_w_hilo_ena_o  ),
        .mem_hi_res         (memc_hi_res_o      ),
        .mem_lo_res         (memc_lo_res_o      ),

        .data_ram_en        (memc_data_ena      ),
        .data_ram_wen       (memc_data_wea      ),
        .data_ram_addr      (memc_data_waddr    ),
        .data_ram_wdata     (memc_data_wdata    ),
        .data_ram_rdata     (memc_data_rdata    )
    );

    lsu memp (
        .ex_pc              (exp_pc_i           ),
        .ex_alu_res         (exp_alu_res_o      ),
        .ex_rt_data         (exp_rt_data_o      ),
        .ex_ls_ena          (exp_ls_ena_o       ),
        .ex_ls_sel          (exp_ls_sel_o       ),
        .ex_has_exception   (exc_has_exception  
                            |exp_has_exception  ),
        .to_ex_is_data_adel (to_exp_is_data_adel),
        .to_ex_is_data_ades (to_exp_is_data_ades),

        .ex_mem_alu_res     (exp_alu_res_i      ),
        .ex_mem_rt_data     (exp_rt_data_i      ),
        .ex_mem_w_reg_ena   (exp_w_reg_ena_i    ),
        .ex_mem_w_reg_dst   (exp_w_reg_dst_i    ),
        .ex_mem_ls_ena      (exp_ls_ena_i       ),
        .ex_mem_ls_sel      (exp_ls_sel_i       ),
        .ex_mem_wb_reg_sel  (exp_wb_reg_sel_i   ),

        .ex_mem_w_cp0_ena   (exp_w_cp0_ena_i    ),
        .ex_mem_w_cp0_addr  (exp_w_cp0_addr_i   ),
        .ex_mem_w_cp0_data  (exp_w_cp0_data_i   ),

        .ex_mem_in_delay_slot(exp_in_delay_slot_i),
        .ex_mem_is_eret      (exp_is_eret_i      ),
        .ex_mem_is_syscall   (exp_is_syscall_i   ),
        .ex_mem_is_break     (exp_is_break_i     ),
        .ex_mem_is_inst_adel (exp_is_inst_adel_i ),
        .ex_mem_is_data_adel (exp_is_data_adel_i ),
        .ex_mem_is_data_ades (exp_is_data_ades_i ),
        .ex_mem_is_overflow  (exp_is_overflow_i  ),
        .ex_mem_is_ri        (exp_is_ri_i        ),
        .ex_mem_is_int       (exp_is_int_i       ),

        .ex_mem_w_hilo_ena  (exp_w_hilo_ena_i   ),
        .ex_mem_hi_res      (exp_hi_res_i       ),
        .ex_mem_lo_res      (exp_lo_res_i       ),

        .mem_pc             (memp_pc_o          ),
        .mem_alu_res        (memp_alu_res_o     ),
        .mem_w_reg_ena      (memp_w_reg_ena_o   ),
        .mem_w_reg_dst      (memp_w_reg_dst_o   ),
        .mem_r_data         (memp_r_data_o      ),
        .mem_wb_reg_sel     (memp_wb_reg_sel_o  ),

        .mem_w_cp0_ena      (memp_w_cp0_ena_o   ),
        .mem_w_cp0_addr     (memp_w_cp0_addr_o  ),
        .mem_w_cp0_data     (memp_w_cp0_data_o  ),

        .mem_has_exception  (memp_has_exception_o),

        .mem_w_hilo_ena     (memp_w_hilo_ena_o  ),
        .mem_hi_res         (memp_hi_res_o      ),
        .mem_lo_res         (memp_lo_res_o      ),

        .data_ram_en        (memp_data_ena      ),
        .data_ram_wen       (memp_data_wea      ),
        .data_ram_addr      (memp_data_waddr    ),
        .data_ram_wdata     (memp_data_wdata    ),
        .data_ram_rdata     (memp_data_rdata    )
    );

    assign data_ena     = memc_data_ena     | memp_data_ena;
    assign data_wea     = memc_data_wea     | memp_data_wea;
    assign data_waddr   = memc_data_waddr   | memp_data_waddr;
    assign data_wdata   = memc_data_wdata   | memp_data_wdata;
    assign memc_data_rdata  = data_rdata;
    assign memp_data_rdata  = data_rdata;

    exception_ctrl e_ctrl (
        .clk                        (clk                    ),
        .rst                        (rst                    ),
        .pc_1                       (exc_pc_i               ),
        .mem_badvaddr_1             (exc_alu_res_i          ),
        .in_delay_slot_1            (exc_in_delay_slot_i    ),
        .exception_is_eret_1        (exc_is_eret_i          ),
        .exception_is_syscall_1     (exc_is_syscall_i       ),
        .exception_is_break_1       (exc_is_break_i         ),
        .exception_is_inst_adel_1   (exc_is_inst_adel_i     ),
        .exception_is_data_adel_1   (exc_is_data_adel_i     ),
        .exception_is_data_ades_1   (exc_is_data_ades_i     ),
        .exception_is_overflow_1    (exc_is_overflow_i      ),
        .exception_is_ri_1          (exc_is_ri_i            ),
        .exception_is_int_1         (exc_is_int_i           ),

        .pc_2                       (exp_pc_i               ),
        .mem_badvaddr_2             (exp_alu_res_i          ),
        .in_delay_slot_2            (exp_in_delay_slot_i    ),
        .exception_is_eret_2        (exp_is_eret_i          ),
        .exception_is_syscall_2     (exp_is_syscall_i       ),
        .exception_is_break_2       (exp_is_break_i         ),
        .exception_is_inst_adel_2   (exp_is_inst_adel_i     ),
        .exception_is_data_adel_2   (exp_is_data_adel_i     ),
        .exception_is_data_ades_2   (exp_is_data_ades_i     ),
        .exception_is_overflow_2    (exp_is_overflow_i      ),
        .exception_is_ri_2          (exp_is_ri_i            ),
        .exception_is_int_2         (exp_is_int_i           ),

        .r_cp0_epc                  (cp0_epc            ),

        .exception_pc_ena           (exception_pc_ena   ),
        .exception_pc               (exception_pc       ),

        .w_cp0_update_ena           (w_cp0_update_ena   ),
        .w_cp0_exccode              (w_cp0_exccode      ),
        .w_cp0_bd                   (w_cp0_bd           ),
        .w_cp0_exl                  (w_cp0_exl          ),
        .w_cp0_epc                  (w_cp0_epc          ),
        .w_cp0_badvaddr_ena         (w_cp0_badvaddr_ena ),
        .w_cp0_badvaddr             (w_cp0_badvaddr     ),
        .cp0_cls_exl                (cp0_cls_exl        ),

        .flush_pipline              (exception_flush    )        
    );

    wire        cp0_w_ena = memc_w_cp0_ena_o | memp_w_cp0_ena_o;
    wire [7 :0] cp0_w_addr=
        {8{memc_w_cp0_ena_o}} & memc_w_cp0_addr_o |
        {8{memp_w_cp0_ena_o}} & memp_w_cp0_addr_o ;
    wire [31:0] cp0_w_data=
        {32{memc_w_cp0_ena_o}}& memc_w_cp0_data_o |
        {32{memp_w_cp0_ena_o}}& memp_w_cp0_data_o ;

    wire        cp0_r_ena   = exc_cp0_r_ena | exp_cp0_r_ena;
    wire [7 :0] cp0_r_addr  =
        {8{exc_cp0_r_ena}} & exc_cp0_r_addr |
        {8{exp_cp0_r_ena}} & exp_cp0_r_addr ;

    cp0 cp0c(
        .clk                        (clk                ),
        .rst                        (rst                ),
        .interrupt                  (interrupt          ),
        .r_ena                      (cp0_r_ena          ),
        .r_addr                     (cp0_r_addr         ),
        .r_data                     (cp0_r_data         ),
        .w_ena                      (cp0_w_ena          ),
        .w_addr                     (cp0_w_addr         ),
        .w_data                     (cp0_w_data         ),

        .epc                        (cp0_epc            ),
        .cp0_has_int                (cp0_has_int        ),
        .cp0_cls_exl                (cp0_cls_exl        ),
        .w_cp0_update_ena           (w_cp0_update_ena   ),
        .w_cp0_exccode              (w_cp0_exccode      ),
        .w_cp0_bd                   (w_cp0_bd           ),
        .w_cp0_exl                  (w_cp0_exl          ),
        .w_cp0_epc                  (w_cp0_epc          ),
        .w_cp0_badvaddr_ena         (w_cp0_badvaddr_ena ),
        .w_cp0_badvaddr             (w_cp0_badvaddr     )
    );

    wbu wbc (
        .stall              (wb_stall           ),
        .mem_has_exception  (memc_has_exception_i),
        .mem_pc             (memc_pc_i          ),
        .mem_alu_res        (memc_alu_res_i     ),
        .mem_w_reg_ena      (memc_w_reg_ena_i   ),
        .mem_w_reg_dst      (memc_w_reg_dst_i   ),
        .mem_r_data         (memc_r_data_i      ),
        .mem_wb_sel         (memc_wb_reg_sel_i  ),
        .wb_pc              (wbc_pc_o           ),
        .wb_w_reg_ena       (wbc_w_reg_ena_o    ),
        .wb_w_reg_addr      (wbc_w_reg_addr_o   ),
        .wb_w_reg_data      (wbc_w_reg_data_o   )
    );

    wbu wbp (
        .stall              (wb_stall           ),
        .mem_has_exception  (memp_has_exception_i|
                             memc_has_exception_i),
        .mem_pc             (memp_pc_i          ),
        .mem_alu_res        (memp_alu_res_i     ),
        .mem_w_reg_ena      (memp_w_reg_ena_i   ),
        .mem_w_reg_dst      (memp_w_reg_dst_i   ),
        .mem_r_data         (memp_r_data_i      ),
        .mem_wb_sel         (memp_wb_reg_sel_i  ),
        .wb_pc              (wbp_pc_o           ),
        .wb_w_reg_ena       (wbp_w_reg_ena_o    ),
        .wb_w_reg_addr      (wbp_w_reg_addr_o   ),
        .wb_w_reg_data      (wbp_w_reg_data_o   )
    );

    assign debug_wb_pc_1        = wbc_pc_o;
    assign debug_wb_rf_wen_1    = {4{wbc_w_reg_ena_o}};
    assign debug_wb_rf_wnum_1   = wbc_w_reg_addr_o;
    assign debug_wb_rf_wdata_1  = wbc_w_reg_data_o;

    assign debug_wb_pc_2        = wbp_pc_o;
    assign debug_wb_rf_wen_2    = {4{wbp_w_reg_ena_o}};
    assign debug_wb_rf_wnum_2   = wbp_w_reg_addr_o;
    assign debug_wb_rf_wdata_2  = wbp_w_reg_data_o;

    wire [1 :0] w_hilo_ena_cp;
    assign w_hilo_ena_cp[1]     = 
         memc_w_hilo_ena_i[1] & (~memc_has_exception_i) | 
        (memp_w_hilo_ena_i[1] & (~memp_has_exception_i) & (~memc_has_exception_i));
    assign w_hilo_ena_cp[0]     = 
         memc_w_hilo_ena_i[0] & (~memc_has_exception_i) | 
        (memp_w_hilo_ena_i[0] & (~memp_has_exception_i) & (~memc_has_exception_i));
    wire [31:0] w_hi_res_cp     =
            {32{ memc_w_hilo_ena_i[1] & ~memp_w_hilo_ena_i[1]}} & memc_hi_res_i |
            {32{~memc_w_hilo_ena_i[1] &  memp_w_hilo_ena_i[1]}} & memp_hi_res_i ;
    wire [31:0] w_lo_res_cp     =
            {32{ memc_w_hilo_ena_i[0] & ~memp_w_hilo_ena_i[0]}} & memc_lo_res_i |
            {32{~memc_w_hilo_ena_i[0] &  memp_w_hilo_ena_i[0]}} & memp_lo_res_i ;

    hilo hl (
        .clk                (clk                ),
        .rst                (rst                ),
        .w_hilo_ena         (w_hilo_ena_cp      ),
        .w_hi_data          (w_hi_res_cp        ),
        .w_lo_data          (w_lo_res_cp        ),
        .r_hi_data          (r_hi_data          ),    
        .r_lo_data          (r_lo_data          )    
    );

    ctrl ctrl_pipeline (
        .i_cache_stall_req  (i_cache_stall_req ),
        .d_cache_stall_req  (d_cache_stall_req ),
        .fifo_stall_req     (fifo_stall_req    ),
        .forwardc_stall_req (forwardc_stall_req),
        .forwardc_flush_req (forwardc_flush_req),
        .forwardp_stall_req (forwardp_stall_req),
        .forwardp_flush_req (forwardp_flush_req),
        .b_ctrl_flush_req   (b_ctrl_flush_req  ),
        .exc_stall_req      (exc_stall_req     ),
        .exp_stall_req      (exp_stall_req     ),
        .exception_flush    (exception_flush   ),

        .pc_stall           (pc_stall          ),
        .pc_flush           (pc_flush          ),
        .fifo_flush         (fifo_flush        ),
        .issue_stall        (issue_stall       ),
        .ii_id2_flush       (ii_id2_flush      ),
        .ii_id2_stall       (ii_id2_stall      ),
        .id2_ex_flush       (id2_ex_flush      ),
        .id2_ex_stall       (id2_ex_stall      ),
        .ex_mem_flush       (ex_mem_flush      ),
        .ex_mem_stall       (ex_mem_stall      ),
        .mem_wb_flush       (mem_wb_flush      ),
        .mem_wb_stall       (mem_wb_stall      ),
        .wb_stall           (wb_stall          ),

        .ii_id2_exception_flush (ii_id2_exception_flush ),
        .id2_ex_exception_flush (id2_ex_exception_flush ),
        .ex_mem_exception_flush (ex_mem_exception_flush ),
        .mem_wb_exception_flush (mem_wb_exception_flush )
    );

endmodule