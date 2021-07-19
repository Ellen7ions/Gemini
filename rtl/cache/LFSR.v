`timescale 1ns / 1ps

module LFSR #(
    parameter WAY_LOG = 1
) (
    input   wire                clk,
    input   wire                rst,
    input   wire [WAY_LOG-1:0]  out
);

    reg [11 :0] x;
    always @(posedge clk) begin
        if (rst) begin
            x <= {4'd5, 4'd2, 4'd8};
        end else begin
            x <= {x[0] ^ x[1], x[11 :1]};
        end
    end

    assign out = x[11:11-WAY_LOG+1];
endmodule