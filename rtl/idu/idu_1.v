`timescale 1ns / 1ps

`include "id_def.v"

module idu_1 (
    input   wire [31:0]     inst,
    output  wire [28:0]     id1_op_codes,
    output  wire [28:0]     id1_func_codes,
    output  wire [4 :0]     id1_rs,
    output  wire [4 :0]     id1_rt,
    output  wire [4 :0]     id1_rd,
    output  wire [4 :0]     id1_sa,
    output  wire            id1_w_reg_ena,
    output  wire [4 :0]     id1_w_reg_dst,
    output  wire [15:0]     id1_imme,
    output  wire [25:0]     id1_j_imme,
    output  wire            id1_is_branch,
    output  wire            id1_is_j_imme,
    output  wire            id1_is_jr,
    output  wire            id1_is_ls,
    output  wire            id1_is_cop0,
    output  wire            id1_is_tlbp,
    output  wire            id1_is_tlbr,
    output  wire            id1_is_tlbwi,
    output  wire            id1_is_check_ov,
    output  wire            id1_is_ri,

    output  wire            id1_is_hilo
);
    wire [5 :0] id1_op_code;
    wire [5 :0] id1_funct;
    assign id1_op_code   = inst[31:26];
    assign id1_rs        = inst[25:21];
    assign id1_rt        = inst[20:16];
    assign id1_rd        = inst[15:11];
    assign id1_sa        = inst[10: 6];
    assign id1_funct     = inst[5 : 0];
    assign id1_imme      = inst[15: 0];
    assign id1_j_imme    = inst[25: 0];

    wire op_code_is_special =   !(id1_op_code   ^ `SPECIAL_OP_CODE    );
    wire op_code_is_cop0    =   !(id1_op_code   ^ `COP0_OP_CODE       );
    wire op_code_is_regimm  =   !(id1_op_code   ^ `REGIMM_OP_CODE     );
    wire op_code_is_addi    =   !(id1_op_code   ^ `ADDI_OP_CODE       );
    wire op_code_is_addiu   =   !(id1_op_code   ^ `ADDIU_OP_CODE      );
    wire op_code_is_slti    =   !(id1_op_code   ^ `SLTI_OP_CODE       );
    wire op_code_is_sltiu   =   !(id1_op_code   ^ `SLTIU_OP_CODE      );
    wire op_code_is_andi    =   !(id1_op_code   ^ `ANDI_OP_CODE       );
    wire op_code_is_lui     =   !(id1_op_code   ^ `LUI_OP_CODE        );
    wire op_code_is_ori     =   !(id1_op_code   ^ `ORI_OP_CODE        );
    wire op_code_is_xori    =   !(id1_op_code   ^ `XORI_OP_CODE       );
    wire op_code_is_lb      =   !(id1_op_code   ^ `LB_OP_CODE         );
    wire op_code_is_lh      =   !(id1_op_code   ^ `LH_OP_CODE         );
    wire op_code_is_lbu     =   !(id1_op_code   ^ `LBU_OP_CODE        );
    wire op_code_is_lhu     =   !(id1_op_code   ^ `LHU_OP_CODE        );
    wire op_code_is_lw      =   !(id1_op_code   ^ `LW_OP_CODE         );
    wire op_code_is_lwl     =   !(id1_op_code   ^ `LWL_OP_CODE        );
    wire op_code_is_lwr     =   !(id1_op_code   ^ `LWR_OP_CODE        );
    wire op_code_is_jal     =   !(id1_op_code   ^ `JAL_OP_CODE        );
    wire op_code_is_beq     =   !(id1_op_code   ^ `BEQ_OP_CODE        );
    wire op_code_is_bne     =   !(id1_op_code   ^ `BNE_OP_CODE        );
    wire op_code_is_bgtz    =   !(id1_op_code   ^ `BGTZ_OP_CODE       );
    wire op_code_is_blez    =   !(id1_op_code   ^ `BLEZ_OP_CODE       );
    wire op_code_is_j       =   !(id1_op_code   ^ `J_OP_CODE          );
    wire op_code_is_sb      =   !(id1_op_code   ^ `SB_OP_CODE         );
    wire op_code_is_sh      =   !(id1_op_code   ^ `SH_OP_CODE         );
    wire op_code_is_sw      =   !(id1_op_code   ^ `SW_OP_CODE         );
    wire op_code_is_swl     =   !(id1_op_code   ^ `SWL_OP_CODE        );
    wire op_code_is_swr     =   !(id1_op_code   ^ `SWR_OP_CODE        );
    
    assign id1_op_codes = {
        op_code_is_special,
        op_code_is_cop0,
        op_code_is_regimm,
        op_code_is_addi,
        op_code_is_addiu,
        op_code_is_slti,
        op_code_is_sltiu,
        op_code_is_andi,
        op_code_is_lui,
        op_code_is_ori,
        op_code_is_xori,
        op_code_is_lb,
        op_code_is_lh,
        op_code_is_lbu,
        op_code_is_lhu,
        op_code_is_lw,
        op_code_is_lwl,
        op_code_is_lwr,
        op_code_is_jal,
        op_code_is_beq,
        op_code_is_bne,
        op_code_is_bgtz,
        op_code_is_blez,
        op_code_is_j,
        op_code_is_sb,
        op_code_is_sh,
        op_code_is_sw,
        op_code_is_swl,
        op_code_is_swr
    };

    wire func_code_is_add       =   !(id1_funct ^ `ADD_FUNCT    );
    wire func_code_is_addu      =   !(id1_funct ^ `ADDU_FUNCT   );
    wire func_code_is_sub       =   !(id1_funct ^ `SUB_FUNCT    );
    wire func_code_is_subu      =   !(id1_funct ^ `SUBU_FUNCT   );
    wire func_code_is_slt       =   !(id1_funct ^ `SLT_FUNCT    );
    wire func_code_is_sltu      =   !(id1_funct ^ `SLTU_FUNCT   );
    wire func_code_is_and       =   !(id1_funct ^ `AND_FUNCT    );
    wire func_code_is_nor       =   !(id1_funct ^ `NOR_FUNCT    );
    wire func_code_is_or        =   !(id1_funct ^ `OR_FUNCT     );
    wire func_code_is_xor       =   !(id1_funct ^ `XOR_FUNCT    );
    wire func_code_is_sllv      =   !(id1_funct ^ `SLLV_FUNCT   );
    wire func_code_is_sll       =   !(id1_funct ^ `SLL_FUNCT    );
    wire func_code_is_srav      =   !(id1_funct ^ `SRAV_FUNCT   );
    wire func_code_is_sra       =   !(id1_funct ^ `SRA_FUNCT    );
    wire func_code_is_srlv      =   !(id1_funct ^ `SRLV_FUNCT   );
    wire func_code_is_srl       =   !(id1_funct ^ `SRL_FUNCT    );
    wire func_code_is_jalr      =   !(id1_funct ^ `JALR_FUNCT   );
    wire func_code_is_mfhi      =   !(id1_funct ^ `MFHI_FUNCT   );
    wire func_code_is_mflo      =   !(id1_funct ^ `MFLO_FUNCT   );
    wire func_code_is_div       =   !(id1_funct ^ `DIV_FUNCT    );
    wire func_code_is_divu      =   !(id1_funct ^ `DIVU_FUNCT   );
    wire func_code_is_mult      =   !(id1_funct ^ `MULT_FUNCT   );
    wire func_code_is_multu     =   !(id1_funct ^ `MULTU_FUNCT  );
    wire func_code_is_jr        =   !(id1_funct ^ `JR_FUNCT     );
    wire func_code_is_mthi      =   !(id1_funct ^ `MTHI_FUNCT   );
    wire func_code_is_mtlo      =   !(id1_funct ^ `MTLO_FUNCT   );
    wire func_code_is_break     =   !(id1_funct ^ `BREAK_FUNCT  );
    wire func_code_is_syscall   =   !(id1_funct ^ `SYSCALL_FUNCT);
    wire func_code_is_eret      =   !(id1_funct ^ `ERET_FUNCT   );

    assign id1_func_codes = {
        func_code_is_add,
        func_code_is_addu,
        func_code_is_sub,
        func_code_is_subu,
        func_code_is_slt,
        func_code_is_sltu,
        func_code_is_and,
        func_code_is_nor,
        func_code_is_or,
        func_code_is_xor,
        func_code_is_sllv,
        func_code_is_sll,
        func_code_is_srav,
        func_code_is_sra,
        func_code_is_srlv,
        func_code_is_srl,
        func_code_is_jalr,
        func_code_is_mfhi,
        func_code_is_mflo,
        func_code_is_div,
        func_code_is_divu,
        func_code_is_mult,
        func_code_is_multu,
        func_code_is_jr,
        func_code_is_mthi,
        func_code_is_mtlo,
        func_code_is_break,
        func_code_is_syscall,
        func_code_is_eret
    };

    assign id1_w_reg_dst    =
            ({5{
                (op_code_is_special) & (
                    func_code_is_add     |
                    func_code_is_addu    |
                    func_code_is_sub     |
                    func_code_is_subu    |
                    func_code_is_slt     |
                    func_code_is_sltu    |
                    func_code_is_and     |
                    func_code_is_nor     |
                    func_code_is_or      |
                    func_code_is_xor     |
                    func_code_is_sllv    |
                    func_code_is_sll     |
                    func_code_is_srav    |
                    func_code_is_sra     |
                    func_code_is_srlv    |
                    func_code_is_srl     |
                    func_code_is_jalr    |
                    func_code_is_mfhi    |
                    func_code_is_mflo    
                )
            }} & id1_rd) |
            ({5{
                (op_code_is_addi   )   |
                (op_code_is_addiu  )   |
                (op_code_is_slti   )   |
                (op_code_is_sltiu  )   |
                (op_code_is_andi   )   |
                (op_code_is_lui    )   |
                (op_code_is_ori    )   |
                (op_code_is_xori   )   |
                (op_code_is_lb     )   |
                (op_code_is_lh     )   |
                (op_code_is_lbu    )   |
                (op_code_is_lhu    )   |
                (op_code_is_lw     )   |
                (op_code_is_lwl    )   |
                (op_code_is_lwr    )   |
                (op_code_is_cop0 & !(id1_rs ^ `MFC0_RS_CODE))
            }} & id1_rt) |
            ({5{
                (op_code_is_regimm) & (
                    !(id1_rt ^ `BGEZAL_RT_CODE)   |
                    !(id1_rt ^ `BLTZAL_RT_CODE   )
                ) |
                (op_code_is_jal)
            }} & 5'd31 ) ;

    assign id1_is_branch    =
            (op_code_is_beq    )   |
            (op_code_is_bne    )   |
            (op_code_is_regimm )   |
            (op_code_is_bgtz   )   |
            (op_code_is_blez   )   ;
            
    assign id1_is_j_imme    = 
            (op_code_is_j      )   |
            (op_code_is_jal    )   ;

    assign id1_is_jr        = 
            (op_code_is_special & (
                func_code_is_jr  |
                func_code_is_jalr
            ));

    assign id1_is_ls        = 
            op_code_is_lbu  |
            op_code_is_lb   |
            op_code_is_lh   |
            op_code_is_lhu  |
            op_code_is_lw   |
            op_code_is_sb   |
            op_code_is_sh   |
            op_code_is_sw   |
            op_code_is_swl  |
            op_code_is_swr  |
            op_code_is_lwl  |
            op_code_is_lwr  ;

    assign id1_is_cop0      =
            op_code_is_cop0                             |
            op_code_is_special & func_code_is_break     |
            op_code_is_special & func_code_is_syscall   ;

    assign id1_is_hilo      =
            (op_code_is_special & (
                func_code_is_div     |
                func_code_is_divu    |
                func_code_is_mult    |
                func_code_is_multu   |
                func_code_is_mfhi    |
                func_code_is_mflo    |
                func_code_is_mthi    |
                func_code_is_mtlo    
            ));
    
    assign id1_is_tlbp  =
        !(inst ^ {`COP0_OP_CODE, 1'b1, 19'h0, 6'b001_000});
    assign id1_is_tlbr  =
        !(inst ^ {`COP0_OP_CODE, 1'b1, 19'h0, 6'b000_001});
    assign id1_is_tlbwi =
        !(inst ^ {`COP0_OP_CODE, 1'b1, 19'h0, 6'b000_010});

    assign id1_w_reg_ena    = 
            !(op_code_is_special & func_code_is_div     )   &
            !(op_code_is_special & func_code_is_divu    )   &
            !(op_code_is_special & func_code_is_mult    )   &
            !(op_code_is_special & func_code_is_multu   )   &
            !(op_code_is_special & func_code_is_jr      )   &
            !(op_code_is_special & func_code_is_mthi    )   &
            !(op_code_is_special & func_code_is_mtlo    )   &
            !(op_code_is_special & func_code_is_break   )   &
            !(op_code_is_special & func_code_is_syscall )   &
            !(op_code_is_special & func_code_is_eret    )   &
            !(op_code_is_beq   )  &
            !(op_code_is_bne   )  &
            !(op_code_is_bgtz  )  &
            !(op_code_is_blez  )  &
            !(op_code_is_j     )  &
            !(op_code_is_sb    )  &
            !(op_code_is_sh    )  &
            !(op_code_is_sw    )  &
            !(op_code_is_swl   )  &
            !(op_code_is_swr   )  &
            !(op_code_is_regimm & !(id1_rt ^ `BGEZ_RT_CODE)  )   &
            !(op_code_is_regimm & !(id1_rt ^ `BLTZ_RT_CODE)  )   &
            // I can't believe the trace miss this bug...
            !(op_code_is_cop0   & !(id1_rs ^ `MTC0_RS_CODE)  )   &
            (id1_w_reg_dst != 5'h0);

    assign id1_is_check_ov  = 
        op_code_is_special  & func_code_is_add  |
        op_code_is_special  & func_code_is_sub  |
        op_code_is_addi; 
    
    wire inst_is_special    = 
            op_code_is_special  & (|id1_func_codes);
    wire inst_is_regimm     = 
            op_code_is_regimm   & (
                ~(id1_rt ^ `BGEZ_RT_CODE   ) |    
                ~(id1_rt ^ `BLTZ_RT_CODE   ) |
                ~(id1_rt ^ `BGEZAL_RT_CODE ) |
                ~(id1_rt ^ `BLTZAL_RT_CODE )  
            );
    wire inst_is_cop0       =
            op_code_is_cop0     & (
                ~(id1_rs ^ `MTC0_RS_CODE) |
                ~(id1_rs ^ `MFC0_RS_CODE)
            );

    assign id1_is_ri        =
        ~inst_is_special & ~inst_is_regimm & ~inst_is_cop0 & ~(|id1_op_codes);

endmodule