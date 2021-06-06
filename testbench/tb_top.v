`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/06 16:27:08
// Design Name: 
// Module Name: tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_top();
    reg clk, rst;
    initial begin
        forever begin
            #5 clk = 1'b0;
            #5 clk = 1'b1;
        end
    end

    Top top(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        rst = 1'b1;
        #200 rst = 1'b0;
    end
endmodule
