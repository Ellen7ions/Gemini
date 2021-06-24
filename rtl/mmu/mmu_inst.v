`timescale 1ns / 1ps

module mmu_inst #(
    parameter TLBNUM = 16
    ) (
    input   wire                        en,
    input   wire [              31:0]   vaddr,
    input   wire [              31:0]   r_cp0_EntryHi,
    output  wire                        psyaddr_ena,
    output  wire [              31:0]   psyaddr,
    output  wire                        is_tlb_refill_tlbl,
    output  wire                        is_tlb_invalid_tlbl,

    output  wire [              18:0]   s_vpn,
    output  wire                        s_odd,
    output  wire [              7 :0]   s_asid,
    input   wire                        s_found,
    input   wire [$clog2(TLBNUM)-1:0]   s_index,
    input   wire [              19:0]   s_pfn,
    input   wire [              2 :0]   s_c,
    input   wire                        s_d,
    input   wire                        s_v
);

    wire [31:0] direct_psyaddr;
    wire        direct_psyena;

    mmu_direct mmu_direct0 (
        .vaddr          (vaddr         ),
        .direct_psyena  (direct_psyena ),
        .direct_psyaddr (direct_psyaddr)
    );

    mmu_exception mmu_exception0 (
        .en                     (en & ~direct_psyena),
        .ls_sel                 (1'b0               ),
        .found                  (s_found            ),
        .v                      (s_v                ),
        .d                      (s_d                ),
        .is_tlb_refill_tlbl     (is_tlb_refill_tlbl ),
        .is_tlb_refill_tlbs     (                   ),
        .is_tlb_invalid_tlbl    (is_tlb_invalid_tlbl),
        .is_tlb_invalid_tlbs    (),
        .is_tlb_modify          ()
    );

    assign s_vpn        = vaddr[31:13];
    assign s_odd        = vaddr[12];
    assign s_asid       = r_cp0_EntryHi[7 :0];

    assign psyaddr_ena  =
        direct_psyena | s_found & s_v;

    assign psyaddr =
        {32{ direct_psyena}} & {direct_psyaddr       }   |
        {32{~direct_psyena}} & {s_pfn, vaddr[11:0]   }   ;
    
endmodule