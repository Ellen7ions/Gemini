`timescale 1ns / 1ps

`include "id_def.v"
`include "../utils/forward_def.v"

module idu_2 (
    input  wire [31:0]      id1_pc,
    input  wire [5 :0]      id1_op_code,
    input  wire [4 :0]      id1_rs,
    input  wire [4 :0]      id1_rt,
    input  wire [4 :0]      id1_rd,
    input  wire [4 :0]      id1_sa,
    input  wire [5 :0]      id1_funct,
    input  wire             id1_w_reg_ena,
    input  wire [4 :0]      id1_w_reg_dst,
    input  wire [15:0]      id1_imme,
    input  wire [25:0]      id1_j_imme,
    input  wire             id1_is_branch,
    input  wire             id1_is_j_imme,
    input  wire             id1_is_jr,
    input  wire             id1_is_ls,

    input  wire [1 :0]      forward_rs,
    input  wire [1 :0]      forward_rt,
    input  wire [31:0]      exc_alu_res,
    input  wire [31:0]      exp_alu_res,
    input  wire [31:0]      memc_alu_res,
    input  wire [31:0]      memc_r_data,
    input  wire [31:0]      memp_alu_res,

    // regfile
    output wire [4 :0]      reg_r_addr_1,
    output wire [4 :0]      reg_r_addr_2,
    input  wire [31:0]      reg_r_data_1,
    input  wire [31:0]      reg_r_data_2,

    // ====================== //

    // id signals
    output wire             id2_is_branch,
    output wire             id2_is_j_imme,
    output wire             id2_is_jr,
    output wire             id2_is_ls,

    // addr signals
    output wire [4 :0]      id2_rs,
    output wire [4 :0]      id2_rt,
    output wire [4 :0]      id2_rd,
    output wire [4 :0]      id2_w_reg_dst,

    // data signals
    output wire [4 :0]      id2_sa,
    output wire [31:0]      id2_rs_data,
    output wire [31:0]      id2_rt_data,
    output wire [15:0]      id2_imme,
    output wire [25:0]      id2_j_imme,
    output wire [31:0]      id2_ext_imme,
    output wire [31:0]      id2_pc,
    
    // control signals
    output wire             id2_take_branch,
    output wire             id2_take_j_imme,
    output wire             id2_take_jr,
    output wire             id2_flush_req,

    output reg  [2 :0]      id2_src_a_sel,
    output reg  [2 :0]      id2_src_b_sel,
    output wire [5 :0]      id2_alu_sel,
    output wire [2 :0]      id2_alu_res_sel,
    output wire             id2_w_reg_ena,
    output wire [1 :0]      id2_w_hilo_ena,
    output wire             id2_w_cp0_ena,
    output wire             id2_ls_ena,
    output wire [3 :0]      id2_ls_sel,
    output wire             id2_wb_reg_sel
);
    // attention !
    // w_hilo_ena   [1 :0]
    // w_cp0_ena    


    // internal signals
    wire sign_ext;

    assign reg_r_addr_1 = id1_rs;
    assign reg_r_addr_2 = id1_rt;

    assign sign_ext = 
            (id1_op_code == `ADDI_OP_CODE   )   |
            (id1_op_code == `ADDIU_OP_CODE  )   |
            (id1_op_code == `SLTI_OP_CODE   )   |
            (id1_op_code == `SLTIU_OP_CODE  )   |
            (id1_op_code == `LB_OP_CODE     )   |
            (id1_op_code == `LBU_OP_CODE    )   |
            (id1_op_code == `LH_OP_CODE     )   |
            (id1_op_code == `LHU_OP_CODE    )   |
            (id1_op_code == `LW_OP_CODE     )   |
            (id1_op_code == `SB_OP_CODE     )   |
            (id1_op_code == `SH_OP_CODE     )   |
            (id1_op_code == `SW_OP_CODE     )   ;

    // output signals

    assign id2_is_branch    = id1_is_branch;    
    assign id2_is_j_imme    = id1_is_j_imme;    
    assign id2_is_jr        = id1_is_jr;
    assign id2_is_ls        = id1_is_ls;

    assign id2_pc           = id1_pc;
    assign id2_rs           = id1_rs;            
    assign id2_rt           = id1_rt;
    assign id2_rd           = id1_rd;
    assign id2_w_reg_dst    = id1_w_reg_dst;

    assign id2_sa           = id1_sa;
    assign id2_imme         = id1_imme;
    assign id2_j_imme       = id1_j_imme;
    
    assign id2_ext_imme     = sign_ext ? {{16{id1_imme[15]}}, id1_imme} : {{16{1'b0}}, id1_imme};
    
    // forward !
    assign id2_rs_data      =
            ({32{
                forward_rs == `FORWARD_NOP
            }} & reg_r_data_1   )   |
            ({32{
                forward_rs == `FORWARD_EXC_ALU_RES
            }} & exc_alu_res    )   |
            ({32{
                forward_rs == `FORWARD_EXP_ALU_RES
            }} & exp_alu_res    )   |
            ({32{
                forward_rs == `FORWARD_MEMC_ALU_RES
            }} & memc_alu_res   )   |
            ({32{
                forward_rs == `FORWARD_MEMC_MEM_DATA
            }} & memc_r_data    )   |
            ({32{
                forward_rs == `FORWARD_MEMP_ALU_RES
            }} & memp_alu_res   )   ;
    
    assign id2_rt_data      =
            ({32{
                forward_rt == `FORWARD_NOP
            }} & reg_r_data_2   )   |
            ({32{
                forward_rt == `FORWARD_EXC_ALU_RES
            }} & exc_alu_res    )   |
            ({32{
                forward_rt == `FORWARD_EXP_ALU_RES
            }} & exp_alu_res    )   |
            ({32{
                forward_rt == `FORWARD_MEMC_ALU_RES
            }} & memc_alu_res   )   |
            ({32{
                forward_rt == `FORWARD_MEMC_MEM_DATA
            }} & memc_r_data    )   |
            ({32{
                forward_rt == `FORWARD_MEMP_ALU_RES
            }} & memp_alu_res   )   ;

    assign id2_take_branch  =
            id2_is_branch & (
                (id1_op_code == `BEQ_OP_CODE                                    ) & ($signed(id2_rs_data) == $signed(id2_rt_data))    |
                (id1_op_code == `BNE_OP_CODE                                    ) & ($signed(id2_rs_data) != $signed(id2_rt_data))    |
                (id1_op_code == `REGIMM_OP_CODE & id1_funct == `BGEZ_RT_CODE    ) & ($signed(id2_rs_data) >= $signed(32'h0      ))    |
                (id1_op_code == `BGTZ_OP_CODE                                   ) & ($signed(id2_rs_data) >  $signed(32'h0      ))    |
                (id1_op_code == `BLEZ_OP_CODE                                   ) & ($signed(id2_rs_data) <= $signed(32'h0      ))    |
                (id1_op_code == `REGIMM_OP_CODE & id1_funct == `BLTZ_RT_CODE    ) & ($signed(id2_rs_data) <  $signed(32'h0      ))    |
                (id1_op_code == `REGIMM_OP_CODE & id1_funct == `BGEZAL_RT_CODE  ) & ($signed(id2_rs_data) >= $signed(32'h0      ))    |
                (id1_op_code == `REGIMM_OP_CODE & id1_funct == `BLTZAL_RT_CODE  ) & ($signed(id2_rs_data) <  $signed(32'h0      ))    
            );
    
    assign id2_take_j_imme  =
            id2_is_j_imme & (
                1'b1
            );
    
    assign id2_take_jr      =
            id2_is_jr & (
                1'b1
            );

    assign id2_flush_req    =
            id2_take_jr | id2_take_j_imme | id2_take_branch;

    always @(*) begin
        if (id1_op_code == `SPECIAL_OP_CODE & (
            id1_funct   == `SLL_FUNCT   |
            id1_funct   == `SRA_FUNCT   |
            id1_funct   == `SRL_FUNCT   |
            id1_funct   == `SLLV_FUNCT  |
            id1_funct   == `SRAV_FUNCT  |
            id1_funct   == `SRLV_FUNCT  
        )) begin
            id2_src_a_sel = `SRC_A_SEL_RT;
        end else begin
            id2_src_a_sel = `SRC_A_SEL_RS;
        end
    end

    always @(*) begin
        if ((id1_op_code == `SPECIAL_OP_CODE) & (
            id1_funct   == `ADD_FUNCT       |
            id1_funct   == `ADDU_FUNCT      |
            id1_funct   == `SUB_FUNCT       |
            id1_funct   == `SUBU_FUNCT      |
            id1_funct   == `SLT_FUNCT       |
            id1_funct   == `SLTU_FUNCT      |
            id1_funct   == `DIV_FUNCT       |
            id1_funct   == `DIVU_FUNCT      |
            id1_funct   == `MULT_FUNCT      |
            id1_funct   == `MULTU_FUNCT     |
            id1_funct   == `AND_FUNCT       |
            id1_funct   == `NOR_FUNCT       |
            id1_funct   == `OR_FUNCT        |
            id1_funct   == `XOR_FUNCT       
        )) begin
            id2_src_b_sel = `SRC_B_SEL_RT;
        end else if (
            id1_op_code == `ADDI_OP_CODE    |
            id1_op_code == `ADDIU_OP_CODE   |
            id1_op_code == `SLTI_OP_CODE    |
            id1_op_code == `SLTIU_OP_CODE   |
            id1_op_code == `ANDI_OP_CODE    |
            id1_op_code == `LUI_OP_CODE     |
            id1_op_code == `ORI_OP_CODE     |
            id1_op_code == `XORI_OP_CODE    |

            id1_op_code == `LB_OP_CODE      |
            id1_op_code == `LBU_OP_CODE     |
            id1_op_code == `LH_OP_CODE      |
            id1_op_code == `LHU_OP_CODE     |
            id1_op_code == `LW_OP_CODE      |
            id1_op_code == `SB_OP_CODE      |
            id1_op_code == `SH_OP_CODE      |
            id1_op_code == `SW_OP_CODE     
        ) begin
            id2_src_b_sel = `SRC_B_SEL_IMME;
        end else if (id1_op_code == `SPECIAL_OP_CODE & (
            id1_op_code == `SLLV_FUNCT      |
            id1_op_code == `SRAV_FUNCT      |
            id1_op_code == `SRLV_FUNCT      
        )) begin
            id2_src_b_sel = `SRC_B_SEL_RS;
        end else if (id1_op_code == `SPECIAL_OP_CODE & (
            id1_op_code == `SLL_FUNCT       |
            id1_op_code == `SRA_FUNCT       |
            id1_op_code == `SRL_FUNCT       
        )) begin
            id2_src_b_sel = `SRC_B_SEL_SA;
        end else begin
            id2_src_b_sel = `SRC_B_SEL_NOP;
        end
    end

    assign id2_alu_sel = 
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `ADD_FUNCT     |
                id1_funct == `ADDU_FUNCT
                )   |
                (id1_op_code == `ADDI_OP_CODE   )   |
                (id1_op_code == `ADDIU_OP_CODE  )   |
                (id1_op_code == `LB_OP_CODE     )   |
                (id1_op_code == `LBU_OP_CODE    )   |
                (id1_op_code == `LH_OP_CODE     )   |
                (id1_op_code == `LHU_OP_CODE    )   |
                (id1_op_code == `LW_OP_CODE     )   |
                (id1_op_code == `SB_OP_CODE     )   |
                (id1_op_code == `SH_OP_CODE     )   |
                (id1_op_code == `SW_OP_CODE     )
            }} & (`ALU_SEL_ADD))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `SUB_FUNCT     |
                id1_funct == `SUBU_FUNCT
            )}} & (`ALU_SEL_SUB))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `SLT_FUNCT) |
                (id1_op_code == `SLTI_OP_CODE)
            }} & (`ALU_SEL_SLT))    |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `SLTU_FUNCT)|
                (id1_op_code == `SLTIU_OP_CODE)
            }} & (`ALU_SEL_SLTU))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `DIV_FUNCT)
            }} & (`ALU_SEL_DIV))    |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `DIVU_FUNCT)
            }} & (`ALU_SEL_DIVU))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `MULT_FUNCT)
            }} & (`ALU_SEL_MULT))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `MULTU_FUNCT)
            }} & (`ALU_SEL_MULTU))  |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `AND_FUNCT) |
                (id1_op_code == `ANDI_OP_CODE)
            }} & (`ALU_SEL_AND))    |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `NOR_FUNCT)
            }} & (`ALU_SEL_NOR))    |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (id1_funct == `OR_FUNCT)  |
                (id1_op_code == `ORI_OP_CODE)
            }} & (`ALU_SEL_OR))     |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `SLL_FUNCT |
                id1_funct == `SLLV_FUNCT
            )}} & (`ALU_SEL_SLL))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `SRAV_FUNCT|
                id1_funct == `SRA_FUNCT
            )}} & (`ALU_SEL_SRA))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `SRLV_FUNCT|
                id1_funct == `SRL_FUNCT
            )}} & (`ALU_SEL_SRA))   |
            ({6{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `XOR_FUNCT
                )   |
                (id1_op_code == `XORI_OP_CODE)
            }} & (`ALU_SEL_XOR))    |
            ({6{
                (id1_op_code == `LUI_OP_CODE)
            }} & (`ALU_SEL_LUI));

    assign id2_alu_res_sel  =
            ({3{
                (id1_op_code == `COP0_OP_CODE   ) & (
                id1_rs == `MFC0_RS_CODE
            )}} & (`ALU_RES_SEL_CP0))   |
            ({3{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `MFHI_FUNCT
            )}} & (`ALU_RES_SEL_HI))    |
            ({3{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `MFLO_FUNCT
            )}} & (`ALU_RES_SEL_LO))    |
            ({3{
                (id1_op_code == `SPECIAL_OP_CODE) & (
                id1_funct == `JALR_FUNCT
                )   |
                (id1_op_code == `JAL_OP_CODE)   |
                (id1_op_code == `REGIMM_OP_CODE) & (
                id1_rt == `BLTZAL_RT_CODE |
                id1_rt == `BGEZAL_RT_CODE
                )
            }} & (`ALU_RES_SEL_PC_8));

    assign id2_w_reg_ena    = id1_w_reg_ena;

    assign id2_w_hilo_ena   =
            ({2{
                (id1_op_code == `SPECIAL_OP_CODE & (
                    id1_funct == `DIV_FUNCT     |
                    id1_funct == `DIVU_FUNCT    |
                    id1_funct == `MULT_FUNCT    |
                    id1_funct == `MULTU_FUNCT
                )
            )}} & 2'b11) |
            ({2{
                (id1_op_code == `SPECIAL_OP_CODE & (
                    id1_funct == `MTHI_FUNCT
                )
            )}} & 2'b10) |
            ({2{
                (id1_op_code == `SPECIAL_OP_CODE & (
                    id1_funct == `MTLO_FUNCT
                )
            )}}) & 2'b01;
    
    assign id2_w_cp0_ena    =
            (id1_op_code == `COP0_OP_CODE & id1_rs == `MTC0_RS_CODE);

    assign id2_ls_ena       =
            id2_ls_sel != `LS_SEL_NOP;

    assign id2_ls_sel       =   
            ({4{id1_op_code == `LB_OP_CODE  }}) & (`LS_SEL_LB   )    |
            ({4{id1_op_code == `LBU_OP_CODE }}) & (`LS_SEL_LBU  )    |
            ({4{id1_op_code == `LH_OP_CODE  }}) & (`LS_SEL_LH   )    |
            ({4{id1_op_code == `LHU_OP_CODE }}) & (`LS_SEL_LHU  )    |
            ({4{id1_op_code == `LW_OP_CODE  }}) & (`LS_SEL_LW   )    |
            ({4{id1_op_code == `SB_OP_CODE  }}) & (`LS_SEL_SB   )    |
            ({4{id1_op_code == `SH_OP_CODE  }}) & (`LS_SEL_SH   )    |
            ({4{id1_op_code == `SW_OP_CODE  }}) & (`LS_SEL_SW   )    ;

    assign id2_wb_reg_sel   =   
            (id1_op_code == `LB_OP_CODE )   |
            (id1_op_code == `LBU_OP_CODE)   |
            (id1_op_code == `LH_OP_CODE )   |
            (id1_op_code == `LHU_OP_CODE)   |
            (id1_op_code == `LW_OP_CODE )   ;
    
endmodule