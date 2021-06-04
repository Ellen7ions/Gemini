`timescale 1ns / 1ps

module wbu (
    input   wire        wb_sel,
    input   wire [31:0] alu_res,
    input   wire [31:0] mem_data,
    input   wire [4 :0] w_reg_dst,

    output  wire [4 :0] wb_w_reg_addr,
    output  wire [31:0] wb_w_data
);

    assign wb_w_reg_addr    = w_reg_dst;
    assign wb_w_data        = 
            ({32{~wb_sel}} & alu_res) | 
            ({32{ wb_sel}} & mem_data);
endmodule