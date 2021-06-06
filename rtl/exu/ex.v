`timescale 1ns / 1ps

`include "../idu/id_def.v"

module ex (
    input   wire            clk,
    input   wire            rst,
    
    // // id signals
    // input   wire            id2_is_branch,
    // input   wire            id2_is_j_imme,
    // input   wire            id2_is_jr,
    // input   wire            id2_is_ls,

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
    input   wire            forward_hi,
    input   wire            forward_lo,
    input   wire [31:0]     hilo_hi,
    input   wire [31:0]     hilo_lo,
    input   wire [31:0]     memc_hi_res,
    input   wire [31:0]     memc_lo_res,
    // cp0
    output  wire [4 :0]     ex_cp0_r_addr,
    input   wire [31:0]     ex_cp0_r_data,
    output  wire            ex_cp0_w_ena,
    output  wire [4 :0]     ex_cp0_w_addr,
    output  wire [31:0]     ex_cp0_w_data,

    // control signals
    input   wire [2 :0]     id2_src_a_sel,
    input   wire [2 :0]     id2_src_b_sel,
    input   wire [5 :0]     id2_alu_sel,
    input   wire [2 :0]     id2_alu_res_sel,
    input   wire            id2_w_reg_ena,
    input   wire [1 :0]     id2_w_hilo_ena,
    input   wire            id2_w_cp0_ena,
    input   wire            id2_ls_ena,
    input   wire [3 :0]     id2_ls_sel,
    input   wire            id2_wb_reg_sel,
    // output

    // ex output
    output  wire            ex_stall_req,
    output  wire [31:0]     ex_alu_res,
    output  wire [1 :0]     ex_w_hilo_ena,  // ?
    output  wire [31:0]     ex_hi_res,
    output  wire [31:0]     ex_lo_res,

    // pass down
    output  wire [31:0]     ex_rt_data,
    output  wire [31:0]     ex_w_reg_ena,
    output  wire [4 :0]     ex_w_reg_dst,
    output  wire            ex_ls_ena,
    output  wire [3 :0]     ex_ls_sel,
    output  wire            ex_wb_reg_sel
);

    wire [31: 0] src_a, src_b, alu_res;
    wire [31: 0] alu_hi_res, alu_lo_res;

    wire [31: 0] fw_hi, fw_lo;

    assign fw_hi        =
            ({32{
                forward_hi
            }} & memc_hi_res)   |
            ({32{
                ~forward_hi
            }} & hilo_hi    )   ;
    
    assign fw_lo        =
            ({32{
                forward_lo
            }} & memc_hi_res)   |
            ({32{
                ~forward_lo
            }} & hilo_lo    )   ;

    assign src_a        =
            ({32{
                id2_src_a_sel == `SRC_A_SEL_NOP | id2_src_a_sel == `SRC_A_SEL_ZERO
            }} & 32'h0          )   |
            ({32{
                id2_src_a_sel == `SRC_A_SEL_RS
            }} & id2_rs_data    )   |
            ({32{
                id2_src_a_sel == `SRC_A_SEL_RT
            }} & id2_rt_data    )   ;

    assign src_b        =
            ({32{
                id2_src_b_sel == `SRC_B_SEL_NOP | id2_src_b_sel == `SRC_B_SEL_ZERO
            }} & 32'h0          )   |
            ({32{
                id2_src_b_sel == `SRC_B_SEL_RT
            }} & id2_rt_data    )   |
            ({32{
                id2_src_b_sel == `SRC_B_SEL_IMME
            }} & id2_ext_imme   )   |
            ({32{
                id2_src_b_sel == `SRC_B_SEL_RS
            }} & id2_rs_data    )   |
            ({32{
                id2_src_b_sel == `SRC_B_SEL_SA
            }} & id2_sa         )   ;

    assign ex_alu_res   =
            ({32{
                id2_alu_res_sel == `ALU_RES_SEL_ALU
            }} & alu_res        )   |
            ({32{
                id2_alu_res_sel == `ALU_RES_SEL_HI
            }} & fw_hi          )   |
            ({32{
                id2_alu_res_sel == `ALU_RES_SEL_LO
            }} & fw_lo          )   |
            ({32{
                id2_alu_res_sel == `ALU_RES_SEL_PC_8
            }} & (id2_pc + 32'h8))  |
            ({32{
                id2_alu_res_sel == `ALU_RES_SEL_CP0
            }} & ex_cp0_r_data);
    
    assign ex_cp0_r_addr    = id2_rd;
    assign ex_cp0_w_ena     = id2_w_cp0_ena;
    assign ex_cp0_w_addr    = id2_rd;
    assign ex_cp0_w_data    = id2_rt_data;

    assign ex_w_hilo_ena    = id2_w_hilo_ena;
    assign ex_hi_res        = alu_hi_res;
    assign ex_lo_res        = alu_lo_res;

    assign ex_w_reg_ena     = id2_w_reg_ena;
    assign ex_w_reg_dst     = id2_w_reg_dst;
    assign ex_ls_ena        = id2_ls_ena;
    assign ex_ls_sel        = id2_ls_sel;
    assign ex_wb_reg_sel    = id2_wb_reg_sel;
    assign ex_rt_data       = id2_rt_data;

    alu alu_kernel (
        .clk            (clk            ),
        .rst            (rst            ),
        .src_a          (src_a          ),
        .src_b          (src_b          ),
        .alu_sel        (id2_alu_sel    ),
        .alu_res        (alu_res        ),
        .alu_hi_res     (alu_hi_res     ),
        .alu_lo_res     (alu_lo_res     ),
        .alu_stall_req  (ex_stall_req   )
    );

endmodule