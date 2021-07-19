`timescale 1ns / 1ps

module decoder #(
    parameter M = 2,
    parameter N = 4
) (
    input   wire [M-1:0] in,
    output  reg  [N-1:0] out
);

    always @(*) begin
        case (in)
        2'b00: out = 4'b0001;
        2'b01: out = 4'b0010;
        2'b10: out = 4'b0100;
        2'b11: out = 4'b1000;
        default: out = 4'b0000;
        endcase
    end

endmodule