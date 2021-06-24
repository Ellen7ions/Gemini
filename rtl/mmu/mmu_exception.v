`timescale 1ns / 1ps

module mmu_exception (
    // 0 load 1 store
    input   wire en,
    input   wire ls_sel,
    input   wire found,
    input   wire v,
    input   wire d,
    output  wire is_tlb_refill_tlbl,
    output  wire is_tlb_refill_tlbs,
    output  wire is_tlb_invalid_tlbl,
    output  wire is_tlb_invalid_tlbs,
    output  wire is_tlb_modify
);

    assign is_tlb_refill_tlbl   =
        en & ~ls_sel & ~found;
    assign is_tlb_refill_tlbs   =
        en &  ls_sel & ~found;
    assign is_tlb_invalid_tlbl  =
        en & ~ls_sel & found & ~v;
    assign is_tlb_invalid_tlbs  =
        en & ls_sel & found & ~v;
    assign is_tlb_modify        =
        en & ls_sel & found & v & ~d;
endmodule