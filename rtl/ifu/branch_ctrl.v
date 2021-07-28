`timescale 1ns / 1ps

`include "../exu/branch_def.v"

module branch_ctrl (
    input   wire [31:0] ex_rs_data,
    input   wire [31:0] ex_rt_data,
    input   wire        ex_is_branch,
    input   wire        ex_is_jr,
    input   wire        ex_is_j_imme,
    input   wire [3 :0] ex_branch_sel,
    
    input   wire        ex_pred_taken,

    output  wire        ex_is_jmp,
    output  wire        ex_act_taken,
    output  wire        flush_req
);
    assign ex_is_jmp = ex_is_branch | ex_is_jr | ex_is_j_imme;
    wire beq_check      = ex_rs_data == ex_rt_data;
    wire bne_check      = ex_rs_data != ex_rt_data;
    wire bgez_check     = ~ex_rs_data[31];
    wire bgtz_check     = ~ex_rs_data[31] & |(ex_rs_data[30:0]);
    wire blez_check     = ex_rs_data[31] | !(|ex_rs_data);
    wire bltz_check     = ex_rs_data[31];
    
    assign ex_take_branch  =
        (!(ex_branch_sel ^ `BRANCH_SEL_BEQ     )) & (beq_check  )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BNE     )) & (bne_check  )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BGEZ    )) & (bgez_check )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BGTZ    )) & (bgtz_check )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BLEZ    )) & (blez_check )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BLTZ    )) & (bltz_check )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BGEZAL  )) & (bgez_check )  & ex_is_branch  |
        (!(ex_branch_sel ^ `BRANCH_SEL_BLTZAL  )) & (bltz_check )  & ex_is_branch  ;

    assign ex_act_taken = ex_is_jr | ex_is_j_imme | ex_take_branch;
    assign flush_req    = ex_pred_taken != ex_act_taken;
endmodule