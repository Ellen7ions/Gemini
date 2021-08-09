`timescale 1ns / 1ps

module tlb #(
    parameter TLBNUM = 16
    ) (
    input   wire                        clk,
    input   wire [              18:0]   s_vpn_1,
    input   wire                        s_odd_1,
    input   wire [              7 :0]   s_asid_1,
    output  wire                        s_found_1,
    output  wire [$clog2(TLBNUM)-1:0]   s_index_1,
    output  wire [              19:0]   s_pfn_1,
    output  wire [              2 :0]   s_c_1,
    output  wire                        s_d_1,
    output  wire                        s_v_1,

    (*mark_debug="true"*) input   wire [              18:0]   s_vpn_2,
    (*mark_debug="true"*) input   wire                        s_odd_2,
    (*mark_debug="true"*) input   wire [              7 :0]   s_asid_2,
    (*mark_debug="true"*) output  wire                        s_found_2,
    (*mark_debug="true"*) output  wire [$clog2(TLBNUM)-1:0]   s_index_2,
    (*mark_debug="true"*) output  wire [              19:0]   s_pfn_2,
    (*mark_debug="true"*) output  wire [              2 :0]   s_c_2,
    (*mark_debug="true"*) output  wire                        s_d_2,
    (*mark_debug="true"*) output  wire                        s_v_2,

    input   wire                        we,
    input   wire [$clog2(TLBNUM)-1:0]   w_index,
    input   wire [              18:0]   w_vpn,
    input   wire [              7 :0]   w_asid,
    input   wire                        w_g,
    input   wire [              19:0]   w_pfn0,
    input   wire [              2 :0]   w_c0,
    input   wire                        w_d0,
    input   wire                        w_v0,
    input   wire [              19:0]   w_pfn1,
    input   wire [              2 :0]   w_c1,
    input   wire                        w_d1,
    input   wire                        w_v1,

    input   wire [$clog2(TLBNUM)-1:0]   r_index,
    output  wire [              18:0]   r_vpn,
    output  wire [              7 :0]   r_asid,
    output  wire                        r_g,
    output  wire [              19:0]   r_pfn0,
    output  wire [              2 :0]   r_c0,
    output  wire                        r_d0,
    output  wire                        r_v0,
    output  wire [              19:0]   r_pfn1,
    output  wire [              2 :0]   r_c1,
    output  wire                        r_d1,
    output  wire                        r_v1
);

    (*mark_debug="true"*) reg     [               18:0]   tlb_vpn     [TLBNUM-1:0];
    (*mark_debug="true"*) reg     [               7 :0]   tlb_asid    [TLBNUM-1:0];
    (*mark_debug="true"*) reg                             tlb_g       [TLBNUM-1:0];
    reg     [               19:0]   tlb_pfn0    [TLBNUM-1:0];
    reg     [               2 :0]   tlb_c0      [TLBNUM-1:0];
    reg                             tlb_d0      [TLBNUM-1:0];
    reg                             tlb_v0      [TLBNUM-1:0];
    reg     [               19:0]   tlb_pfn1    [TLBNUM-1:0];
    reg     [               2 :0]   tlb_c1      [TLBNUM-1:0];
    reg                             tlb_d1      [TLBNUM-1:0];
    reg                             tlb_v1      [TLBNUM-1:0];

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            tlb_vpn [i] <= 19'h0;
            tlb_asid[i] <= 8'h0;
            tlb_g   [i] <= 1'h0;
            tlb_pfn0[i] <= 20'h0;
            tlb_c0  [i] <= 3'b0;
            tlb_d0  [i] <= 1'b0;
            tlb_v0  [i] <= 1'b0;
            tlb_pfn1[i] <= 20'h0;
            tlb_c1  [i] <= 3'b0;
            tlb_d1  [i] <= 1'b0;
            tlb_v1  [i] <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (we) begin
            tlb_vpn  [w_index]  <= w_vpn;
            tlb_asid [w_index]  <= w_asid;    
            tlb_g    [w_index]  <= w_g;
            tlb_pfn0 [w_index]  <= w_pfn0;    
            tlb_c0   [w_index]  <= w_c0;
            tlb_d0   [w_index]  <= w_d0;
            tlb_v0   [w_index]  <= w_v0;
            tlb_pfn1 [w_index]  <= w_pfn1;    
            tlb_c1   [w_index]  <= w_c1;
            tlb_d1   [w_index]  <= w_d1;
            tlb_v1   [w_index]  <= w_v1;
        end
    end

    assign r_vpn  = tlb_vpn  [r_index];
    assign r_asid = tlb_asid [r_index];
    assign r_g    = tlb_g    [r_index];
    assign r_pfn0 = tlb_pfn0 [r_index];
    assign r_c0   = tlb_c0   [r_index];
    assign r_d0   = tlb_d0   [r_index];
    assign r_v0   = tlb_v0   [r_index];
    assign r_pfn1 = tlb_pfn1 [r_index];
    assign r_c1   = tlb_c1   [r_index];
    assign r_d1   = tlb_d1   [r_index];
    assign r_v1   = tlb_v1   [r_index];

    // search port 1
    wire    [TLBNUM-1:0]   tlb_match_1;

    assign tlb_match_1[ 0] = (s_vpn_1 == tlb_vpn[ 0]) && ((s_asid_1 == tlb_asid[ 0]) || tlb_g[ 0]);
    assign tlb_match_1[ 1] = (s_vpn_1 == tlb_vpn[ 1]) && ((s_asid_1 == tlb_asid[ 1]) || tlb_g[ 1]);
    assign tlb_match_1[ 2] = (s_vpn_1 == tlb_vpn[ 2]) && ((s_asid_1 == tlb_asid[ 2]) || tlb_g[ 2]);
    assign tlb_match_1[ 3] = (s_vpn_1 == tlb_vpn[ 3]) && ((s_asid_1 == tlb_asid[ 3]) || tlb_g[ 3]);
    assign tlb_match_1[ 4] = (s_vpn_1 == tlb_vpn[ 4]) && ((s_asid_1 == tlb_asid[ 4]) || tlb_g[ 4]);
    assign tlb_match_1[ 5] = (s_vpn_1 == tlb_vpn[ 5]) && ((s_asid_1 == tlb_asid[ 5]) || tlb_g[ 5]);
    assign tlb_match_1[ 6] = (s_vpn_1 == tlb_vpn[ 6]) && ((s_asid_1 == tlb_asid[ 6]) || tlb_g[ 6]);
    assign tlb_match_1[ 7] = (s_vpn_1 == tlb_vpn[ 7]) && ((s_asid_1 == tlb_asid[ 7]) || tlb_g[ 7]);
    assign tlb_match_1[ 8] = (s_vpn_1 == tlb_vpn[ 8]) && ((s_asid_1 == tlb_asid[ 8]) || tlb_g[ 8]);
    assign tlb_match_1[ 9] = (s_vpn_1 == tlb_vpn[ 9]) && ((s_asid_1 == tlb_asid[ 9]) || tlb_g[ 9]);
    assign tlb_match_1[10] = (s_vpn_1 == tlb_vpn[10]) && ((s_asid_1 == tlb_asid[10]) || tlb_g[10]);
    assign tlb_match_1[11] = (s_vpn_1 == tlb_vpn[11]) && ((s_asid_1 == tlb_asid[11]) || tlb_g[11]);
    assign tlb_match_1[12] = (s_vpn_1 == tlb_vpn[12]) && ((s_asid_1 == tlb_asid[12]) || tlb_g[12]);
    assign tlb_match_1[13] = (s_vpn_1 == tlb_vpn[13]) && ((s_asid_1 == tlb_asid[13]) || tlb_g[13]);
    assign tlb_match_1[14] = (s_vpn_1 == tlb_vpn[14]) && ((s_asid_1 == tlb_asid[14]) || tlb_g[14]);
    assign tlb_match_1[15] = (s_vpn_1 == tlb_vpn[15]) && ((s_asid_1 == tlb_asid[15]) || tlb_g[15]);

    // search port 1
    assign s_found_1     = |tlb_match_1;
    encoder16 en0 (
        .in     (tlb_match_1),
        .out    (s_index_1)
    );
    assign s_pfn_1       = 
        {20{tlb_match_1[ 0] & ~s_odd_1}} & tlb_pfn0[ 0] |
        {20{tlb_match_1[ 0] &  s_odd_1}} & tlb_pfn1[ 0] |
        {20{tlb_match_1[ 1] & ~s_odd_1}} & tlb_pfn0[ 1] |
        {20{tlb_match_1[ 1] &  s_odd_1}} & tlb_pfn1[ 1] |
        {20{tlb_match_1[ 2] & ~s_odd_1}} & tlb_pfn0[ 2] |
        {20{tlb_match_1[ 2] &  s_odd_1}} & tlb_pfn1[ 2] |
        {20{tlb_match_1[ 3] & ~s_odd_1}} & tlb_pfn0[ 3] |
        {20{tlb_match_1[ 3] &  s_odd_1}} & tlb_pfn1[ 3] |
        {20{tlb_match_1[ 4] & ~s_odd_1}} & tlb_pfn0[ 4] |
        {20{tlb_match_1[ 4] &  s_odd_1}} & tlb_pfn1[ 4] |
        {20{tlb_match_1[ 5] & ~s_odd_1}} & tlb_pfn0[ 5] |
        {20{tlb_match_1[ 5] &  s_odd_1}} & tlb_pfn1[ 5] |
        {20{tlb_match_1[ 6] & ~s_odd_1}} & tlb_pfn0[ 6] |
        {20{tlb_match_1[ 6] &  s_odd_1}} & tlb_pfn1[ 6] |
        {20{tlb_match_1[ 7] & ~s_odd_1}} & tlb_pfn0[ 7] |
        {20{tlb_match_1[ 7] &  s_odd_1}} & tlb_pfn1[ 7] |
        {20{tlb_match_1[ 8] & ~s_odd_1}} & tlb_pfn0[ 8] |
        {20{tlb_match_1[ 8] &  s_odd_1}} & tlb_pfn1[ 8] |
        {20{tlb_match_1[ 9] & ~s_odd_1}} & tlb_pfn0[ 9] |
        {20{tlb_match_1[ 9] &  s_odd_1}} & tlb_pfn1[ 9] |
        {20{tlb_match_1[10] & ~s_odd_1}} & tlb_pfn0[10] |
        {20{tlb_match_1[10] &  s_odd_1}} & tlb_pfn1[10] |
        {20{tlb_match_1[11] & ~s_odd_1}} & tlb_pfn0[11] |
        {20{tlb_match_1[11] &  s_odd_1}} & tlb_pfn1[11] |
        {20{tlb_match_1[12] & ~s_odd_1}} & tlb_pfn0[12] |
        {20{tlb_match_1[12] &  s_odd_1}} & tlb_pfn1[12] |
        {20{tlb_match_1[13] & ~s_odd_1}} & tlb_pfn0[13] |
        {20{tlb_match_1[13] &  s_odd_1}} & tlb_pfn1[13] |
        {20{tlb_match_1[14] & ~s_odd_1}} & tlb_pfn0[14] |
        {20{tlb_match_1[14] &  s_odd_1}} & tlb_pfn1[14] |
        {20{tlb_match_1[15] & ~s_odd_1}} & tlb_pfn0[15] |
        {20{tlb_match_1[15] &  s_odd_1}} & tlb_pfn1[15] ;
        
    assign s_c_1         =
        {20{tlb_match_1[ 0] & ~s_odd_1}} & tlb_c0[ 0]   |
        {20{tlb_match_1[ 0] &  s_odd_1}} & tlb_c1[ 0]   |
        {20{tlb_match_1[ 1] & ~s_odd_1}} & tlb_c0[ 1]   |
        {20{tlb_match_1[ 1] &  s_odd_1}} & tlb_c1[ 1]   |
        {20{tlb_match_1[ 2] & ~s_odd_1}} & tlb_c0[ 2]   |
        {20{tlb_match_1[ 2] &  s_odd_1}} & tlb_c1[ 2]   |
        {20{tlb_match_1[ 3] & ~s_odd_1}} & tlb_c0[ 3]   |
        {20{tlb_match_1[ 3] &  s_odd_1}} & tlb_c1[ 3]   |
        {20{tlb_match_1[ 4] & ~s_odd_1}} & tlb_c0[ 4]   |
        {20{tlb_match_1[ 4] &  s_odd_1}} & tlb_c1[ 4]   |
        {20{tlb_match_1[ 5] & ~s_odd_1}} & tlb_c0[ 5]   |
        {20{tlb_match_1[ 5] &  s_odd_1}} & tlb_c1[ 5]   |
        {20{tlb_match_1[ 6] & ~s_odd_1}} & tlb_c0[ 6]   |
        {20{tlb_match_1[ 6] &  s_odd_1}} & tlb_c1[ 6]   |
        {20{tlb_match_1[ 7] & ~s_odd_1}} & tlb_c0[ 7]   |
        {20{tlb_match_1[ 7] &  s_odd_1}} & tlb_c1[ 7]   |
        {20{tlb_match_1[ 8] & ~s_odd_1}} & tlb_c0[ 8]   |
        {20{tlb_match_1[ 8] &  s_odd_1}} & tlb_c1[ 8]   |
        {20{tlb_match_1[ 9] & ~s_odd_1}} & tlb_c0[ 9]   |
        {20{tlb_match_1[ 9] &  s_odd_1}} & tlb_c1[ 9]   |
        {20{tlb_match_1[10] & ~s_odd_1}} & tlb_c0[10]   |
        {20{tlb_match_1[10] &  s_odd_1}} & tlb_c1[10]   |
        {20{tlb_match_1[11] & ~s_odd_1}} & tlb_c0[11]   |
        {20{tlb_match_1[11] &  s_odd_1}} & tlb_c1[11]   |
        {20{tlb_match_1[12] & ~s_odd_1}} & tlb_c0[12]   |
        {20{tlb_match_1[12] &  s_odd_1}} & tlb_c1[12]   |
        {20{tlb_match_1[13] & ~s_odd_1}} & tlb_c0[13]   |
        {20{tlb_match_1[13] &  s_odd_1}} & tlb_c1[13]   |
        {20{tlb_match_1[14] & ~s_odd_1}} & tlb_c0[14]   |
        {20{tlb_match_1[14] &  s_odd_1}} & tlb_c1[14]   |
        {20{tlb_match_1[15] & ~s_odd_1}} & tlb_c0[15]   |
        {20{tlb_match_1[15] &  s_odd_1}} & tlb_c1[15]   ;
    assign s_d_1         =
        {20{tlb_match_1[ 0] & ~s_odd_1}} & tlb_d0[ 0]   |
        {20{tlb_match_1[ 0] &  s_odd_1}} & tlb_d1[ 0]   |
        {20{tlb_match_1[ 1] & ~s_odd_1}} & tlb_d0[ 1]   |
        {20{tlb_match_1[ 1] &  s_odd_1}} & tlb_d1[ 1]   |
        {20{tlb_match_1[ 2] & ~s_odd_1}} & tlb_d0[ 2]   |
        {20{tlb_match_1[ 2] &  s_odd_1}} & tlb_d1[ 2]   |
        {20{tlb_match_1[ 3] & ~s_odd_1}} & tlb_d0[ 3]   |
        {20{tlb_match_1[ 3] &  s_odd_1}} & tlb_d1[ 3]   |
        {20{tlb_match_1[ 4] & ~s_odd_1}} & tlb_d0[ 4]   |
        {20{tlb_match_1[ 4] &  s_odd_1}} & tlb_d1[ 4]   |
        {20{tlb_match_1[ 5] & ~s_odd_1}} & tlb_d0[ 5]   |
        {20{tlb_match_1[ 5] &  s_odd_1}} & tlb_d1[ 5]   |
        {20{tlb_match_1[ 6] & ~s_odd_1}} & tlb_d0[ 6]   |
        {20{tlb_match_1[ 6] &  s_odd_1}} & tlb_d1[ 6]   |
        {20{tlb_match_1[ 7] & ~s_odd_1}} & tlb_d0[ 7]   |
        {20{tlb_match_1[ 7] &  s_odd_1}} & tlb_d1[ 7]   |
        {20{tlb_match_1[ 8] & ~s_odd_1}} & tlb_d0[ 8]   |
        {20{tlb_match_1[ 8] &  s_odd_1}} & tlb_d1[ 8]   |
        {20{tlb_match_1[ 9] & ~s_odd_1}} & tlb_d0[ 9]   |
        {20{tlb_match_1[ 9] &  s_odd_1}} & tlb_d1[ 9]   |
        {20{tlb_match_1[10] & ~s_odd_1}} & tlb_d0[10]   |
        {20{tlb_match_1[10] &  s_odd_1}} & tlb_d1[10]   |
        {20{tlb_match_1[11] & ~s_odd_1}} & tlb_d0[11]   |
        {20{tlb_match_1[11] &  s_odd_1}} & tlb_d1[11]   |
        {20{tlb_match_1[12] & ~s_odd_1}} & tlb_d0[12]   |
        {20{tlb_match_1[12] &  s_odd_1}} & tlb_d1[12]   |
        {20{tlb_match_1[13] & ~s_odd_1}} & tlb_d0[13]   |
        {20{tlb_match_1[13] &  s_odd_1}} & tlb_d1[13]   |
        {20{tlb_match_1[14] & ~s_odd_1}} & tlb_d0[14]   |
        {20{tlb_match_1[14] &  s_odd_1}} & tlb_d1[14]   |
        {20{tlb_match_1[15] & ~s_odd_1}} & tlb_d0[15]   |
        {20{tlb_match_1[15] &  s_odd_1}} & tlb_d1[15]   ;
    assign s_v_1         =
        {20{tlb_match_1[ 0] & ~s_odd_1}} & tlb_v0[ 0]   |
        {20{tlb_match_1[ 0] &  s_odd_1}} & tlb_v1[ 0]   |
        {20{tlb_match_1[ 1] & ~s_odd_1}} & tlb_v0[ 1]   |
        {20{tlb_match_1[ 1] &  s_odd_1}} & tlb_v1[ 1]   |
        {20{tlb_match_1[ 2] & ~s_odd_1}} & tlb_v0[ 2]   |
        {20{tlb_match_1[ 2] &  s_odd_1}} & tlb_v1[ 2]   |
        {20{tlb_match_1[ 3] & ~s_odd_1}} & tlb_v0[ 3]   |
        {20{tlb_match_1[ 3] &  s_odd_1}} & tlb_v1[ 3]   |
        {20{tlb_match_1[ 4] & ~s_odd_1}} & tlb_v0[ 4]   |
        {20{tlb_match_1[ 4] &  s_odd_1}} & tlb_v1[ 4]   |
        {20{tlb_match_1[ 5] & ~s_odd_1}} & tlb_v0[ 5]   |
        {20{tlb_match_1[ 5] &  s_odd_1}} & tlb_v1[ 5]   |
        {20{tlb_match_1[ 6] & ~s_odd_1}} & tlb_v0[ 6]   |
        {20{tlb_match_1[ 6] &  s_odd_1}} & tlb_v1[ 6]   |
        {20{tlb_match_1[ 7] & ~s_odd_1}} & tlb_v0[ 7]   |
        {20{tlb_match_1[ 7] &  s_odd_1}} & tlb_v1[ 7]   |
        {20{tlb_match_1[ 8] & ~s_odd_1}} & tlb_v0[ 8]   |
        {20{tlb_match_1[ 8] &  s_odd_1}} & tlb_v1[ 8]   |
        {20{tlb_match_1[ 9] & ~s_odd_1}} & tlb_v0[ 9]   |
        {20{tlb_match_1[ 9] &  s_odd_1}} & tlb_v1[ 9]   |
        {20{tlb_match_1[10] & ~s_odd_1}} & tlb_v0[10]   |
        {20{tlb_match_1[10] &  s_odd_1}} & tlb_v1[10]   |
        {20{tlb_match_1[11] & ~s_odd_1}} & tlb_v0[11]   |
        {20{tlb_match_1[11] &  s_odd_1}} & tlb_v1[11]   |
        {20{tlb_match_1[12] & ~s_odd_1}} & tlb_v0[12]   |
        {20{tlb_match_1[12] &  s_odd_1}} & tlb_v1[12]   |
        {20{tlb_match_1[13] & ~s_odd_1}} & tlb_v0[13]   |
        {20{tlb_match_1[13] &  s_odd_1}} & tlb_v1[13]   |
        {20{tlb_match_1[14] & ~s_odd_1}} & tlb_v0[14]   |
        {20{tlb_match_1[14] &  s_odd_1}} & tlb_v1[14]   |
        {20{tlb_match_1[15] & ~s_odd_1}} & tlb_v0[15]   |
        {20{tlb_match_1[15] &  s_odd_1}} & tlb_v1[15]   ;
    
    // search port 2
    wire    [TLBNUM-1:0]   tlb_match_2;

    assign tlb_match_2[ 0] = (s_vpn_2 == tlb_vpn[ 0]) && ((s_asid_2 == tlb_asid[ 0]) || tlb_g[ 0]);
    assign tlb_match_2[ 1] = (s_vpn_2 == tlb_vpn[ 1]) && ((s_asid_2 == tlb_asid[ 1]) || tlb_g[ 1]);
    assign tlb_match_2[ 2] = (s_vpn_2 == tlb_vpn[ 2]) && ((s_asid_2 == tlb_asid[ 2]) || tlb_g[ 2]);
    assign tlb_match_2[ 3] = (s_vpn_2 == tlb_vpn[ 3]) && ((s_asid_2 == tlb_asid[ 3]) || tlb_g[ 3]);
    assign tlb_match_2[ 4] = (s_vpn_2 == tlb_vpn[ 4]) && ((s_asid_2 == tlb_asid[ 4]) || tlb_g[ 4]);
    assign tlb_match_2[ 5] = (s_vpn_2 == tlb_vpn[ 5]) && ((s_asid_2 == tlb_asid[ 5]) || tlb_g[ 5]);
    assign tlb_match_2[ 6] = (s_vpn_2 == tlb_vpn[ 6]) && ((s_asid_2 == tlb_asid[ 6]) || tlb_g[ 6]);
    assign tlb_match_2[ 7] = (s_vpn_2 == tlb_vpn[ 7]) && ((s_asid_2 == tlb_asid[ 7]) || tlb_g[ 7]);
    assign tlb_match_2[ 8] = (s_vpn_2 == tlb_vpn[ 8]) && ((s_asid_2 == tlb_asid[ 8]) || tlb_g[ 8]);
    assign tlb_match_2[ 9] = (s_vpn_2 == tlb_vpn[ 9]) && ((s_asid_2 == tlb_asid[ 9]) || tlb_g[ 9]);
    assign tlb_match_2[10] = (s_vpn_2 == tlb_vpn[10]) && ((s_asid_2 == tlb_asid[10]) || tlb_g[10]);
    assign tlb_match_2[11] = (s_vpn_2 == tlb_vpn[11]) && ((s_asid_2 == tlb_asid[11]) || tlb_g[11]);
    assign tlb_match_2[12] = (s_vpn_2 == tlb_vpn[12]) && ((s_asid_2 == tlb_asid[12]) || tlb_g[12]);
    assign tlb_match_2[13] = (s_vpn_2 == tlb_vpn[13]) && ((s_asid_2 == tlb_asid[13]) || tlb_g[13]);
    assign tlb_match_2[14] = (s_vpn_2 == tlb_vpn[14]) && ((s_asid_2 == tlb_asid[14]) || tlb_g[14]);
    assign tlb_match_2[15] = (s_vpn_2 == tlb_vpn[15]) && ((s_asid_2 == tlb_asid[15]) || tlb_g[15]);

    // search port 1
    assign s_found_2     = |tlb_match_2;
    encoder16 en1 (
        .in     (tlb_match_2),
        .out    (s_index_2)
    );
    assign s_pfn_2       = 
        {20{tlb_match_2[ 0] & ~s_odd_2}} & tlb_pfn0[ 0] |
        {20{tlb_match_2[ 0] &  s_odd_2}} & tlb_pfn1[ 0] |
        {20{tlb_match_2[ 1] & ~s_odd_2}} & tlb_pfn0[ 1] |
        {20{tlb_match_2[ 1] &  s_odd_2}} & tlb_pfn1[ 1] |
        {20{tlb_match_2[ 2] & ~s_odd_2}} & tlb_pfn0[ 2] |
        {20{tlb_match_2[ 2] &  s_odd_2}} & tlb_pfn1[ 2] |
        {20{tlb_match_2[ 3] & ~s_odd_2}} & tlb_pfn0[ 3] |
        {20{tlb_match_2[ 3] &  s_odd_2}} & tlb_pfn1[ 3] |
        {20{tlb_match_2[ 4] & ~s_odd_2}} & tlb_pfn0[ 4] |
        {20{tlb_match_2[ 4] &  s_odd_2}} & tlb_pfn1[ 4] |
        {20{tlb_match_2[ 5] & ~s_odd_2}} & tlb_pfn0[ 5] |
        {20{tlb_match_2[ 5] &  s_odd_2}} & tlb_pfn1[ 5] |
        {20{tlb_match_2[ 6] & ~s_odd_2}} & tlb_pfn0[ 6] |
        {20{tlb_match_2[ 6] &  s_odd_2}} & tlb_pfn1[ 6] |
        {20{tlb_match_2[ 7] & ~s_odd_2}} & tlb_pfn0[ 7] |
        {20{tlb_match_2[ 7] &  s_odd_2}} & tlb_pfn1[ 7] |
        {20{tlb_match_2[ 8] & ~s_odd_2}} & tlb_pfn0[ 8] |
        {20{tlb_match_2[ 8] &  s_odd_2}} & tlb_pfn1[ 8] |
        {20{tlb_match_2[ 9] & ~s_odd_2}} & tlb_pfn0[ 9] |
        {20{tlb_match_2[ 9] &  s_odd_2}} & tlb_pfn1[ 9] |
        {20{tlb_match_2[10] & ~s_odd_2}} & tlb_pfn0[10] |
        {20{tlb_match_2[10] &  s_odd_2}} & tlb_pfn1[10] |
        {20{tlb_match_2[11] & ~s_odd_2}} & tlb_pfn0[11] |
        {20{tlb_match_2[11] &  s_odd_2}} & tlb_pfn1[11] |
        {20{tlb_match_2[12] & ~s_odd_2}} & tlb_pfn0[12] |
        {20{tlb_match_2[12] &  s_odd_2}} & tlb_pfn1[12] |
        {20{tlb_match_2[13] & ~s_odd_2}} & tlb_pfn0[13] |
        {20{tlb_match_2[13] &  s_odd_2}} & tlb_pfn1[13] |
        {20{tlb_match_2[14] & ~s_odd_2}} & tlb_pfn0[14] |
        {20{tlb_match_2[14] &  s_odd_2}} & tlb_pfn1[14] |
        {20{tlb_match_2[15] & ~s_odd_2}} & tlb_pfn0[15] |
        {20{tlb_match_2[15] &  s_odd_2}} & tlb_pfn1[15] ;
        
    assign s_c_2         =
        {20{tlb_match_2[ 0] & ~s_odd_2}} & tlb_c0[ 0]   |
        {20{tlb_match_2[ 0] &  s_odd_2}} & tlb_c1[ 0]   |
        {20{tlb_match_2[ 1] & ~s_odd_2}} & tlb_c0[ 1]   |
        {20{tlb_match_2[ 1] &  s_odd_2}} & tlb_c1[ 1]   |
        {20{tlb_match_2[ 2] & ~s_odd_2}} & tlb_c0[ 2]   |
        {20{tlb_match_2[ 2] &  s_odd_2}} & tlb_c1[ 2]   |
        {20{tlb_match_2[ 3] & ~s_odd_2}} & tlb_c0[ 3]   |
        {20{tlb_match_2[ 3] &  s_odd_2}} & tlb_c1[ 3]   |
        {20{tlb_match_2[ 4] & ~s_odd_2}} & tlb_c0[ 4]   |
        {20{tlb_match_2[ 4] &  s_odd_2}} & tlb_c1[ 4]   |
        {20{tlb_match_2[ 5] & ~s_odd_2}} & tlb_c0[ 5]   |
        {20{tlb_match_2[ 5] &  s_odd_2}} & tlb_c1[ 5]   |
        {20{tlb_match_2[ 6] & ~s_odd_2}} & tlb_c0[ 6]   |
        {20{tlb_match_2[ 6] &  s_odd_2}} & tlb_c1[ 6]   |
        {20{tlb_match_2[ 7] & ~s_odd_2}} & tlb_c0[ 7]   |
        {20{tlb_match_2[ 7] &  s_odd_2}} & tlb_c1[ 7]   |
        {20{tlb_match_2[ 8] & ~s_odd_2}} & tlb_c0[ 8]   |
        {20{tlb_match_2[ 8] &  s_odd_2}} & tlb_c1[ 8]   |
        {20{tlb_match_2[ 9] & ~s_odd_2}} & tlb_c0[ 9]   |
        {20{tlb_match_2[ 9] &  s_odd_2}} & tlb_c1[ 9]   |
        {20{tlb_match_2[10] & ~s_odd_2}} & tlb_c0[10]   |
        {20{tlb_match_2[10] &  s_odd_2}} & tlb_c1[10]   |
        {20{tlb_match_2[11] & ~s_odd_2}} & tlb_c0[11]   |
        {20{tlb_match_2[11] &  s_odd_2}} & tlb_c1[11]   |
        {20{tlb_match_2[12] & ~s_odd_2}} & tlb_c0[12]   |
        {20{tlb_match_2[12] &  s_odd_2}} & tlb_c1[12]   |
        {20{tlb_match_2[13] & ~s_odd_2}} & tlb_c0[13]   |
        {20{tlb_match_2[13] &  s_odd_2}} & tlb_c1[13]   |
        {20{tlb_match_2[14] & ~s_odd_2}} & tlb_c0[14]   |
        {20{tlb_match_2[14] &  s_odd_2}} & tlb_c1[14]   |
        {20{tlb_match_2[15] & ~s_odd_2}} & tlb_c0[15]   |
        {20{tlb_match_2[15] &  s_odd_2}} & tlb_c1[15]   ;
    assign s_d_2         =
        {20{tlb_match_2[ 0] & ~s_odd_2}} & tlb_d0[ 0]   |
        {20{tlb_match_2[ 0] &  s_odd_2}} & tlb_d1[ 0]   |
        {20{tlb_match_2[ 1] & ~s_odd_2}} & tlb_d0[ 1]   |
        {20{tlb_match_2[ 1] &  s_odd_2}} & tlb_d1[ 1]   |
        {20{tlb_match_2[ 2] & ~s_odd_2}} & tlb_d0[ 2]   |
        {20{tlb_match_2[ 2] &  s_odd_2}} & tlb_d1[ 2]   |
        {20{tlb_match_2[ 3] & ~s_odd_2}} & tlb_d0[ 3]   |
        {20{tlb_match_2[ 3] &  s_odd_2}} & tlb_d1[ 3]   |
        {20{tlb_match_2[ 4] & ~s_odd_2}} & tlb_d0[ 4]   |
        {20{tlb_match_2[ 4] &  s_odd_2}} & tlb_d1[ 4]   |
        {20{tlb_match_2[ 5] & ~s_odd_2}} & tlb_d0[ 5]   |
        {20{tlb_match_2[ 5] &  s_odd_2}} & tlb_d1[ 5]   |
        {20{tlb_match_2[ 6] & ~s_odd_2}} & tlb_d0[ 6]   |
        {20{tlb_match_2[ 6] &  s_odd_2}} & tlb_d1[ 6]   |
        {20{tlb_match_2[ 7] & ~s_odd_2}} & tlb_d0[ 7]   |
        {20{tlb_match_2[ 7] &  s_odd_2}} & tlb_d1[ 7]   |
        {20{tlb_match_2[ 8] & ~s_odd_2}} & tlb_d0[ 8]   |
        {20{tlb_match_2[ 8] &  s_odd_2}} & tlb_d1[ 8]   |
        {20{tlb_match_2[ 9] & ~s_odd_2}} & tlb_d0[ 9]   |
        {20{tlb_match_2[ 9] &  s_odd_2}} & tlb_d1[ 9]   |
        {20{tlb_match_2[10] & ~s_odd_2}} & tlb_d0[10]   |
        {20{tlb_match_2[10] &  s_odd_2}} & tlb_d1[10]   |
        {20{tlb_match_2[11] & ~s_odd_2}} & tlb_d0[11]   |
        {20{tlb_match_2[11] &  s_odd_2}} & tlb_d1[11]   |
        {20{tlb_match_2[12] & ~s_odd_2}} & tlb_d0[12]   |
        {20{tlb_match_2[12] &  s_odd_2}} & tlb_d1[12]   |
        {20{tlb_match_2[13] & ~s_odd_2}} & tlb_d0[13]   |
        {20{tlb_match_2[13] &  s_odd_2}} & tlb_d1[13]   |
        {20{tlb_match_2[14] & ~s_odd_2}} & tlb_d0[14]   |
        {20{tlb_match_2[14] &  s_odd_2}} & tlb_d1[14]   |
        {20{tlb_match_2[15] & ~s_odd_2}} & tlb_d0[15]   |
        {20{tlb_match_2[15] &  s_odd_2}} & tlb_d1[15]   ;
    assign s_v_2         =
        {20{tlb_match_2[ 0] & ~s_odd_2}} & tlb_v0[ 0]   |
        {20{tlb_match_2[ 0] &  s_odd_2}} & tlb_v1[ 0]   |
        {20{tlb_match_2[ 1] & ~s_odd_2}} & tlb_v0[ 1]   |
        {20{tlb_match_2[ 1] &  s_odd_2}} & tlb_v1[ 1]   |
        {20{tlb_match_2[ 2] & ~s_odd_2}} & tlb_v0[ 2]   |
        {20{tlb_match_2[ 2] &  s_odd_2}} & tlb_v1[ 2]   |
        {20{tlb_match_2[ 3] & ~s_odd_2}} & tlb_v0[ 3]   |
        {20{tlb_match_2[ 3] &  s_odd_2}} & tlb_v1[ 3]   |
        {20{tlb_match_2[ 4] & ~s_odd_2}} & tlb_v0[ 4]   |
        {20{tlb_match_2[ 4] &  s_odd_2}} & tlb_v1[ 4]   |
        {20{tlb_match_2[ 5] & ~s_odd_2}} & tlb_v0[ 5]   |
        {20{tlb_match_2[ 5] &  s_odd_2}} & tlb_v1[ 5]   |
        {20{tlb_match_2[ 6] & ~s_odd_2}} & tlb_v0[ 6]   |
        {20{tlb_match_2[ 6] &  s_odd_2}} & tlb_v1[ 6]   |
        {20{tlb_match_2[ 7] & ~s_odd_2}} & tlb_v0[ 7]   |
        {20{tlb_match_2[ 7] &  s_odd_2}} & tlb_v1[ 7]   |
        {20{tlb_match_2[ 8] & ~s_odd_2}} & tlb_v0[ 8]   |
        {20{tlb_match_2[ 8] &  s_odd_2}} & tlb_v1[ 8]   |
        {20{tlb_match_2[ 9] & ~s_odd_2}} & tlb_v0[ 9]   |
        {20{tlb_match_2[ 9] &  s_odd_2}} & tlb_v1[ 9]   |
        {20{tlb_match_2[10] & ~s_odd_2}} & tlb_v0[10]   |
        {20{tlb_match_2[10] &  s_odd_2}} & tlb_v1[10]   |
        {20{tlb_match_2[11] & ~s_odd_2}} & tlb_v0[11]   |
        {20{tlb_match_2[11] &  s_odd_2}} & tlb_v1[11]   |
        {20{tlb_match_2[12] & ~s_odd_2}} & tlb_v0[12]   |
        {20{tlb_match_2[12] &  s_odd_2}} & tlb_v1[12]   |
        {20{tlb_match_2[13] & ~s_odd_2}} & tlb_v0[13]   |
        {20{tlb_match_2[13] &  s_odd_2}} & tlb_v1[13]   |
        {20{tlb_match_2[14] & ~s_odd_2}} & tlb_v0[14]   |
        {20{tlb_match_2[14] &  s_odd_2}} & tlb_v1[14]   |
        {20{tlb_match_2[15] & ~s_odd_2}} & tlb_v0[15]   |
        {20{tlb_match_2[15] &  s_odd_2}} & tlb_v1[15]   ;

endmodule