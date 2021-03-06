`timescale 1ns / 1ps


module mmu_mapping #(
    parameter TLBNUM = 16
    ) (
    input   wire        clk,

    input   wire        is_tlbp,
    input   wire        is_tlbr,
    input   wire        is_tlbwi,
    input   wire        is_tlbwr,

    input   wire [31:0] r_cp0_Random,
    input   wire [31:0] r_cp0_Config,
    input   wire [31:0] r_cp0_Index,
    input   wire [31:0] r_cp0_EntryHi,
    input   wire [31:0] r_cp0_EntryLo0,
    input   wire [31:0] r_cp0_EntryLo1,

    output  wire        w_cp0_tlbp_ena,
    output  wire        w_cp0_tlbr_ena,
    output  wire [31:0] w_cp0_Index,
    output  wire [31:0] w_cp0_EntryHi,
    output  wire [31:0] w_cp0_EntryLo0,
    output  wire [31:0] w_cp0_EntryLo1,

    input   wire        inst_ena,
    input   wire [31:0] inst_addr_next_pc,
    output  wire [31:0] inst_rdata_1,
    output  wire [31:0] inst_rdata_2,
    output  wire        inst_ok_1,
    output  wire        inst_ok_2,
    output  wire        inst_tlb_refill_tlbl,
    output  wire        inst_tlb_invalid_tlbl,

    input   wire        lsu1_ls_ena,
    input   wire [3 :0] lsu1_load_type,
    input   wire [3 :0] lsu1_wea,
    input   wire [31:0] lsu1_wdata,
    input   wire [31:0] lsu1_vaddr,
    output  wire        lsu1_tlb_refill_tlbl,
    output  wire        lsu1_tlb_refill_tlbs,
    output  wire        lsu1_tlb_invalid_tlbl,
    output  wire        lsu1_tlb_invalid_tlbs,
    output  wire        lsu1_tlb_modify,
    output  wire [31:0] lsu1_rdata,     // send to lsu2

    // sram
    output  wire        sram_inst_ena,
    output  wire        sram_inst_uncached,
    output  wire [31:0] sram_inst_vaddr,
    output  wire [31:0] sram_inst_psyaddr,
    input   wire [31:0] sram_inst_rdata_1,
    input   wire [31:0] sram_inst_rdata_2,
    input   wire        sram_inst_ok_1,
    input   wire        sram_inst_ok_2,

    output  wire        sram_data_ena,
    output  wire [3 :0] sram_data_wen,
    output  wire [3 :0] sram_load_type,
    output  wire        sram_uncached,
    output  wire [31:0] sram_data_vaddr,
    output  wire [31:0] sram_data_psyaddr,
    output  wire [31:0] sram_data_wdata,
    input   wire [31:0] sram_data_rdata
);
    wire [              18:0]   s_vpn_1;
    wire                        s_odd_1;
    wire [              7 :0]   s_asid_1;
    wire                        s_found_1;
    wire [$clog2(TLBNUM)-1:0]   s_index_1;
    wire [              19:0]   s_pfn_1;
    wire [              2 :0]   s_c_1;
    wire                        s_d_1;
    wire                        s_v_1;
    wire [              18:0]   s_vpn_2;
    wire                        s_odd_2;
    wire [              7 :0]   s_asid_2;
    wire                        s_found_2;
    wire [$clog2(TLBNUM)-1:0]   s_index_2;
    wire [              19:0]   s_pfn_2;
    wire [              2 :0]   s_c_2;
    wire                        s_d_2;
    wire                        s_v_2;
    wire                        we;
    wire [$clog2(TLBNUM)-1:0]   w_index;
    wire [              18:0]   w_vpn;
    wire [              7 :0]   w_asid;
    wire                        w_g;
    wire [              19:0]   w_pfn0;
    wire [              2 :0]   w_c0;
    wire                        w_d0;
    wire                        w_v0;
    wire [              19:0]   w_pfn1;
    wire [              2 :0]   w_c1;
    wire                        w_d1;
    wire                        w_v1;
    wire [$clog2(TLBNUM)-1:0]   r_index;
    wire [              18:0]   r_vpn;
    wire [              7 :0]   r_asid;
    wire                        r_g;
    wire [              19:0]   r_pfn0;
    wire [              2 :0]   r_c0;
    wire                        r_d0;
    wire                        r_v0;
    wire [              19:0]   r_pfn1;
    wire [              2 :0]   r_c1;
    wire                        r_d1;
    wire                        r_v1;

    wire                        inst_psyaddr_ena;
    wire [              31:0]   inst_psyaddr;
    wire                        data_psyaddr_ena;
    wire                        data_uncached;
    wire [              31:0]   data_psyaddr;

    wire                        inst_uncached;

    assign sram_inst_ena    =   inst_psyaddr_ena & inst_ena;
    assign sram_inst_uncached = inst_uncached;
    assign sram_inst_vaddr  =   inst_addr_next_pc;
    assign sram_inst_psyaddr=   inst_psyaddr;
    assign inst_rdata_1     =   sram_inst_rdata_1;
    assign inst_rdata_2     =   sram_inst_rdata_2;
    assign inst_ok_1        =   sram_inst_ok_1;
    assign inst_ok_2        =   sram_inst_ok_2;

    assign sram_data_ena    =   data_psyaddr_ena & lsu1_ls_ena;
    assign sram_data_wen    =   lsu1_wea;
    assign sram_load_type   =   lsu1_load_type;
    assign sram_uncached    =   data_uncached;
    assign sram_data_vaddr  =   lsu1_vaddr;
    assign sram_data_psyaddr=   data_psyaddr;
    assign sram_data_wdata  =   lsu1_wdata;
    assign lsu1_rdata       =   sram_data_rdata;

    mmu_inst #(TLBNUM) inst_map (
        .en                 (inst_ena               ),
        .vaddr              (inst_addr_next_pc      ),
        .uncached           (inst_uncached          ),
        .r_cp0_Config       (r_cp0_Config           ),
        .r_cp0_EntryHi      (r_cp0_EntryHi          ),
        .psyaddr_ena        (inst_psyaddr_ena       ),
        .psyaddr            (inst_psyaddr           ),
        .is_tlb_refill_tlbl (inst_tlb_refill_tlbl   ),
        .is_tlb_invalid_tlbl(inst_tlb_invalid_tlbl  ),
        .s_vpn              (s_vpn_1                ),
        .s_odd              (s_odd_1                ),
        .s_asid             (s_asid_1               ),
        .s_found            (s_found_1              ),
        .s_index            (s_index_1              ),
        .s_pfn              (s_pfn_1                ),
        .s_c                (s_c_1                  ),
        .s_d                (s_d_1                  ),
        .s_v                (s_v_1                  )
    );

    mmu_data #(TLBNUM) data_map (
        .en                 (lsu1_ls_ena            ),
        .ls_sel             (|lsu1_wea              ),
        .vaddr              (lsu1_vaddr             ),
        .uncached           (data_uncached          ),
        .psyaddr_ena        (data_psyaddr_ena       ),
        .psyaddr            (data_psyaddr           ),
        .is_tlb_refill_tlbl (lsu1_tlb_refill_tlbl   ),    
        .is_tlb_refill_tlbs (lsu1_tlb_refill_tlbs   ),    
        .is_tlb_invalid_tlbl(lsu1_tlb_invalid_tlbl  ),        
        .is_tlb_invalid_tlbs(lsu1_tlb_invalid_tlbs  ),        
        .is_tlb_modify      (lsu1_tlb_modify        ),

        .is_tlbp            (is_tlbp                ),
        .is_tlbr            (is_tlbr                ),
        .is_tlbwi           (is_tlbwi               ),
        .is_tlbwr           (is_tlbwr               ),
        
        .r_cp0_Random       (r_cp0_Random           ),
        .r_cp0_Config       (r_cp0_Config           ),
        .r_cp0_Index        (r_cp0_Index            ),
        .r_cp0_EntryHi      (r_cp0_EntryHi          ),
        .r_cp0_EntryLo0     (r_cp0_EntryLo0         ),
        .r_cp0_EntryLo1     (r_cp0_EntryLo1         ),

        .w_cp0_tlbp_ena     (w_cp0_tlbp_ena         ),
        .w_cp0_tlbr_ena     (w_cp0_tlbr_ena         ),
        .w_cp0_Index        (w_cp0_Index            ),
        .w_cp0_EntryHi      (w_cp0_EntryHi          ),
        .w_cp0_EntryLo0     (w_cp0_EntryLo0         ),
        .w_cp0_EntryLo1     (w_cp0_EntryLo1         ),

        .s_vpn              (s_vpn_2                ),
        .s_odd              (s_odd_2                ),
        .s_asid             (s_asid_2               ),
        .s_found            (s_found_2              ),    
        .s_index            (s_index_2              ),    
        .s_pfn              (s_pfn_2                ),
        .s_c                (s_c_2                  ),
        .s_d                (s_d_2                  ),
        .s_v                (s_v_2                  ),

        .we                 (we                     ),
        .w_index            (w_index                ),        
        .w_vpn              (w_vpn                  ),    
        .w_asid             (w_asid                 ),    
        .w_g                (w_g                    ),    
        .w_pfn0             (w_pfn0                 ),    
        .w_c0               (w_c0                   ),    
        .w_d0               (w_d0                   ),    
        .w_v0               (w_v0                   ),    
        .w_pfn1             (w_pfn1                 ),    
        .w_c1               (w_c1                   ),    
        .w_d1               (w_d1                   ),    
        .w_v1               (w_v1                   ),

        .r_index            (r_index                ),    
        .r_vpn              (r_vpn                  ),
        .r_asid             (r_asid                 ),
        .r_g                (r_g                    ),
        .r_pfn0             (r_pfn0                 ),
        .r_c0               (r_c0                   ),
        .r_d0               (r_d0                   ),
        .r_v0               (r_v0                   ),
        .r_pfn1             (r_pfn1                 ),
        .r_c1               (r_c1                   ),
        .r_d1               (r_d1                   ),
        .r_v1               (r_v1                   )
    );

    tlb #(TLBNUM) tlb0 (
        .clk            (clk                ),
        .s_vpn_1        (s_vpn_1            ),
        .s_odd_1        (s_odd_1            ),
        .s_asid_1       (s_asid_1           ),
        .s_found_1      (s_found_1          ),
        .s_index_1      (s_index_1          ),
        .s_pfn_1        (s_pfn_1            ),
        .s_c_1          (s_c_1              ),
        .s_d_1          (s_d_1              ),
        .s_v_1          (s_v_1              ),

        .s_vpn_2        (s_vpn_2            ),
        .s_odd_2        (s_odd_2            ),
        .s_asid_2       (s_asid_2           ),
        .s_found_2      (s_found_2          ),
        .s_index_2      (s_index_2          ),
        .s_pfn_2        (s_pfn_2            ),
        .s_c_2          (s_c_2              ),
        .s_d_2          (s_d_2              ),
        .s_v_2          (s_v_2              ),

        .we             (we                 ),
        .w_index        (w_index            ),
        .w_vpn          (w_vpn              ),
        .w_asid         (w_asid             ),
        .w_g            (w_g                ),
        .w_pfn0         (w_pfn0             ),
        .w_c0           (w_c0               ),
        .w_d0           (w_d0               ),
        .w_v0           (w_v0               ),
        .w_pfn1         (w_pfn1             ),
        .w_c1           (w_c1               ),
        .w_d1           (w_d1               ),
        .w_v1           (w_v1               ),

        .r_index        (r_index            ),
        .r_vpn          (r_vpn              ),
        .r_asid         (r_asid             ),
        .r_g            (r_g                ),
        .r_pfn0         (r_pfn0             ),
        .r_c0           (r_c0               ),
        .r_d0           (r_d0               ),
        .r_v0           (r_v0               ),
        .r_pfn1         (r_pfn1             ),
        .r_c1           (r_c1               ),
        .r_d1           (r_d1               ),
        .r_v1           (r_v1               )
    );

endmodule