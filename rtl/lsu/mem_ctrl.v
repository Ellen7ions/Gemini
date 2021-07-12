`timescale 1ns / 1ps

`include "../idu/id_def.v"

module mem_ctrl (
    // EX
    input   wire            exc_ls_ena,
    input   wire  [31:0]    exc_ls_addr,
    input   wire  [31:0]    exc_rt_data,
    input   wire  [3 :0]    exc_ls_sel,
    input   wire            exc_has_exception,
    input   wire            exc_refetch,
    output  wire            exc_is_data_adel,
    output  wire            exc_is_data_ades,

    input   wire            exp_ls_ena,
    input   wire  [31:0]    exp_ls_addr,
    input   wire  [31:0]    exp_rt_data,
    input   wire  [3 :0]    exp_ls_sel,
    input   wire            exp_has_exception,
    output  wire            exp_is_data_adel,
    output  wire            exp_is_data_ades,

    // MEM
    input   wire            memc_has_exception,
    input   wire            memp_has_exception,
    output  wire [31:0]     memc_r_data,
    output  wire [31:0]     memp_r_data,

    output  wire            data_ram_en,
    output  wire [3 :0]     data_ram_wen,
    output  wire [31:0]     data_ram_addr,
    output  wire [31:0]     data_ram_wdata,
    input   wire [31:0]     data_ram_rdata
);

    // exc
    assign exc_is_data_adel =
        exc_ls_ena & (
            !(exc_ls_sel ^ `LS_SEL_LH )  &  (exc_ls_addr[0]                    )   |
            !(exc_ls_sel ^ `LS_SEL_LHU)  &  (exc_ls_addr[0]                    )   |
            !(exc_ls_sel ^ `LS_SEL_LW )  &  (exc_ls_addr[1] | exc_ls_addr[0]   )   
        );

    // exp
    assign exp_is_data_adel = 1'b0;
    
    assign exc_is_data_ades =
        exc_ls_ena & (
            !(exc_ls_sel ^ `LS_SEL_SH)   &  (exc_ls_addr[0]                     )   |
            !(exc_ls_sel ^ `LS_SEL_SW)   &  (exc_ls_addr[1] | exc_ls_addr[0]    )   
        );

    assign exp_is_data_ades = 1'b0;

    assign data_ram_en  =
        exc_ls_ena & ~exc_has_exception & ~memc_has_exception & ~memp_has_exception & ~exc_refetch;

    assign data_ram_wen =
        {4{exc_ls_ena}} & (
                {4{
                    exc_ls_sel == `LS_SEL_SB
                }} & {
                    exc_ls_addr[1:0] == 2'b11,
                    exc_ls_addr[1:0] == 2'b10,
                    exc_ls_addr[1:0] == 2'b01,
                    exc_ls_addr[1:0] == 2'b00
                }               |
                {4{
                    exc_ls_sel == `LS_SEL_SH
                }} & {
                    exc_ls_addr[1:0] == 2'b10,
                    exc_ls_addr[1:0] == 2'b10,
                    exc_ls_addr[1:0] == 2'b00,
                    exc_ls_addr[1:0] == 2'b00
                }               |
                {4{
                    (exc_ls_sel == `LS_SEL_SWL) &
                    (exc_ls_addr[1:0] == 2'b00)
                }} & 4'b0001    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWL) &
                    (exc_ls_addr[1:0] == 2'b01)
                }} & 4'b0011    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWL) &
                    (exc_ls_addr[1:0] == 2'b10)
                }} & 4'b0111    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWL) &
                    (exc_ls_addr[1:0] == 2'b11)
                }} & 4'b1111    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWR) &
                    (exc_ls_addr[1:0] == 2'b00)
                }} & 4'b1111    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWR) &
                    (exc_ls_addr[1:0] == 2'b01)
                }} & 4'b1110    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWR) &
                    (exc_ls_addr[1:0] == 2'b10)
                }} & 4'b1100    |
                {4{
                    (exc_ls_sel == `LS_SEL_SWR) &
                    (exc_ls_addr[1:0] == 2'b11)
                }} & 4'b1000    |
                {4{
                    (exc_ls_sel == `LS_SEL_SW)
                }} & 4'b1111
            );
    
    assign data_ram_addr = 
        exc_ls_addr;
    
    assign data_ram_wdata=
            ({32{
                exc_ls_sel == `LS_SEL_SB
            }} & {4{exc_rt_data[7:0]}})  |
            ({32{
                exc_ls_sel == `LS_SEL_SH
            }} & {2{exc_rt_data[15:0]}}) |
            ({32{
                exc_ls_sel == `LS_SEL_SW
            }} & exc_rt_data)            |
            ({32{
                (exc_ls_sel == `LS_SEL_SWL) &
                (exc_ls_addr[1:0] == 2'b00)
            }} & {{24{1'b0}}, exc_rt_data[31:24]})   |
            ({32{
                (exc_ls_sel == `LS_SEL_SWL) &
                (exc_ls_addr[1:0] == 2'b01)
            }} & {{16{1'b0}}, exc_rt_data[31:16]})   |
            ({32{
                (exc_ls_sel == `LS_SEL_SWL) &
                (exc_ls_addr[1:0] == 2'b10)
            }} & {{8{1'b0}},  exc_rt_data[31:8]})    |
            ({32{
                (exc_ls_sel == `LS_SEL_SWL) &
                (exc_ls_addr[1:0] == 2'b11)
            }} & {exc_rt_data[31:0]})                |
            ({32{
                (exc_ls_sel == `LS_SEL_SWR) &
                (exc_ls_addr[1:0] == 2'b00)
            }} & {exc_rt_data[31:0]})                |
            ({32{
                (exc_ls_sel == `LS_SEL_SWR) &
                (exc_ls_addr[1:0] == 2'b01)
            }} & {exc_rt_data[23:0], {8{1'b0}}})     |
            ({32{
                (exc_ls_sel == `LS_SEL_SWR) &
                (exc_ls_addr[1:0] == 2'b10)
            }} & {exc_rt_data[15:0], {16{1'b0}}})    |
            ({32{
                (exc_ls_sel == `LS_SEL_SWR) &
                (exc_ls_addr[1:0] == 2'b11)
            }} & {exc_rt_data[7 :0], {24{1'b0}}})    ;

    assign memc_r_data  = data_ram_rdata;
    assign memp_r_data  = data_ram_rdata;

endmodule