`timescale 1ns / 1ps

module lsu (
    input   wire        ls_en,
    input   wire [31:0] alu_res,
    input   wire [31:0] rt_data,
    input   wire [3 :0] ex_ls_sel,
    input   wire [3 :0] mem_ls_sel,

    output  wire        data_ram_en,
    output  wire [3 :0] data_ram_wen,
    output  wire [31:0] data_ram_addr,
    output  wire [31:0] data_ram_wdata,
    input   wire [31:0] data_ram_rdata
);
    
endmodule