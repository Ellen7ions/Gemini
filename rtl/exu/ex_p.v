`timescale 1ns / 1ps

`include "../idu/id_def.v"
`include "../utils/forward_def.v"

module ex_p (
    input   wire            clk,
    input   wire            rst,

    input   wire            id2_in_delay_slot,

    input   wire [4 :0]     id2_rd,
    input   wire [4 :0]     id2_w_reg_dst,

    input   wire [4 :0]     id2_sa,
    input   wire [31:0]     id2_rs_data,
    input   wire [31:0]     id2_rt_data,

    input   wire [31:0]     id2_ext_imme,
    input   wire [31:0]     id2_pc,

    input   wire [2 :0]     id2_src_a_sel,
    input   wire [2 :0]     id2_src_b_sel,
    input   wire [5 :0]     id2_alu_sel,
    input   wire [2 :0]     id2_alu_res_sel,
    input   wire            id2_w_reg_ena,
    input   wire            id2_wb_reg_sel,

    output  wire [31:0]     ex_alu_res,

    output  wire            ex_in_delay_slot,

    output  wire [31:0]     ex_pc,
    output  wire [31:0]     ex_rt_data,
    output  wire            ex_w_reg_ena,
    output  wire [4 :0]     ex_w_reg_dst,
    output  wire            ex_wb_reg_sel
);

    wire [31: 0] src_a, src_b, alu_res;

    assign ex_in_delay_slot = id2_in_delay_slot;

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

    assign ex_alu_res   = alu_res;


    assign ex_w_reg_ena     = id2_w_reg_ena;
    assign ex_w_reg_dst     = id2_w_reg_dst;
    assign ex_wb_reg_sel    = id2_wb_reg_sel;
    assign ex_rt_data       = id2_rt_data;

    assign ex_pc            = id2_pc;

    alu_p alu_kernel (
        .clk            (clk            ),
        .rst            (rst            ),
        .src_a          (src_a          ),
        .src_b          (src_b          ),
        .alu_sel        (id2_alu_sel    ),
        .alu_res        (alu_res        )
    );

endmodule