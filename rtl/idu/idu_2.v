`timescale 1ns / 1ps

`include "id_def.v"
`include "../exu/branch_def.v"
`include "../utils/forward_def.v"

module idu_2 (
    input  wire             id1_valid,
    input  wire             cp0_has_int,

    input  wire [29:0]      id1_op_codes,
    input  wire [29:0]      id1_func_codes,
    input  wire [31:0]      id1_pc,
    input  wire [4 :0]      id1_rs,
    input  wire [4 :0]      id1_rt,
    input  wire [4 :0]      id1_rd,
    input  wire [4 :0]      id1_sa,
    input  wire             id1_w_reg_ena,
    input  wire [4 :0]      id1_w_reg_dst,
    input  wire [15:0]      id1_imme,
    input  wire [25:0]      id1_j_imme,
    input  wire             id1_is_branch,
    input  wire             id1_is_j_imme,
    input  wire             id1_is_jr,
    input  wire             id1_is_ls,
    input  wire             id1_is_tlbp,
    input  wire             id1_is_tlbr,
    input  wire             id1_is_tlbwi,
    input  wire             id1_in_delay_slot,
    input  wire             id1_inst_adel,
    input  wire             id1_is_i_refill_tlbl,
    input  wire             id1_is_i_invalid_tlbl,
    input  wire             id1_is_refetch,

    input  wire [2 :0]      forward_rs,
    input  wire [2 :0]      forward_rt,
    input  wire [31:0]      exc_alu_res,
    input  wire [31:0]      exp_alu_res,
    input  wire [31:0]      lsu1c_alu_res,
    input  wire [31:0]      lsu1p_alu_res,
    input  wire [31:0]      lsu2c_alu_res,
    input  wire [31:0]      lsu2c_r_data,
    input  wire [31:0]      lsu2p_alu_res,

    // regfile
    output wire             reg_r_ena_1,
    output wire             reg_r_ena_2,
    output wire [4 :0]      reg_r_addr_1,
    output wire [4 :0]      reg_r_addr_2,
    input  wire [31:0]      reg_r_data_1,
    input  wire [31:0]      reg_r_data_2,

    // ====================== //

    // exception signals
    output wire             id2_in_delay_slot,
    output wire             id2_is_eret,
    output wire             id2_is_syscall,
    output wire             id2_is_break,
    output wire             id2_is_inst_adel,
    output wire             id2_is_ri,
    output wire             id2_is_int,
    output wire             id2_is_check_ov,

    // id signals
    output wire             id2_is_ls,
    output wire             id2_is_tlbp,
    output wire             id2_is_tlbr,
    output wire             id2_is_tlbwi,
    output wire             id2_is_i_refill_tlbl,
    output wire             id2_is_i_invalid_tlbl,
    output wire             id2_is_refetch,

    output wire             id2_take_jmp,
    output wire [31:0]      id2_jmp_target,

    // addr signals
    output wire [4 :0]      id2_rs,
    output wire [4 :0]      id2_rt,
    output wire [4 :0]      id2_rd,
    output wire [4 :0]      id2_w_reg_dst,

    // data signals
    output wire [4 :0]      id2_sa,
    output wire [31:0]      id2_rs_data,
    output wire [31:0]      id2_rt_data,
    output wire [31:0]      id2_ext_imme,
    output wire [31:0]      id2_pc,
    
    // control signals
    // output wire             id2_take_branch,
    // output wire             id2_take_j_imme,
    // output wire             id2_take_jr,
    // output wire             id2_flush_req,
    output wire             id2_is_branch,
    output wire             id2_is_j_imme,
    output wire             id2_is_jr,
    output wire [3 :0]      id2_branch_sel,

    output reg  [2 :0]      id2_src_a_sel,
    output reg  [2 :0]      id2_src_b_sel,
    output wire [5 :0]      id2_alu_sel,
    output wire [2 :0]      id2_alu_res_sel,
    output wire             id2_w_reg_ena,
    output wire [1 :0]      id2_w_hilo_ena,
    output wire             id2_w_cp0_ena,
    output wire [7 :0]      id2_w_cp0_addr,
    output wire             id2_ls_ena,
    output wire [3 :0]      id2_ls_sel,
    output wire             id2_wb_reg_sel
);
    wire [15:0]     id2_imme;
    wire [25:0]     id2_j_imme;
    wire [31:0]     id2_branch_target;

    wire op_code_is_special;
    wire op_code_is_special2;
    wire op_code_is_cop0;
    wire op_code_is_regimm;
    wire op_code_is_addi;
    wire op_code_is_addiu;
    wire op_code_is_slti;
    wire op_code_is_sltiu;
    wire op_code_is_andi;
    wire op_code_is_lui;
    wire op_code_is_ori;
    wire op_code_is_xori;
    wire op_code_is_lb;
    wire op_code_is_lh;
    wire op_code_is_lbu;
    wire op_code_is_lhu;
    wire op_code_is_lw;
    wire op_code_is_lwl;
    wire op_code_is_lwr;
    wire op_code_is_jal;
    wire op_code_is_beq;
    wire op_code_is_bne;
    wire op_code_is_bgtz;
    wire op_code_is_blez;
    wire op_code_is_j;
    wire op_code_is_sb;
    wire op_code_is_sh;
    wire op_code_is_sw;
    wire op_code_is_swl;
    wire op_code_is_swr;

    assign {
        op_code_is_special,
        op_code_is_special2,
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
    }   = id1_op_codes;

    wire func_code_is_add;
    wire func_code_is_addu;
    wire func_code_is_sub;
    wire func_code_is_subu;
    wire func_code_is_slt;
    wire func_code_is_sltu;
    wire func_code_is_and;
    wire func_code_is_nor;
    wire func_code_is_or;
    wire func_code_is_xor;
    wire func_code_is_sllv;
    wire func_code_is_sll;
    wire func_code_is_srav;
    wire func_code_is_sra;
    wire func_code_is_srlv;
    wire func_code_is_srl;
    wire func_code_is_jalr;
    wire func_code_is_mfhi;
    wire func_code_is_mflo;
    wire func_code_is_div;
    wire func_code_is_divu;
    wire func_code_is_mul;
    wire func_code_is_mult;
    wire func_code_is_multu;
    wire func_code_is_jr;
    wire func_code_is_mthi;
    wire func_code_is_mtlo;
    wire func_code_is_break;
    wire func_code_is_syscall;
    wire func_code_is_eret;

    assign {
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
        func_code_is_mul,
        func_code_is_mult,
        func_code_is_multu,
        func_code_is_jr,
        func_code_is_mthi,
        func_code_is_mtlo,
        func_code_is_break,
        func_code_is_syscall,
        func_code_is_eret
    }   = id1_func_codes;

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

    // internal signals
    wire sign_ext;

    wire read_rs = 
        op_code_is_addi | op_code_is_addiu  | op_code_is_slti   | op_code_is_sltiu  | op_code_is_andi   | 
        op_code_is_lui  | op_code_is_ori    | op_code_is_xori   | 
        op_code_is_bgtz     | 
        op_code_is_regimm   & (id1_rt == `BGEZ_RT_CODE)     |
        op_code_is_blez     | 
        op_code_is_regimm   & (id1_rt == `BLTZ_RT_CODE)     | 
        op_code_is_regimm   & (id1_rt == `BGEZAL_RT_CODE)   |
        op_code_is_regimm   & (id1_rt == `BLTZAL_RT_CODE)   |
        op_code_is_lb       | op_code_is_lbu    | op_code_is_lh     | op_code_is_lhu | op_code_is_lw | 
        op_code_is_lwl      | op_code_is_lwr    ;

    wire read_both =
        inst_is_special | op_code_is_beq    | op_code_is_bne    | 
        op_code_is_sb   | op_code_is_sh     | op_code_is_sw     |
        op_code_is_swl  | op_code_is_swr    | (op_code_is_special2 & func_code_is_mul);

    assign reg_r_ena_1 = 
        read_both | read_rs;
    
    assign reg_r_ena_2 =
        read_both;

    assign reg_r_addr_1 = id1_rs;
    assign reg_r_addr_2 = id1_rt;

    assign sign_ext = 
            (op_code_is_addi   )   |
            (op_code_is_addiu  )   |
            (op_code_is_slti   )   |
            (op_code_is_sltiu  )   |
            (op_code_is_lb     )   |
            (op_code_is_lbu    )   |
            (op_code_is_lh     )   |
            (op_code_is_lhu    )   |
            (op_code_is_lbu    )   |
            (op_code_is_lw     )   |
            (op_code_is_lwl    )   |
            (op_code_is_lwr    )   |
            (op_code_is_sb     )   |
            (op_code_is_sh     )   |
            (op_code_is_sw     )   |
            (op_code_is_swl    )   |
            (op_code_is_swr    )   ;

    // output signals

    assign id2_in_delay_slot= id1_in_delay_slot;
    assign id2_is_eret      = op_code_is_cop0       & func_code_is_eret     ;
    assign id2_is_syscall   = op_code_is_special    & func_code_is_syscall  ;
    assign id2_is_break     = op_code_is_special    & func_code_is_break    ;
    assign id2_is_inst_adel = id1_inst_adel;
    assign id2_is_ri        = 
            id1_valid & (
                ~inst_is_special & ~inst_is_regimm & ~inst_is_cop0 & ~(|id1_op_codes) & ~id1_is_tlbr & ~id1_is_tlbp & ~id1_is_tlbwi & ~(op_code_is_special2 & func_code_is_mul)
            );
    assign id2_is_int       = cp0_has_int & id1_valid;

    assign id2_is_check_ov  = 
            op_code_is_special  & func_code_is_add  |
            op_code_is_special  & func_code_is_sub  |
            op_code_is_addi; 

    assign id2_is_branch        = id1_is_branch;    
    assign id2_is_j_imme        = id1_is_j_imme;    
    assign id2_is_jr            = id1_is_jr;
    assign id2_is_ls            = id1_is_ls;
    assign id2_is_tlbp          = id1_is_tlbp;
    assign id2_is_tlbr          = id1_is_tlbr;
    assign id2_is_tlbwi         = id1_is_tlbwi;
    assign id2_is_i_refill_tlbl = id1_is_i_refill_tlbl;
    assign id2_is_i_invalid_tlbl= id1_is_i_invalid_tlbl;
    assign id2_is_refetch       = id1_is_refetch;

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
                !(forward_rs ^ `FORWARD_NOP)
            }} & reg_r_data_1   )   |
            ({32{
                !(forward_rs ^ `FORWARD_EXC_ALU_RES)
            }} & exc_alu_res    )   |
            ({32{
                !(forward_rs ^ `FORWARD_EXP_ALU_RES)
            }} & exp_alu_res    )   |
            ({32{
                !(forward_rs ^ `FORWARD_LS1P_ALU_RES)
            }} & lsu1p_alu_res  )   |
            ({32{
                !(forward_rs ^ `FORWARD_LS1C_ALU_RES)
            }} & lsu1c_alu_res  )   |
            ({32{
                !(forward_rs ^ `FORWARD_LS2C_ALU_RES)
            }} & lsu2c_alu_res  )   |
            ({32{
                !(forward_rs ^ `FORWARD_LS2C_MEM_DATA)
            }} & lsu2c_r_data   )   |
            ({32{
                !(forward_rs ^ `FORWARD_LS2P_ALU_RES)
            }} & lsu2p_alu_res)     ;
    
    assign id2_rt_data      =
            ({32{
                !(forward_rt ^ `FORWARD_NOP)
            }} & reg_r_data_2   )   |
            ({32{
                !(forward_rt ^ `FORWARD_EXC_ALU_RES)
            }} & exc_alu_res    )   |
            ({32{
                !(forward_rt ^ `FORWARD_EXP_ALU_RES)
            }} & exp_alu_res    )   |
            ({32{
                !(forward_rt ^ `FORWARD_LS1P_ALU_RES)
            }} & lsu1p_alu_res  )   |
            ({32{
                !(forward_rt ^ `FORWARD_LS1C_ALU_RES)
            }} & lsu1c_alu_res  )   |
            ({32{
                !(forward_rt ^ `FORWARD_LS2C_ALU_RES)
            }} & lsu2c_alu_res  )   |
            ({32{
                !(forward_rt ^ `FORWARD_LS2C_MEM_DATA)
            }} & lsu2c_r_data   )   |
            ({32{
                !(forward_rt ^ `FORWARD_LS2P_ALU_RES)
            }} & lsu2p_alu_res)     ;
            
    assign id2_branch_sel = 
            {4{
                op_code_is_beq
            }} & (`BRANCH_SEL_BEQ   )   |
            {4{
                op_code_is_bne
            }} & (`BRANCH_SEL_BNE   )   |
            {4{
                op_code_is_regimm & !(id1_rt   ^ `BGEZ_RT_CODE )
            }} & (`BRANCH_SEL_BGEZ  )   |
            {4{
                op_code_is_bgtz
            }} & (`BRANCH_SEL_BGTZ  )   |
            {4{
                op_code_is_blez
            }} & (`BRANCH_SEL_BLEZ  )   |
            {4{
                op_code_is_regimm & !(id1_rt   ^ `BLTZ_RT_CODE  )
            }} & (`BRANCH_SEL_BLTZ  )   |
            {4{
                op_code_is_regimm & !(id1_rt   ^ `BGEZAL_RT_CODE)
            }} & (`BRANCH_SEL_BGEZAL)   |
            {4{
                op_code_is_regimm & !(id1_rt   ^ `BLTZAL_RT_CODE)
            }} & (`BRANCH_SEL_BLTZAL)   ;

    assign id2_branch_target    = id1_pc + 32'h4 + {{14{id1_imme[15]}}, id1_imme[15:0], 2'b00};

    always @(*) begin
        if (op_code_is_special & (
            func_code_is_sll   |
            func_code_is_sra   |
            func_code_is_srl   |
            func_code_is_sllv  |
            func_code_is_srav  |
            func_code_is_srlv  
        )) begin
            id2_src_a_sel = `SRC_A_SEL_RT;
        end else begin
            id2_src_a_sel = `SRC_A_SEL_RS;
        end
    end

    always @(*) begin
        if ((op_code_is_special) & (
            func_code_is_add       |
            func_code_is_addu      |
            func_code_is_sub       |
            func_code_is_subu      |
            func_code_is_slt       |
            func_code_is_sltu      |
            func_code_is_div       |
            func_code_is_divu      |
            func_code_is_mult      |
            func_code_is_multu     |
            func_code_is_and       |
            func_code_is_nor       |
            func_code_is_or        |
            func_code_is_xor
        ) | (op_code_is_special2)& (
            func_code_is_mul
        )) begin
            id2_src_b_sel = `SRC_B_SEL_RT;
        end else if (
            op_code_is_addi     |
            op_code_is_addiu    |
            op_code_is_slti     |
            op_code_is_sltiu    |
            op_code_is_andi     |
            op_code_is_lui      |
            op_code_is_ori      |
            op_code_is_xori     |

            op_code_is_lbu      |
            op_code_is_lb       |
            op_code_is_lh       |
            op_code_is_lhu      |
            op_code_is_lw       |
            op_code_is_sb       |
            op_code_is_sh       |
            op_code_is_sw       |
            op_code_is_swl      |
            op_code_is_swr      |
            op_code_is_lwl      |
            op_code_is_lwr
        ) begin
            id2_src_b_sel = `SRC_B_SEL_IMME;
        end else if (op_code_is_special & (
            func_code_is_sllv      |
            func_code_is_srav      |
            func_code_is_srlv      
        )) begin
            id2_src_b_sel = `SRC_B_SEL_RS;
        end else if (op_code_is_special & (
            func_code_is_sll       |
            func_code_is_sra       |
            func_code_is_srl
        )) begin
            id2_src_b_sel = `SRC_B_SEL_SA;
        end else begin
            id2_src_b_sel = `SRC_B_SEL_NOP;
        end
    end

    assign id2_alu_sel = 
            ({6{
                (op_code_is_special) & (
                func_code_is_add     |
                func_code_is_addu
                )   |
                (op_code_is_addi    )   |
                (op_code_is_addiu   )   |
                (op_code_is_lb      )   |
                (op_code_is_lbu     )   |
                (op_code_is_lh      )   |
                (op_code_is_lhu     )   |
                (op_code_is_lw      )   |
                (op_code_is_lwl     )   |
                (op_code_is_lwr     )   |
                (op_code_is_sb      )   |
                (op_code_is_sh      )   |
                (op_code_is_sw      )   |
                (op_code_is_swl     )   |
                (op_code_is_swr     )
            }} & (`ALU_SEL_ADD))    |
            ({6{
                (op_code_is_special) & (
                func_code_is_sub     |
                func_code_is_subu
            )}} & (`ALU_SEL_SUB))   |
            ({6{
                (op_code_is_special) & (func_code_is_slt) |
                (op_code_is_slti)
            }} & (`ALU_SEL_SLT))    |
            ({6{
                (op_code_is_special) & (func_code_is_sltu)|
                (op_code_is_sltiu)
            }} & (`ALU_SEL_SLTU))   |
            ({6{
                (op_code_is_special) & (func_code_is_div)
            }} & (`ALU_SEL_DIV))    |
            ({6{
                (op_code_is_special) & (func_code_is_divu)
            }} & (`ALU_SEL_DIVU))   |
            ({6{
                (op_code_is_special2) & (func_code_is_mul)
            }} & (`ALU_SEL_MUL))    |
            ({6{
                (op_code_is_special) & (func_code_is_mult)
            }} & (`ALU_SEL_MULT))   |
            ({6{
                (op_code_is_special) & (func_code_is_multu)
            }} & (`ALU_SEL_MULTU))  |
            ({6{
                (op_code_is_special) & (func_code_is_and) |
                (op_code_is_andi)
            }} & (`ALU_SEL_AND))    |
            ({6{
                (op_code_is_special) & (func_code_is_nor)
            }} & (`ALU_SEL_NOR))    |
            ({6{
                (op_code_is_special) & (func_code_is_or)  |
                (op_code_is_ori)
            }} & (`ALU_SEL_OR))     |
            ({6{
                (op_code_is_special) & (
                func_code_is_sll |
                func_code_is_sllv
            )}} & (`ALU_SEL_SLL))   |
            ({6{
                (op_code_is_special) & (
                func_code_is_srav|
                func_code_is_sra
            )}} & (`ALU_SEL_SRA))   |
            ({6{
                (op_code_is_special) & (
                func_code_is_srlv|
                func_code_is_srl
            )}} & (`ALU_SEL_SRL))   |
            ({6{
                (op_code_is_special) & (
                func_code_is_xor
                )   |
                (op_code_is_xori)
            }} & (`ALU_SEL_XOR))    |
            ({6{
                (op_code_is_lui)
            }} & (`ALU_SEL_LUI))    |
            ({6{
                (op_code_is_special) & (
                func_code_is_mthi
                )
            }} & (`ALU_SEL_MTHI))   |
            ({6{
                (op_code_is_special) & (
                func_code_is_mtlo
                )
            }} & (`ALU_SEL_MTLO))   ;

    assign id2_alu_res_sel  =
            ({3{
                (op_code_is_cop0   ) & (
                !(id1_rs ^ `MFC0_RS_CODE)
            )}} & (`ALU_RES_SEL_CP0))   |
            ({3{
                (op_code_is_special) & (
                func_code_is_mfhi
            )}} & (`ALU_RES_SEL_HI))    |
            ({3{
                (op_code_is_special) & (
                func_code_is_mflo
            )}} & (`ALU_RES_SEL_LO))    |
            ({3{
                (op_code_is_special) & (
                func_code_is_jalr
                )   |
                (op_code_is_jal)   |
                (op_code_is_regimm) & (
                id1_rt == `BLTZAL_RT_CODE |
                id1_rt == `BGEZAL_RT_CODE
                )
            }} & (`ALU_RES_SEL_PC_8));

    assign id2_w_reg_ena    = id1_w_reg_ena;

    assign id2_w_hilo_ena   =
            ({2{
                (op_code_is_special & (
                    func_code_is_div     |
                    func_code_is_divu    |
                    func_code_is_mult    |
                    func_code_is_multu
                )
            )}} & 2'b11) |
            ({2{
                (op_code_is_special & (
                    func_code_is_mthi
                )
            )}} & 2'b10) |
            ({2{
                (op_code_is_special & (
                    func_code_is_mtlo
                )
            )}}) & 2'b01;
    
    assign id2_w_cp0_ena    =
            (op_code_is_cop0 & !(id1_rs ^ `MTC0_RS_CODE));
    assign id2_w_cp0_addr   =
            {id1_rd, id1_imme[2:0]};

    assign id2_ls_ena       =
            id2_ls_sel != `LS_SEL_NOP;

    assign id2_ls_sel       =   
            ({4{op_code_is_lb  }}) & (`LS_SEL_LB   )   |
            ({4{op_code_is_lbu }}) & (`LS_SEL_LBU  )   |
            ({4{op_code_is_lh  }}) & (`LS_SEL_LH   )   |
            ({4{op_code_is_lhu }}) & (`LS_SEL_LHU  )   |
            ({4{op_code_is_lw  }}) & (`LS_SEL_LW   )   |
            ({4{op_code_is_sb  }}) & (`LS_SEL_SB   )   |
            ({4{op_code_is_sh  }}) & (`LS_SEL_SH   )   |
            ({4{op_code_is_sw  }}) & (`LS_SEL_SW   )   |
            ({4{op_code_is_swl }}) & (`LS_SEL_SWL  )   |
            ({4{op_code_is_swr }}) & (`LS_SEL_SWR  )   |
            ({4{op_code_is_lwl }}) & (`LS_SEL_LWL  )   |
            ({4{op_code_is_lwr }}) & (`LS_SEL_LWR  )   ;

    assign id2_wb_reg_sel   =   
            (op_code_is_lb )   |
            (op_code_is_lbu)   |
            (op_code_is_lh )   |
            (op_code_is_lhu)   |
            (op_code_is_lw )   |
            (op_code_is_lwr)   |
            (op_code_is_lwl)   ;

    assign id2_jmp_target   =
            {32{id2_is_j_imme   }} & {id2_pc[31:28], id2_j_imme, 2'b00} |
            {32{id2_is_jr       }} & {id2_rs_data}                      |
            {32{id2_is_branch   }} & {id2_branch_target}                ;

endmodule