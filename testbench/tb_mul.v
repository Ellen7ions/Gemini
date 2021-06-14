`timescale 1ns/1ps  

module tb_mul ();
    reg clk;

    initial begin
        repeat (300) begin
            #5 clk = 1'b1;
            #5 clk = 1'b0;
        end
    end
    
    reg rst;
    reg [31:0] a, b;
    reg mul_sign;
    reg en;
    wire [31:0] s, r;
    wire ready, stall;
    multiplier uut(
        .clk(clk),
        .rst(rst),
        .src_a(a),
        .src_b(b),
        .en(en),
        .mul_sign(mul_sign),
        .s(s),
        .r(r),
        .res_ready(ready),
        .stall_all(stall)
    );

    initial begin
        rst = 1;
        a = 0;
        b = 0;
        en = 0;
        mul_sign = 0;
        #50 rst = 0;
        #10 begin
            a = 32'd45;
            b = 32'd14;
            en = 1; 
            mul_sign = 0;
        end
        #10 en = 0;

        #35 begin
            a = 32'd111;
            b = 32'd1111;
            en = 1; 
            mul_sign = 0;
        end
    end
endmodule