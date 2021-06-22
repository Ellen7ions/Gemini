`timescale 1ns/1ps

module npc (
    input   wire        id_take_j_imme,
    input   wire [25:0] id_j_imme,

    input   wire        id_take_branch,
    input   wire [15:0] id_branch_offset,

    input   wire        id_take_jr,
    input   wire [31:0] id_rs_data,

    input   wire        exception_pc_ena,
    input   wire [31:0] exception_pc,

    input   wire [31:0] id_pc,
    input   wire [31:0] id_branch_target,
    
    input   wire [31:0] pc,
    input   wire        inst_rdata_1_ok,
    input   wire        inst_rdata_2_ok,

    output  wire [31:0] next_pc
);

  assign next_pc =
    {32{ exception_pc_ena                           }} & exception_pc                                                |
    {32{(id_take_j_imme )  & (~exception_pc_ena)    }} & {id_pc[31:28], id_j_imme, 2'b00} |
    {32{(id_take_branch )  & (~exception_pc_ena)    }} & {id_branch_target}               |
    {32{(id_take_jr     )  & (~exception_pc_ena)    }} & {id_rs_data}                     |
    {32{(~id_take_j_imme)  & (~exception_pc_ena) & (~id_take_branch) & (~id_take_jr) & ~inst_rdata_1_ok & ~inst_rdata_2_ok}} & {pc} |
    {32{(~id_take_j_imme)  & (~exception_pc_ena) & (~id_take_branch) & (~id_take_jr) &  inst_rdata_1_ok & ~inst_rdata_2_ok}} & {pc + 32'h4} |
    {32{(~id_take_j_imme)  & (~exception_pc_ena) & (~id_take_branch) & (~id_take_jr) &  inst_rdata_1_ok &  inst_rdata_2_ok}} & {pc + 32'h8} ;

endmodule