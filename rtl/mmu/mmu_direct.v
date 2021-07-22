`timescale 1ns / 1ps


module mmu_direct (
    input   wire [31:0] vaddr,
    output  wire        direct_psyena,
    output  wire [31:0] direct_psyaddr
);
    assign direct_psyena    =
        vaddr[31] & ~vaddr[30];
    assign direct_psyaddr   =
        {3'b000, vaddr[28:0]};
endmodule