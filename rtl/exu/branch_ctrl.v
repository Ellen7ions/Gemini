`timescale 1ns / 1ps

`include "../idu/id_def.v"
`include "branch_def.v"

module branch_ctrl (
    input   wire [3:0]  id2_branch_sel,
    input   wire        id2_is_branch,
    input   wire        id2_is_j_imme,
    input   wire        id2_is_jr,
    input   wire [31:0] id2_rs_data,
    input   wire [31:0] id2_rt_data,

    input   wire        id2_take_jmp,

    output  wire        take_branch,
    output  wire        take_j_imme,
    output  wire        take_jr,
    output  wire        flush_req
);
    
    assign take_j_imme  = id2_is_j_imme;
    
    assign take_jr      = id2_is_jr;

    assign flush_req    = id2_take_jmp;
endmodule