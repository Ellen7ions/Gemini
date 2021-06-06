`timescale 1ns / 1ps

module wbu (
    input   wire [31:0] mem_alu_res,
    input   wire        mem_w_reg_ena,
    input   wire [4 :0] mem_w_reg_dst,
    input   wire [31:0] mem_r_data,
    input   wire        mem_wb_sel,
    output  wire        wb_w_reg_ena,
    output  wire [4 :0] wb_w_reg_addr,
    output  wire [31:0] wb_w_reg_data
);

    assign wb_w_reg_ena     = mem_w_reg_dst == 5'h0 ? 1'b0 : mem_w_reg_ena;
    assign wb_w_reg_addr    = mem_w_reg_dst;
    assign wb_w_reg_data    = 
            ({32{~mem_wb_sel}} & mem_alu_res) | 
            ({32{ mem_wb_sel}} & mem_r_data);
endmodule