`timescale 1ns / 1ps

module cp0 (
    input   wire clk,
    input   wire rst,
    input   wire r_addr,
    output  wire r_data
);

    assign r_data = 32'h0;
endmodule