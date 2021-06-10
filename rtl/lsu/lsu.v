`timescale 1ns / 1ps

`include "../idu/id_def.v"

module lsu (
    input   wire [31:0] ex_pc,
    input   wire [31:0] ex_alu_res,
    input   wire [31:0] ex_rt_data,
    input   wire        ex_ls_ena,
    input   wire [3 :0] ex_ls_sel,
    input   wire [31:0] ex_mem_alu_res,
    input   wire        ex_mem_w_reg_ena,
    input   wire [4 :0] ex_mem_w_reg_dst,
    input   wire        ex_mem_ls_ena,
    input   wire [3 :0] ex_mem_ls_sel,
    input   wire        ex_mem_wb_reg_sel,
    
    input   wire [1 :0] ex_mem_w_hilo_ena,
    input   wire [31:0] ex_mem_hi_res,
    input   wire [31:0] ex_mem_lo_res,
    
    output  wire [31:0] mem_pc,
    output  wire [31:0] mem_alu_res,
    output  wire        mem_w_reg_ena,
    output  wire [4 :0] mem_w_reg_dst,
    output  wire [31:0] mem_r_data,
    output  wire        mem_wb_reg_sel,

    output  wire [1 :0] mem_w_hilo_ena,
    output  wire [31:0] mem_hi_res,
    output  wire [31:0] mem_lo_res,
    // send from ex
    output  wire        data_ram_en,
    output  wire [3 :0] data_ram_wen,
    output  wire [31:0] data_ram_addr,
    output  wire [31:0] data_ram_wdata,
    // receive from mem
    input   wire [31:0] data_ram_rdata
);

    // ex

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
    
    assign data_ram_addr = {32{data_ram_en}} & ex_alu_res;

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

    // mem

    wire [31:0] mem_lb_data;
    wire [31:0] mem_lbu_data;
    wire [31:0] mem_lh_data;
    wire [31:0] mem_lhu_data;
    wire [31:0] mem_lw_data;
    wire [31:0] mem_lwl_data;

    assign mem_lb_data = 
            {32{
                mem_alu_res[1:0] == 2'b00
            }} & {{24{data_ram_rdata[ 7]}}, data_ram_rdata[7 : 0]} |
            {32{
                mem_alu_res[1:0] == 2'b01
            }} & {{24{data_ram_rdata[15]}}, data_ram_rdata[15: 8]} |
            {32{
                mem_alu_res[1:0] == 2'b10
            }} & {{24{data_ram_rdata[23]}}, data_ram_rdata[23:16]} |
            {32{
                mem_alu_res[1:0] == 2'b11
            }} & {{24{data_ram_rdata[31]}}, data_ram_rdata[31:24]} ;

    assign mem_lbu_data =
            {32{
                mem_alu_res[1:0] == 2'b00
            }} & {{24{1'b0}}, data_ram_rdata[7 : 0]} |
            {32{
                mem_alu_res[1:0] == 2'b01
            }} & {{24{1'b0}}, data_ram_rdata[15: 8]} |
            {32{
                mem_alu_res[1:0] == 2'b10
            }} & {{24{1'b0}}, data_ram_rdata[23:16]} |
            {32{
                mem_alu_res[1:0] == 2'b11
            }} & {{24{1'b0}}, data_ram_rdata[31:24]} ;

    assign mem_lh_data  =
            {32{
                mem_alu_res[1:0] == 2'b00
            }} & {{16{data_ram_rdata[15]}}, data_ram_rdata[15: 0]}   |
            {32{
                mem_alu_res[1:0] == 2'b10
            }} & {{16{data_ram_rdata[31]}}, data_ram_rdata[31:16]}   ;

    assign mem_lhu_data =
            {32{
                mem_alu_res[1:0] == 2'b00
            }} & {{16{1'b0}}, data_ram_rdata[15: 0]}   |
            {32{
                mem_alu_res[1:0] == 2'b10
            }} & {{16{1'b0}}, data_ram_rdata[31:16]}   ;
    
    assign mem_lw_data  =
            data_ram_rdata;

    assign mem_r_data =
            {{32{ex_mem_ls_ena}}} & (({32{
                ex_mem_ls_sel == `LS_SEL_LB
            }} & mem_lb_data    )   |
            ({32{
                ex_mem_ls_sel == `LS_SEL_LBU
            }} & mem_lbu_data   )   |
            ({32{
                ex_mem_ls_sel == `LS_SEL_LH
            }} & mem_lh_data    )   |
            ({32{
                ex_mem_ls_sel == `LS_SEL_LHU
            }} & mem_lhu_data   )   |
            ({32{
                ex_mem_ls_sel == `LS_SEL_LW
            }} & mem_lw_data    ))  ;
    
    assign mem_w_reg_ena    = ex_mem_w_reg_ena;
    assign mem_wb_reg_sel   = ex_mem_wb_reg_sel;
    assign mem_alu_res      = ex_mem_alu_res;
    assign mem_w_reg_dst    = ex_mem_w_reg_dst;

    assign mem_w_hilo_ena   = ex_mem_w_hilo_ena;     
    assign mem_hi_res       = ex_mem_hi_res;
    assign mem_lo_res       = ex_mem_lo_res; 

    assign mem_pc           = ex_pc;
endmodule