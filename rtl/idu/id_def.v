// op code
`define SPECIAL_OP_CODE     6'b000_000
`define REGIMM_OP_CODE      6'b000_001
`define COP0_OP_CODE        6'b010_000
// funct code
`define ADD_FUNCT           6'b100_000
`define ADDU_FUNCT          6'b100_001
`define SUB_FUNCT           6'b100_010
`define SUBU_FUNCT          6'b100_011
`define SLT_FUNCT           6'b101_010
`define SLTU_FUNCT          6'b101_011
`define DIV_FUNCT           6'b011_010
`define DIVU_FUNCT          6'b011_011
`define MULT_FUNCT          6'b011_000
`define MULTU_FUNCT         6'b011_001
`define AND_FUNCT           6'b100_100
`define NOR_FUNCT           6'b100_111
`define OR_FUNCT            6'b100_101
`define XOR_FUNCT           6'b100_110
`define SLLV_FUNCT          6'b000_100
`define SLL_FUNCT           6'b000_000
`define SRAV_FUNCT          6'b000_111
`define SRA_FUNCT           6'b000_011
`define SRLV_FUNCT          6'b000_110
`define SRL_FUNCT           6'b000_010
`define JR_FUNCT            6'b001_000
`define JALR_FUNCT          6'b001_001
`define MFHI_FUNCT          6'b010_000
`define MFLO_FUNCT          6'b010_010
`define MTHI_FUNCT          6'b010_001
`define MTLO_FUNCT          6'b010_011
`define BREAK_FUNCT         6'b001_101
`define SYSCALL_FUNCT       6'b001_100

`define ERET_FUNCT          6'b011_000

// =================================== //

// imme
`define ADDI_OP_CODE        6'b001_000
`define ADDIU_OP_CODE       6'b001_001
`define SLTI_OP_CODE        6'b001_010
`define SLTIU_OP_CODE       6'b001_011
`define ANDI_OP_CODE        6'b001_100
`define LUI_OP_CODE         6'b001_111
`define ORI_OP_CODE         6'b001_101
`define XORI_OP_CODE        6'b001_110

// ls
`define LB_OP_CODE          6'b100_000
`define LBU_OP_CODE         6'b100_100
`define LH_OP_CODE          6'b100_001
`define LHU_OP_CODE         6'b100_101
`define LW_OP_CODE          6'b100_011
`define SB_OP_CODE          6'b101_000
`define SH_OP_CODE          6'b101_001
`define SW_OP_CODE          6'b101_011

// jmp
`define BEQ_OP_CODE         6'b000_100
`define BNE_OP_CODE         6'b000_101
`define BGTZ_OP_CODE        6'b000_111
`define BLEZ_OP_CODE        6'b000_110
`define J_OP_CODE           6'b000_010
`define JAL_OP_CODE         6'b000_011

// jmp rt code
`define BGEZ_RT_CODE        6'b000_01
`define BLTZ_RT_CODE        6'b000_00
`define BGEZAL_RT_CODE      6'b100_01
`define BLTZAL_RT_CODE      6'b100_00

// cp0 rs code
`define MFC0_RS_CODE        6'b000_00
`define MTC0_RS_CODE        6'b001_00

// ================================== //

`define ALU_SEL_NOP         6'h0
`define ALU_SEL_ADD         6'h1
`define ALU_SEL_SUB         6'h2
`define ALU_SEL_SLT         6'h3
`define ALU_SEL_SLTU        6'h4
`define ALU_SEL_DIV         6'h5
`define ALU_SEL_DIVU        6'h6
`define ALU_SEL_MULT        6'h7
`define ALU_SEL_MULTU       6'h8
`define ALU_SEL_AND         6'h9
`define ALU_SEL_NOR         6'ha
`define ALU_SEL_OR          6'hb
`define ALU_SEL_XOR         6'hc
`define ALU_SEL_SLL         6'hd
`define ALU_SEL_SRA         6'he
`define ALU_SEL_SRL         6'hf
`define ALU_SEL_LUI         6'h10

// ================================== //

// control signals

`define SRC_A_SEL_NOP       3'b000
`define SRC_A_SEL_ZERO      3'b000
`define SRC_A_SEL_RS        3'b001
`define SRC_A_SEL_RT        3'b010

`define SRC_B_SEL_NOP       3'b000
`define SRC_B_SEL_ZERO      3'b000
`define SRC_B_SEL_RT        3'b001
`define SRC_B_SEL_IMME      3'b010
`define SRC_B_SEL_RS        3'b011
`define SRC_B_SEL_SA        3'b100

`define ALU_RES_SEL_ALU     3'b000
`define ALU_RES_SEL_HI      3'b001
`define ALU_RES_SEL_LO      3'b010
`define ALU_RES_SEL_PC_8    3'b011
`define ALU_RES_SEL_CP0     3'b100    

`define LS_SEL_NOP          4'h0
`define LS_SEL_LB           4'h1
`define LS_SEL_LBU          4'h2
`define LS_SEL_LH           4'h3
`define LS_SEL_LHU          4'h4
`define LS_SEL_LW           4'h5
`define LS_SEL_SB           4'h6
`define LS_SEL_SH           4'h7
`define LS_SEL_SW           4'h8
