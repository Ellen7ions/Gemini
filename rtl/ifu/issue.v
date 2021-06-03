`timescale 1ns / 1ps

module issue (
    input   wire [63:0] fifo_r_data_1,
    input   wire        fifo_r_data_1_ok,
    input   wire [63:0] fifo_r_data_2,
    input   wire        fifo_r_data_2_ok,
    output  wire        p_data_1,
    output  wire        p_data_2,

    output  wire [31:0] id_pc_1,
    output  wire [31:0] id_inst_1,
    output  wire        id_en_1,

    output  wire [31:0] id_pc_2,
    output  wire [31:0] id_inst_2,
    output  wire        id_en_2
);

    assign id_pc_1      = fifo_r_data_1[63:32];
    assign id_inst_1    = fifo_r_data_1[31: 0];
    assign id_en_1      = 1'b1;

    assign id_pc_2      = fifo_r_data_2[63:32];
    assign id_inst_2    = fifo_r_data_2[31: 0];
    assign id_en_2      = 1'b1;

endmodule