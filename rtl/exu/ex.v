`timescale 1ns / 1ps

`include "../idu/id_def.v"
`include "../utils/forward_def.v"

module ex (
    input   wire            clk,
    input   wire            rst,
    
    // exception signals
    input   wire            id2_in_delay_slot,
    input   wire            id2_is_eret,
    input   wire            id2_is_syscall,
    input   wire            id2_is_break,
    input   wire            id2_is_inst_adel,
    input   wire            id2_is_ri,
    input   wire            id2_is_int,
    input   wire            id2_is_check_ov,
    input   wire            id2_is_i_refill_tlbl,
    input   wire            id2_is_i_invalid_tlbl,
    input   wire            id2_is_refetch,
    input   wire            mmu_is_d_refill_tlbl,
    input   wire            mmu_is_d_refill_tlbs,
    input   wire            mmu_is_d_invalid_tlbl,
    input   wire            mmu_is_d_invalid_tlbs,
    input   wire            mmu_is_modify,
    input   wire            id2_is_tlbp,
    input   wire            id2_is_tlbr,
    input   wire            id2_is_tlbwi,
    input   wire            mem_is_w_cp0,

    // addr signals
    input   wire [4 :0]     id2_rd,
    input   wire [4 :0]     id2_w_reg_dst,

    // data signals
    input   wire [4 :0]     id2_sa,
    input   wire [31:0]     id2_rs_data,
    input   wire [31:0]     id2_rt_data,
    // input   wire [15:0]     id2_imme,
    // input   wire [25:0]     id2_j_imme,
    input   wire [31:0]     id2_ext_imme,
    input   wire [31:0]     id2_pc,

    // hilo
    input   wire [2 :0]     forward_hi,
    input   wire [2 :0]     forward_lo,
    input   wire [31:0]     hilo_hi,
    input   wire [31:0]     hilo_lo,
    input   wire [31:0]     memc_hi_res,
    input   wire [31:0]     memc_lo_res,
    input   wire [31:0]     memp_hi_res,
    input   wire [31:0]     memp_lo_res,
    // cp0
    output  wire            ex_cp0_r_ena,
    output  wire [7 :0]     ex_cp0_r_addr,
    input   wire [31:0]     ex_cp0_r_data,

    // control signals
    input   wire [2 :0]     id2_src_a_sel,
    input   wire [2 :0]     id2_src_b_sel,
    input   wire [5 :0]     id2_alu_sel,
    input   wire [2 :0]     id2_alu_res_sel,
    input   wire            id2_w_reg_ena,
    input   wire [1 :0]     id2_w_hilo_ena,
    input   wire            id2_w_cp0_ena,
    input   wire [7 :0]     id2_w_cp0_addr,
    input   wire            id2_ls_ena,
    input   wire [3 :0]     id2_ls_sel,
    input   wire            id2_wb_reg_sel,
    // output

    // ex output
    output  wire            ex_stall_req,
    output  wire [31:0]     ex_alu_res,
    output  wire [31:0]     ex_ls_addr,
    output  wire [1 :0]     ex_w_hilo_ena,  // ?
    output  wire [31:0]     ex_hi_res,
    output  wire [31:0]     ex_lo_res,

    // back from mem
    // if you want to LS, u can't have any exceptions from ex and mem.
    output  wire            ex_has_exception,
    input   wire            to_ex_is_data_adel,
    input   wire            to_ex_is_data_ades,

    // pass down
    output  wire            ex_in_delay_slot,
    output  wire            ex_is_eret,
    output  wire            ex_is_syscall,
    output  wire            ex_is_break,
    output  wire            ex_is_inst_adel,
    output  wire            ex_is_data_adel,
    output  wire            ex_is_data_ades,
    output  wire            ex_is_overflow,
    output  wire            ex_is_ri,
    output  wire            ex_is_int,
    output  wire            ex_is_i_refill_tlbl,
    output  wire            ex_is_i_invalid_tlbl,
    output  wire            ex_is_d_refill_tlbl,
    output  wire            ex_is_d_invalid_tlbl,
    output  wire            ex_is_d_refill_tlbs,
    output  wire            ex_is_d_invalid_tlbs,
    output  wire            ex_is_modify,
    output  wire            ex_is_refetch,
    output  wire            ex_is_tlbp,
    output  wire            ex_is_tlbr,
    output  wire            ex_is_tlbwi,
    output  wire            ex_tlb_stall_req,

    output  wire [31:0]     ex_pc,
    output  wire [31:0]     ex_rt_data,
    output  wire            ex_w_reg_ena,
    output  wire [4 :0]     ex_w_reg_dst,
    output  wire            ex_ls_ena,
    output  wire [3 :0]     ex_ls_sel,
    output  wire            ex_wb_reg_sel,
    output  wire            ex_w_cp0_ena,
    output  wire [7 :0]     ex_w_cp0_addr,
    output  wire [31:0]     ex_w_cp0_data
);

    wire [31: 0] src_a, src_b, alu_res;
    wire [31: 0] alu_hi_res, alu_lo_res;
    wire         alu_overflow;  

    wire [31: 0] fw_hi, fw_lo;

    assign ex_in_delay_slot = id2_in_delay_slot;
    assign ex_is_eret       = id2_is_eret;
    assign ex_is_syscall    = id2_is_syscall;
    assign ex_is_break      = id2_is_break;
    assign ex_is_inst_adel  = id2_is_inst_adel;
    assign ex_is_data_adel  = to_ex_is_data_adel;
    assign ex_is_data_ades  = to_ex_is_data_ades;
    assign ex_is_ri         = id2_is_ri;
    assign ex_is_overflow   = id2_is_check_ov & alu_overflow;
    assign ex_is_int        = id2_is_int;

    assign ex_is_i_refill_tlbl  = id2_is_i_refill_tlbl;
    assign ex_is_i_invalid_tlbl = id2_is_i_invalid_tlbl;
    assign ex_is_d_refill_tlbl  = id2_ls_ena & mmu_is_d_refill_tlbl;
    assign ex_is_d_invalid_tlbl = id2_ls_ena & mmu_is_d_invalid_tlbl;
    assign ex_is_d_refill_tlbs  = id2_ls_ena & mmu_is_d_refill_tlbs;
    assign ex_is_d_invalid_tlbs = id2_ls_ena & mmu_is_d_invalid_tlbs;
    assign ex_is_modify         = id2_ls_ena & mmu_is_modify;
    assign ex_is_refetch        = id2_is_refetch;

    assign ex_is_tlbp           = id2_is_tlbp;
    assign ex_is_tlbr           = id2_is_tlbr;
    assign ex_is_tlbwi          = id2_is_tlbwi;
    assign ex_tlb_stall_req     = (id2_is_tlbwi | id2_is_tlbr | id2_is_tlbp) & mem_is_w_cp0;

    assign ex_has_exception =
            ex_is_eret          |
            ex_is_syscall       |
            ex_is_break         |
            ex_is_inst_adel     |
            ex_is_data_adel     |
            ex_is_data_ades     |
            ex_is_ri            |
            ex_is_overflow      |
            ex_is_int           |
            ex_is_i_refill_tlbl |
            ex_is_i_invalid_tlbl;

    assign fw_hi        =
            ({32{
                !(forward_hi ^ `FORWARD_MEMP_HI)
            }} & memp_hi_res)   |
            ({32{
                !(forward_hi ^ `FORWARD_MEMC_HI)
            }} & memc_hi_res)   |
            ({32{
                !(forward_hi ^ `FORWARD_HILI_NOP)
            }} & hilo_hi    )   ;
    
    assign fw_lo        =
            ({32{
                !(forward_lo ^ `FORWARD_MEMP_LO)
            }} & memp_lo_res)   |
            ({32{
                !(forward_lo ^ `FORWARD_MEMC_LO)
            }} & memc_lo_res)   |
            ({32{
                !(forward_lo ^ `FORWARD_HILI_NOP)
            }} & hilo_lo    )   ;

    assign src_a        =
            ({32{
                !(id2_src_a_sel ^ `SRC_A_SEL_NOP) | !(id2_src_a_sel ^ `SRC_A_SEL_ZERO)
            }} & 32'h0          )   |
            ({32{
                !(id2_src_a_sel ^ `SRC_A_SEL_RS)
            }} & id2_rs_data    )   |
            ({32{
                !(id2_src_a_sel ^ `SRC_A_SEL_RT)
            }} & id2_rt_data    )   ;

    assign src_b        =
            ({32{
                !(id2_src_b_sel ^ `SRC_B_SEL_NOP) | !(id2_src_b_sel ^ `SRC_B_SEL_ZERO)
            }} & 32'h0          )   |
            ({32{
                !(id2_src_b_sel ^ `SRC_B_SEL_RT)
            }} & id2_rt_data    )   |
            ({32{
                !(id2_src_b_sel ^ `SRC_B_SEL_IMME)
            }} & id2_ext_imme   )   |
            ({32{
                !(id2_src_b_sel ^ `SRC_B_SEL_RS)
            }} & id2_rs_data    )   |
            ({32{
                !(id2_src_b_sel ^ `SRC_B_SEL_SA)
            }} & id2_sa         )   ;

    assign ex_alu_res   =
            ({32{
                !(id2_alu_res_sel ^ `ALU_RES_SEL_ALU)
            }} & alu_res        )   |
            ({32{
                !(id2_alu_res_sel ^ `ALU_RES_SEL_HI)
            }} & fw_hi          )   |
            ({32{
                !(id2_alu_res_sel ^ `ALU_RES_SEL_LO)
            }} & fw_lo          )   |
            ({32{
                !(id2_alu_res_sel ^ `ALU_RES_SEL_PC_8)
            }} & (id2_pc + 32'h8))  |
            ({32{
                !(id2_alu_res_sel ^ `ALU_RES_SEL_CP0)
            }} & ex_cp0_r_data);
    
    assign ex_ls_addr   =
            {32{id2_ls_ena}} & (src_a + src_b);
    
    assign ex_cp0_r_addr    = id2_w_cp0_addr;
    assign ex_cp0_r_ena     = !(id2_alu_res_sel ^ `ALU_RES_SEL_CP0);

    assign ex_w_hilo_ena    = id2_w_hilo_ena;
    assign ex_hi_res        = alu_hi_res;
    assign ex_lo_res        = alu_lo_res;

    assign ex_w_reg_ena     = id2_w_reg_ena;
    assign ex_w_reg_dst     = id2_w_reg_dst;
    assign ex_ls_ena        = id2_ls_ena;
    assign ex_ls_sel        = id2_ls_sel;
    assign ex_wb_reg_sel    = id2_wb_reg_sel;
    assign ex_rt_data       = id2_rt_data;

    assign ex_pc            = id2_pc;

    assign ex_w_cp0_ena     = id2_w_cp0_ena;
    assign ex_w_cp0_addr    = id2_w_cp0_addr;
    assign ex_w_cp0_data    = id2_rt_data;

    alu alu_kernel (
        .clk            (clk            ),
        .rst            (rst            ),
        .src_a          (src_a          ),
        .src_b          (src_b          ),
        .alu_sel        (id2_alu_sel    ),
        .alu_res        (alu_res        ),
        .alu_hi_res     (alu_hi_res     ),
        .alu_lo_res     (alu_lo_res     ),
        .alu_overflow   (alu_overflow   ),
        .alu_stall_req  (ex_stall_req   )
    );

endmodule