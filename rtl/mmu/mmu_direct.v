`timescale 1ns / 1ps


module mmu_direct (
    input   wire [31:0] vaddr,
    output  wire        direct_psyena,
    output  wire [31:0] direct_psyaddr
);
    assign direct_psyena    =
        vaddr[31:28] == 4'h8 || vaddr[31:28] == 4'ha;
    assign direct_psyaddr   =
        {3'b0, vaddr[28:0]};
endmodule