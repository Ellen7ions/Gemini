`timescale 1ns / 1ps

module gemini (
    input   wire        clk,
    input   wire        rst,
    input   wire [5 :0] interupt,
    
    output  wire        inst_ena,
    output  wire [31:0] inst_addr_1,
    output  wire [31:0] inst_addr_2,
    input   wire [31:0] inst_rdata_1,
    input   wire [31:0] inst_rdata_2,
    input   wire        inst_rdata_1_ok,
    input   wire        inst_rdata_2_ok,

    output  wire        data_ena,
    output  wire [3 :0] data_wea,
    output  wire [31:0] data_waddr,
    output  wire [31:0] data_wdata,
    output  wire [31:0] data_rdata,

    output  wire [31:0] debug_pc,
    output  wire        debug_w_ena,
    output  wire [31:0] debug_w_addr,
    output  wire [31:0] debug_w_data
);
    
endmodule