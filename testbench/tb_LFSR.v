`timescale 1ns / 1ps

module tb_LFSR ();
    reg clk, rst;
    wire out;
    
    LFSR lfsr (
        clk, rst, out
    );

    initial begin
        repeat (300) begin
            #5 clk = 1'b1;
            #5 clk = 1'b0;
        end
    end

    initial begin
        rst = 1'b1;
        #20 rst = 1'b0;
    end
endmodule