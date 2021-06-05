`timescale 1ns / 1ps

`include "../idu/id_def.v"

module lsu (
    input   wire [31:0] ex_alu_res,
    input   wire [31:0] ex_rt_data,
    input   wire        ex_ls_ena,
    input   wire [3 :0] ex_ls_sel,

    input   wire [31:0] mem_alu_res,
    input   wire [31:0] mem_rt_data,
    input   wire        mem_ls_ena,
    input   wire [3 :0] mem_ls_sel,

    output  wire [31:0] mem_r_data,

    // send from ex
    output  wire        data_ram_en,
    output  wire [3 :0] data_ram_wen,
    output  wire [31:0] data_ram_addr,
    output  wire [31:0] data_ram_wdata,

    // receive from mem
    input   wire [31:0] data_ram_rdata
);

    // mem_ls_sel <=> data_ram_rdata

    assign data_ram_en  = ex_ls_ena;
    
    assign data_ram_wen = 
            ({4{
                ex_ls_sel == `LS_SEL_SB
            }} & 4'b0001)   |
            ({4{
                ex_ls_sel == `LS_SEL_SH
            }} & 4'b0011)   |
            ({4{
                ex_ls_sel == `LS_SEL_SW
            }} & 4'b1111);
    
    assign data_ram_addr = mem_alu_res;

    assign data_ram_wdata = 
            ({32{
                ex_ls_sel == `LS_SEL_SB
            }} & {4{ex_rt_data[7:0]}})  |
            ({32{
                ex_ls_sel == `LS_SEL_SH
            }} & {2{ex_rt_data[15:0]}}) |
            ({32{
                ex_ls_sel == `LS_SEL_SW
            }} & ex_rt_data);

    assign mem_r_data =
            mem_ls_ena & (({32{
                mem_ls_sel == `LS_SEL_LB
            }} & {{24{data_ram_rdata[7]}},  data_ram_rdata[7:0]})   |
            ({32{
                mem_ls_sel == `LS_SEL_LBU
            }} & {{24{1'b0}},               data_ram_rdata[7:0]})   |
            ({32{
                mem_ls_sel == `LS_SEL_LH
            }} & {{16{data_ram_rdata[15]}}, data_ram_rdata[15:0]})  |
            ({32{
                mem_ls_sel == `LS_SEL_LHU
            }} & {{16{1'b0}},               data_ram_rdata[15:0]})  |
            ({32{
                mem_ls_sel == `LS_SEL_LW
            }} & data_ram_rdata))                                    ;
    
endmodule