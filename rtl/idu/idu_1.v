`timescale 1ns / 1ps

`include "id_def.v"

module idu_1 (
    input   wire [31:0]     inst,
    output  wire [5 :0]     id1_op_code,
    output  wire [4 :0]     id1_rs,
    output  wire [4 :0]     id1_rt,
    output  wire [4 :0]     id1_rd,
    output  wire [4 :0]     id1_sa,
    output  wire [5 :0]     id1_funct,
    output  wire            id1_w_reg_ena,
    output  wire [4 :0]     id1_w_reg_dst,
    output  wire [15:0]     id1_imme,
    output  wire [25:0]     id1_j_imme,
    output  wire            id1_is_branch,
    output  wire            id1_is_j_imme,
    output  wire            id1_is_jr,
    output  wire            id1_is_ls
);
    wire id1_r_rs_ena;
    wire id1_r_rt_ena;

    assign id1_op_code   = inst[31:26];
    assign id1_rs        = inst[25:21];
    assign id1_rt        = inst[20:16];
    assign id1_rd        = inst[15:11];
    assign id1_sa        = inst[10: 6];
    assign id1_funct     = inst[5 : 0];
    assign id1_imme      = inst[15: 0];
    assign id1_j_imme    = inst[25: 0];

    assign id1_w_reg_dst    =
            ({5{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                    id1_funct == `ADD_FUNCT     |
                    id1_funct == `ADDU_FUNCT    |
                    id1_funct == `SUB_FUNCT     |
                    id1_funct == `SUBU_FUNCT    |
                    id1_funct == `SLT_FUNCT     |
                    id1_funct == `SLTU_FUNCT    |
                    id1_funct == `AND_FUNCT     |
                    id1_funct == `NOR_FUNCT     |
                    id1_funct == `OR_FUNCT      |
                    id1_funct == `XOR_FUNCT     |
                    id1_funct == `SLLV_FUNCT    |
                    id1_funct == `SLL_FUNCT     |
                    id1_funct == `SRAV_FUNCT    |
                    id1_funct == `SRA_FUNCT     |
                    id1_funct == `SRLV_FUNCT    |
                    id1_funct == `SRL_FUNCT     |
                    id1_funct == `JALR_FUNCT    |
                    id1_funct == `MFHI_FUNCT    |
                    id1_funct == `MFLO_FUNCT    
                )
            }} & id1_rd) |
            ({5{
                (id1_op_code == `ADDI_OP_CODE   )   |
                (id1_op_code == `ADDIU_OP_CODE  )   |
                (id1_op_code == `SLTI_OP_CODE   )   |
                (id1_op_code == `SLTIU_OP_CODE  )   |
                (id1_op_code == `ANDI_OP_CODE   )   |
                (id1_op_code == `LUI_OP_CODE    )   |
                (id1_op_code == `ORI_OP_CODE    )   |
                (id1_op_code == `XORI_OP_CODE   )   |
                (id1_op_code == `LB_OP_CODE     )   |
                (id1_op_code == `LH_OP_CODE     )   |
                (id1_op_code == `LBU_OP_CODE    )   |
                (id1_op_code == `LHU_OP_CODE    )   |
                (id1_op_code == `LW_OP_CODE     )   |
                (id1_op_code == `COP0_OP_CODE & id1_rs == `MFC0_RS_CODE)
            }} & id1_rt) |
            ({5{
                (id1_op_code == `REGIMM_OP_CODE) & (
                    id1_rt == `BGEZAL_RT_CODE   |
                    id1_rt == `BLTZAL_RT_CODE   
                ) |
                (id1_op_code == `JAL_OP_CODE)
            }} & 5'd31 ) ;

    assign id1_is_branch    =
            (id1_op_code == `BEQ_OP_CODE    )   |
            (id1_op_code == `BNE_OP_CODE    )   |
            (id1_op_code == `REGIMM_OP_CODE )   |
            (id1_op_code == `BGTZ_OP_CODE   )   |
            (id1_op_code == `BLEZ_OP_CODE   )   |
            (id1_op_code == `JAL_OP_CODE    )   ;
            
    assign id1_is_j_imme    = 
            (id1_op_code == `J_OP_CODE      )   |
            (id1_op_code == `JAL_OP_CODE    )   ;

    assign id1_is_jr        = 
            (id1_op_code == `SPECIAL_OP_CODE & (
                id1_funct == `JR_FUNCT  |
                id1_funct == `JALR_FUNCT
            ));

    assign id1_is_ls        = 
            id1_op_code == `LB_OP_CODE  |
            id1_op_code == `LBU_OP_CODE |
            id1_op_code == `LH_OP_CODE  |
            id1_op_code == `LHU_OP_CODE |
            id1_op_code == `LW_OP_CODE  |
            id1_op_code == `SB_OP_CODE  |
            id1_op_code == `SH_OP_CODE  |
            id1_op_code == `SW_OP_CODE  ;

    assign id1_r_rs_ena     = 1'b0;
    assign id1_r_rt_ena     = 1'b0;
    assign id1_w_reg_ena    = 1'b0;    
    
endmodule