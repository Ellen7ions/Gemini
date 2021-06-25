`timescale 1ns / 1ps

module mmu_data #(
    parameter TLBNUM = 16
    ) (
    input   wire                        en,
    input   wire                        ls_sel,
    input   wire [              31:0]   vaddr,
    output  wire                        psyaddr_ena,
    output  wire [              31:0]   psyaddr,
    output  wire                        is_tlb_refill_tlbl,
    output  wire                        is_tlb_refill_tlbs,
    output  wire                        is_tlb_invalid_tlbl,
    output  wire                        is_tlb_invalid_tlbs,
    output  wire                        is_tlb_modify,

    input   wire                        is_tlbp,
    input   wire                        is_tlbr,
    input   wire                        is_tlbwi,
    
    // r cp0
    input   wire [              31:0]   r_cp0_Index,
    input   wire [              31:0]   r_cp0_EntryHi,
    input   wire [              31:0]   r_cp0_EntryLo0,
    input   wire [              31:0]   r_cp0_EntryLo1,
    

    // w cp0
    output  wire                        w_cp0_tlbp_ena,
    output  wire                        w_cp0_tlbr_ena,
    output  wire [              31:0]   w_cp0_Index,
    output  wire [              31:0]   w_cp0_EntryHi,
    output  wire [              31:0]   w_cp0_EntryLo0,
    output  wire [              31:0]   w_cp0_EntryLo1,

    output  wire [              18:0]   s_vpn,
    output  wire                        s_odd,
    output  wire [              7 :0]   s_asid,
    input   wire                        s_found,
    input   wire [$clog2(TLBNUM)-1:0]   s_index,
    input   wire [              19:0]   s_pfn,
    input   wire [              2 :0]   s_c,
    input   wire                        s_d,
    input   wire                        s_v,

    // tlb
    output  wire                        we,
    output  wire [$clog2(TLBNUM)-1:0]   w_index,
    output  wire [              18:0]   w_vpn,
    output  wire [              7 :0]   w_asid,
    output  wire                        w_g,
    output  wire [              19:0]   w_pfn0,
    output  wire [              2 :0]   w_c0,
    output  wire                        w_d0,
    output  wire                        w_v0,
    output  wire [              19:0]   w_pfn1,
    output  wire [              2 :0]   w_c1,
    output  wire                        w_d1,
    output  wire                        w_v1,

    output  wire [$clog2(TLBNUM)-1:0]   r_index,
    input   wire [              18:0]   r_vpn,
    input   wire [              7 :0]   r_asid,
    input   wire                        r_g,
    input   wire [              19:0]   r_pfn0,
    input   wire [              2 :0]   r_c0,
    input   wire                        r_d0,
    input   wire                        r_v0,
    input   wire [              19:0]   r_pfn1,
    input   wire [              2 :0]   r_c1,
    input   wire                        r_d1,
    input   wire                        r_v1
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
        .ls_sel                 (ls_sel             ),
        .found                  (s_found            ),
        .v                      (s_v                ),
        .d                      (s_d                ),
        .is_tlb_refill_tlbl     (is_tlb_refill_tlbl ),
        .is_tlb_refill_tlbs     (is_tlb_refill_tlbs ),
        .is_tlb_invalid_tlbl    (is_tlb_invalid_tlbl),
        .is_tlb_invalid_tlbs    (is_tlb_invalid_tlbs),
        .is_tlb_modify          (is_tlb_modify      )
    );

    assign s_vpn        = is_tlbp ? r_cp0_EntryHi[31:13] : vaddr[31:13];
    assign s_asid       = r_cp0_EntryHi[7:0];
    assign s_odd        = vaddr[12];

    assign psyaddr_ena  =
        (direct_psyena | s_found & s_v) & ~(is_tlb_refill_tlbl | is_tlb_refill_tlbs | is_tlb_invalid_tlbl | is_tlb_invalid_tlbs);

    assign psyaddr =
        {32{ direct_psyena}} & direct_psyaddr |
        {32{~direct_psyena}} & {s_pfn, vaddr[11:0]};

    assign w_cp0_tlbp_ena    = is_tlbp;
    assign w_cp0_tlbr_ena    = is_tlbr;
    
    // tlbr
    assign r_index          =
        r_cp0_Index[3 :0];

    // tlbp
    assign w_cp0_Index      =
        {~s_found, 27'h0, s_index};
    // tlbr
    assign w_cp0_EntryHi    =
        {r_vpn, 5'h0, r_asid};
    assign w_cp0_EntryLo0   =
        {6'h0, r_pfn0, r_c0, r_d0, r_v0, r_g};
    assign w_cp0_EntryLo1   =
        {6'h0, r_pfn1, r_c1, r_d1, r_v1, r_g};
    
    assign we       = is_tlbwi;
    assign w_index  = r_cp0_Index[3:0];
    assign w_vpn    = r_cp0_EntryHi[31:13];
    assign w_asid   = r_cp0_EntryHi[7 :0];
    assign w_g      = r_cp0_EntryLo0[0] & r_cp0_EntryLo1[0];
    assign w_pfn0   = r_cp0_EntryLo0[25:6];
    assign w_c0     = r_cp0_EntryLo0[5 :3];
    assign w_d0     = r_cp0_EntryLo0[2];
    assign w_v0     = r_cp0_EntryLo0[1];
    assign w_pfn1   = r_cp0_EntryLo1[25:6]; // bug yellow!
    assign w_c1     = r_cp0_EntryLo1[5 :3];
    assign w_d1     = r_cp0_EntryLo1[2];
    assign w_v1     = r_cp0_EntryLo1[1];
endmodule