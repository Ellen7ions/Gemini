`timescale 1ns / 1ps

`include "../idu/id_def.v"
`include "../utils/forward_def.v"

module ex_c (
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
    input   wire            id2_is_tlbp,
    input   wire            id2_is_tlbr,
    input   wire            id2_is_tlbwi,
    input   wire            id2_is_tlbwr,

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
    input   wire [31:0]     lsu1c_hi_res,
    input   wire [31:0]     lsu1c_lo_res,
    input   wire [31:0]     lsu2c_hi_res,
    input   wire [31:0]     lsu2c_lo_res,
    // cp0
    output  wire            ex_cp0_r_ena,
    output  wire [7 :0]     ex_cp0_r_addr,
    input   wire [31:0]     ex_cp0_r_data,
    output  wire            ex_cp0_stall,

    input   wire            lsu1_w_cp0_ena,
    input   wire [7 :0]     lsu1_w_cp0_addr,
    input   wire            lsu2_w_cp0_ena,
    input   wire [7 :0]     lsu2_w_cp0_addr,

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
    output  wire            ex_ls_or,
    output  wire [31:0]     ex_ls_addr,
    output  wire [1 :0]     ex_w_hilo_ena,  // ?
    output  wire [31:0]     ex_hi_res,
    output  wire [31:0]     ex_lo_res,

    output  wire            ex_has_exception,

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
    output  wire            ex_is_tlbwr,

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
    assign ex_is_data_adel  = 
        ex_ls_ena & (
            !(ex_ls_sel ^ `LS_SEL_LH )  &  (ex_ls_addr[0]                   )   |
            !(ex_ls_sel ^ `LS_SEL_LHU)  &  (ex_ls_addr[0]                   )   |
            !(ex_ls_sel ^ `LS_SEL_LW )  &  (ex_ls_addr[1] | ex_ls_addr[0]   )   
        );
    assign ex_is_data_ades  =
        ex_ls_ena & (
            !(ex_ls_sel ^ `LS_SEL_SH)   &  (ex_ls_addr[0]                   )   |
            !(ex_ls_sel ^ `LS_SEL_SW)   &  (ex_ls_addr[1] | ex_ls_addr[0]   )   
        );
    assign ex_is_ri         = id2_is_ri;
    assign ex_is_overflow   = id2_is_check_ov & alu_overflow;
    assign ex_is_int        = id2_is_int;

    assign ex_is_i_refill_tlbl  = id2_is_i_refill_tlbl;
    assign ex_is_i_invalid_tlbl = id2_is_i_invalid_tlbl;
    assign ex_is_refetch        = id2_is_refetch;

    assign ex_is_tlbp           = id2_is_tlbp;
    assign ex_is_tlbr           = id2_is_tlbr;
    assign ex_is_tlbwi          = id2_is_tlbwi;
    assign ex_is_tlbwr          = id2_is_tlbwr;

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
                !(forward_hi ^ `FORWARD_LS1C_HI)
            }} & lsu1c_hi_res   )   |
            ({32{
                !(forward_hi ^ `FORWARD_LS2C_HI)
            }} & lsu2c_hi_res   )   |
            ({32{
                !(forward_hi ^ `FORWARD_HILI_NOP)
            }} & hilo_hi    )   ;
    
    assign fw_lo        =
            ({32{
                !(forward_lo ^ `FORWARD_LS1C_LO)
            }} & lsu1c_lo_res   )   |
            ({32{
                !(forward_lo ^ `FORWARD_LS2C_LO)
            }} & lsu2c_lo_res   )   |
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

    wire [31:0] cp0_r_data = ex_cp0_r_data;

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
            }} & cp0_r_data);
    
    assign ex_ls_addr   =
            {32{id2_ls_ena}} & (id2_rs_data + id2_ext_imme);
    
    assign ex_ls_or     =
            ex_ls_sel[3];
    
    assign ex_cp0_r_addr    = id2_w_cp0_addr;
    assign ex_cp0_r_ena     = !(id2_alu_res_sel ^ `ALU_RES_SEL_CP0);
    assign ex_cp0_stall     = 
        ex_cp0_r_ena & (lsu1_w_cp0_ena & (lsu1_w_cp0_addr == ex_cp0_r_addr) | lsu2_w_cp0_ena & (lsu2_w_cp0_addr == ex_cp0_r_addr));

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

    // always @(*) begin
    //     ex_w_cp0_data           = 32'h0;
    //     case (id2_w_cp0_addr)
    //     {5'd9, 3'd0}: begin
    //         ex_w_cp0_data       = id2_rt_data;
    //     end

    //     {5'd11, 3'd0}: begin
    //         ex_w_cp0_data       = id2_rt_data;
    //     end

    //     {5'd12, 3'd0}: begin
    //         ex_w_cp0_data[15:8] = id2_rt_data[15:8];
    //         ex_w_cp0_data[1]    = id2_rt_data[1];
    //         ex_w_cp0_data[0]    = id2_rt_data[0];
    //     end

    //     {5'd13, 3'd0}: begin
    //         ex_w_cp0_data[9 :8] = id2_rt_data[9 :8];
    //     end

    //     {5'd14, 3'd0}: begin
    //         ex_w_cp0_data       = id2_rt_data;
    //     end

    //     {5'd0, 3'd0}: begin
    //         ex_w_cp0_data[3 :0] = id2_rt_data[3 :0];
    //     end

    //     {5'd2, 3'd0}: begin
    //         ex_w_cp0_data       = {6'h0, id2_rt_data[25:0]};
    //     end

    //     {5'd3, 3'd0}: begin
    //         ex_w_cp0_data       = {6'h0, id2_rt_data[25:0]};
    //     end

    //     {5'd10, 3'd0}: begin
    //         ex_w_cp0_data       = {id2_rt_data[31:13], 5'h0, id2_rt_data[7:0]};
    //     end

    //     {5'd16, 3'd0}: begin
    //         ex_w_cp0_data       = {29'd0, id2_rt_data[2:0]};
    //     end

    //     default: begin
    //         ex_w_cp0_data       = 32'h0;
    //     end
    //     endcase
    // end

    alu_c alu_kernel (
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