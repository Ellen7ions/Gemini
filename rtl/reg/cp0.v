`timescale 1ns / 1ps

module cp0 (
    input   wire        clk,
    input   wire        rst,
    input   wire [4 :0] r_addr,
    output  wire [31:0] r_data,
    input   wire        w_ena,
    input   wire [4 :0] w_addr,
    input   wire [31:0] w_data
);

    assign r_data = 32'h0;
endmodule