`timescale 1ns / 1ps

`include "../idu/id_def.v"

module lsu (
    input   wire [31:0] ex_pc,
    input   wire [31:0] ex_alu_res,
    input   wire [31:0] ex_rt_data,
    input   wire        ex_ls_ena,
    input   wire [3 :0] ex_ls_sel,
    input   wire        ex_has_exception,
    output  wire        to_ex_is_data_adel,
    output  wire        to_ex_is_data_ades,

    input   wire [31:0] ex_mem_alu_res,
    input   wire [31:0] ex_mem_rt_data,
    input   wire        ex_mem_w_reg_ena,
    input   wire [4 :0] ex_mem_w_reg_dst,
    input   wire        ex_mem_ls_ena,
    input   wire [3 :0] ex_mem_ls_sel,
    input   wire        ex_mem_wb_reg_sel,

    input   wire        ex_mem_w_cp0_ena,
    input   wire [7 :0] ex_mem_w_cp0_addr,
    input   wire [31:0] ex_mem_w_cp0_data,

    // exception signals
    input   wire        ex_mem_in_delay_slot,
    input   wire        ex_mem_is_eret,
    input   wire        ex_mem_is_syscall,
    input   wire        ex_mem_is_break,
    input   wire        ex_mem_is_inst_adel,
    input   wire        ex_mem_is_data_adel,
    input   wire        ex_mem_is_data_ades,
    input   wire        ex_mem_is_overflow,
    input   wire        ex_mem_is_ri,
    input   wire        ex_mem_is_int,
    
    input   wire [1 :0] ex_mem_w_hilo_ena,
    input   wire [31:0] ex_mem_hi_res,
    input   wire [31:0] ex_mem_lo_res,
    
    output  wire [31:0] mem_pc,
    output  wire [31:0] mem_alu_res,
    output  wire        mem_w_reg_ena,
    output  wire [4 :0] mem_w_reg_dst,
    output  reg  [31:0] mem_r_data,
    output  wire        mem_wb_reg_sel,

    output  wire        mem_w_cp0_ena,
    output  wire [7 :0] mem_w_cp0_addr,
    output  wire [31:0] mem_w_cp0_data,

    output  wire        mem_has_exception,

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

    // wire ls_is_sb   = ex_ls_sel == `LS_SEL_SB;
    // wire ls_is_sh   = ex_ls_sel == `LS_SEL_SH;
    // wire ls_is_swl  = ex_ls_sel == `LS_SEL_SWL;
    // wire ls_is_swr  = ex_ls_sel == `LS_SEL_SWR;
    // wire ls_is_sw   = ex_ls_sel == `LS_SEL_SW;

    assign mem_w_cp0_ena     = ex_mem_w_cp0_ena;
    assign mem_w_cp0_addr    = ex_mem_w_cp0_addr;
    assign mem_w_cp0_data    = ex_mem_w_cp0_data;

    assign mem_has_exception = 
            ex_mem_is_eret      |
            ex_mem_is_syscall   |
            ex_mem_is_break     |
            ex_mem_is_inst_adel |
            ex_mem_is_data_adel |
            ex_mem_is_data_ades |
            ex_mem_is_overflow  |
            ex_mem_is_ri        |
            ex_mem_is_int       ;

    assign to_ex_is_data_adel   =
            ex_ls_ena & (
                !(ex_ls_sel ^ `LS_SEL_LH )  &  (ex_alu_res[0]                   )   |
                !(ex_ls_sel ^ `LS_SEL_LHU)  &  (ex_alu_res[0]                   )   |
                !(ex_ls_sel ^ `LS_SEL_LW )  &  (ex_alu_res[1] | ex_alu_res[0]   )   
            );

    assign to_ex_is_data_ades  =
            ex_ls_ena & (
                !(ex_ls_sel ^ `LS_SEL_SH)   &  (ex_alu_res[0]                   )   |
                !(ex_ls_sel ^ `LS_SEL_SW)   &  (ex_alu_res[1] | ex_alu_res[0]   )   
            );

    assign data_ram_en  =
            ex_ls_ena & ~ex_has_exception & ~(
                ex_mem_is_eret      |
                ex_mem_is_syscall   |
                ex_mem_is_break     |
                ex_mem_is_inst_adel |
                ex_mem_is_data_adel |
                ex_mem_is_data_ades |
                ex_mem_is_overflow  |
                ex_mem_is_ri        |
                ex_mem_is_int
            );

    assign data_ram_wen =
            {4{ex_ls_ena}} & (
                {4{
                    ex_ls_sel == `LS_SEL_SB
                }} & {
                    ex_alu_res[1:0] == 2'b11,
                    ex_alu_res[1:0] == 2'b10,
                    ex_alu_res[1:0] == 2'b01,
                    ex_alu_res[1:0] == 2'b00
                }               |
                {4{
                    ex_ls_sel == `LS_SEL_SH
                }} & {
                    ex_alu_res[1:0] == 2'b10,
                    ex_alu_res[1:0] == 2'b10,
                    ex_alu_res[1:0] == 2'b00,
                    ex_alu_res[1:0] == 2'b00
                }               |
                {4{
                    (ex_ls_sel == `LS_SEL_SWL) &
                    (ex_alu_res[1:0] == 2'b00)
                }} & 4'b0001    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWL) &
                    (ex_alu_res[1:0] == 2'b01)
                }} & 4'b0011    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWL) &
                    (ex_alu_res[1:0] == 2'b10)
                }} & 4'b0111    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWL) &
                    (ex_alu_res[1:0] == 2'b11)
                }} & 4'b1111    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWR) &
                    (ex_alu_res[1:0] == 2'b00)
                }} & 4'b1111    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWR) &
                    (ex_alu_res[1:0] == 2'b01)
                }} & 4'b1110    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWR) &
                    (ex_alu_res[1:0] == 2'b10)
                }} & 4'b1100    |
                {4{
                    (ex_ls_sel == `LS_SEL_SWR) &
                    (ex_alu_res[1:0] == 2'b11)
                }} & 4'b1000    |
                {4{
                    (ex_ls_sel == `LS_SEL_SW)
                }} & 4'b1111
            );
    
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
            }} & ex_rt_data)            |
            ({32{
                (ex_ls_sel == `LS_SEL_SWL) &
                (ex_alu_res[1:0] == 2'b00)
            }} & {{24{1'b0}}, ex_rt_data[31:24]})   |
            ({32{
                (ex_ls_sel == `LS_SEL_SWL) &
                (ex_alu_res[1:0] == 2'b01)
            }} & {{16{1'b0}}, ex_rt_data[31:16]})   |
            ({32{
                (ex_ls_sel == `LS_SEL_SWL) &
                (ex_alu_res[1:0] == 2'b10)
            }} & {{8{1'b0}},  ex_rt_data[31:8]})    |
            ({32{
                (ex_ls_sel == `LS_SEL_SWL) &
                (ex_alu_res[1:0] == 2'b11)
            }} & {ex_rt_data[31:0]})                |
            ({32{
                (ex_ls_sel == `LS_SEL_SWR) &
                (ex_alu_res[1:0] == 2'b00)
            }} & {ex_rt_data[31:0]})                |
            ({32{
                (ex_ls_sel == `LS_SEL_SWR) &
                (ex_alu_res[1:0] == 2'b01)
            }} & {ex_rt_data[23:0], {8{1'b0}}})     |
            ({32{
                (ex_ls_sel == `LS_SEL_SWR) &
                (ex_alu_res[1:0] == 2'b10)
            }} & {ex_rt_data[15:0], {16{1'b0}}})    |
            ({32{
                (ex_ls_sel == `LS_SEL_SWR) &
                (ex_alu_res[1:0] == 2'b11)
            }} & {ex_rt_data[7 :0], {24{1'b0}}})     ;

    
    always @(*) begin
        case ({ex_mem_ls_ena, ex_mem_ls_sel})
        {1'b1, `LS_SEL_LB   }: begin
            mem_r_data  =
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
        end

        {1'b1, `LS_SEL_LBU  }: begin
            mem_r_data  =
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
        end

        {1'b1, `LS_SEL_LH   }: begin
            mem_r_data  =
                {32{
                    mem_alu_res[1:0] == 2'b00
                }} & {{16{data_ram_rdata[15]}}, data_ram_rdata[15: 0]}   |
                {32{
                    mem_alu_res[1:0] == 2'b10
                }} & {{16{data_ram_rdata[31]}}, data_ram_rdata[31:16]}   ;
        end

        {1'b1, `LS_SEL_LHU  }: begin
            mem_r_data  =
                {32{
                    mem_alu_res[1:0] == 2'b00
                }} & {{16{1'b0}}, data_ram_rdata[15: 0]}   |
                {32{
                    mem_alu_res[1:0] == 2'b10
                }} & {{16{1'b0}}, data_ram_rdata[31:16]}   ;
        end

        {1'b1, `LS_SEL_LW   }: begin
            mem_r_data  =
                data_ram_rdata;
        end

        {1'b1, `LS_SEL_LWL  }: begin
            mem_r_data  =
                {32{
                    mem_alu_res[1:0] == 2'b00
                }} & {data_ram_rdata[7 :0], ex_mem_rt_data[23:0]}   |
                {32{
                    mem_alu_res[1:0] == 2'b01
                }} & {data_ram_rdata[15:0], ex_mem_rt_data[15:0]}   |
                {32{
                    mem_alu_res[1:0] == 2'b10
                }} & {data_ram_rdata[23:0], ex_mem_rt_data[7 :0]}   |
                {32{
                    mem_alu_res[1:0] == 2'b11
                }} & {data_ram_rdata[31:0]}                         ;
        end

        {1'b1, `LS_SEL_LWR  }: begin
            mem_r_data  =
                {32{
                    mem_alu_res[1:0] == 2'b00
                }} & {data_ram_rdata[31:0]}                         |
                {32{
                    mem_alu_res[1:0] == 2'b01
                }} & {ex_mem_rt_data[31:24], data_ram_rdata[31: 8]}  |
                {32{
                    mem_alu_res[1:0] == 2'b10
                }} & {ex_mem_rt_data[31:16], data_ram_rdata[31:16]} |
                {32{
                    mem_alu_res[1:0] == 2'b11
                }} & {ex_mem_rt_data[31: 8], data_ram_rdata[31:24]} ;
        end
        default: begin
            mem_r_data  = 32'h0;
        end
        endcase
    end
    
    assign mem_w_reg_ena    = ex_mem_w_reg_ena;
    assign mem_wb_reg_sel   = ex_mem_wb_reg_sel;
    assign mem_alu_res      = ex_mem_alu_res;
    assign mem_w_reg_dst    = ex_mem_w_reg_dst;

    assign mem_w_hilo_ena   = ex_mem_w_hilo_ena;     
    assign mem_hi_res       = ex_mem_hi_res;
    assign mem_lo_res       = ex_mem_lo_res; 

    assign mem_pc           = ex_pc;
endmodule