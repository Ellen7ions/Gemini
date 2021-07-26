`timescale 1ns / 1ps

module BTB (
    input   wire        clk,
    input   wire [31:0] pc,
    output  wire        btb_miss,
    output  wire [31:0] pred_pc,
    input   wire        wen,
    input   wire [31:0] update_pc,
    input   wire [31:0] update_target
);

    wire [8 :0] r_tagv;
    wire [7 :0] index = wen ? update_pc[9:2] : pc[9:2];

    mem_gen_tagv cache_tagv (
        .clk    (clk            ),  // input wire clk
        .a      (index          ),  // input wire [7 : 0] a
        .d      ({update_pc[17:10], 1'b1}),  // input wire [8 : 0] d
        .we     (wen            ),    // input wire we
        .spo    (r_tagv         )  // output wire [8 : 0] spo
    );

    mem_gen_target cache_target (
        .clk    (clk            ),  // input wire clk
        .a      (index          ),      // input wire [7 : 0] a
        .d      (update_target  ),      // input wire [31 : 0] d
        .we     (wen            ),    // input wire we
        .spo    (pred_pc        )  // output wire [31 : 0] spo
    );

    assign btb_miss = ~r_tagv[0] | r_tagv[0] & (r_tagv[8:1] != pc[17:10]);

endmodule