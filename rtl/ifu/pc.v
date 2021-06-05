`timescale 1ns / 1ps

module pc(
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,
    input   wire        flush,
    input   wire [31:0] next_pc,
    output  reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'hbfbf_fffc;
        end else if (flush && !stall) begin
            pc <= 32'h0;
        end else if (!flush && !stall) begin
            pc <= next_pc;
        end
    end

endmodule