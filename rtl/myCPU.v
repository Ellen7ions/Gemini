`timescale 1ns / 1ps

module myCPU (
    input   wire        clk,
    input   wire        rst,
    input   wire [5:0]  interrupt,

    output  wire        sram_inst_ena,
    output  wire [31:0] sram_inst_addr,
    input   wire [31:0] sram_inst_rdata_1,
    input   wire [31:0] sram_inst_rdata_2,
    input   wire        sram_inst_ok_1,
    input   wire        sram_inst_ok_2,
    input   wire        i_cache_stall_req,
    output  wire        sram_data_ena,
    output  wire [3 :0] sram_data_wen,
    output  wire [31:0] sram_data_addr,
    output  wire [31:0] sram_data_wdata,
    input   wire [31:0] sram_data_rdata,
    input   wire        d_cache_stall_req,

    output  wire [31:0] debug_wb_pc_1,
    output  wire [3 :0] debug_wb_rf_wen_1,
    output  wire [4 :0] debug_wb_rf_wnum_1,
    output  wire [31:0] debug_wb_rf_wdata_1,
    output  wire [31:0] debug_wb_pc_2,
    output  wire [3 :0] debug_wb_rf_wen_2,
    output  wire [4 :0] debug_wb_rf_wnum_2,
    output  wire [31:0] debug_wb_rf_wdata_2
);
    
    wire        is_tlbp;
    wire        is_tlbr;
    wire        is_tlbwi;
    wire [31:0] r_cp0_Index;
    wire [31:0] r_cp0_EntryHi;
    wire [31:0] r_cp0_EntryLo0;
    wire [31:0] r_cp0_EntryLo1;
    wire        w_cp0_tlbp_ena;
    wire        w_cp0_tlbr_ena;
    wire [31:0] w_cp0_Index;
    wire [31:0] w_cp0_EntryHi;
    wire [31:0] w_cp0_EntryLo0;
    wire [31:0] w_cp0_EntryLo1;
    wire        inst_ena;
    wire [31:0] inst_addr_next_pc;
    wire [31:0] inst_rdata_1;
    wire [31:0] inst_rdata_2;
    wire        inst_ok_1;
    wire        inst_ok_2;
    wire        inst_tlb_refill_tlbl;
    wire        inst_tlb_invalid_tlbl;
    wire        data_ena;
    wire [3 :0] data_wea;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire        data_tlb_refill_tlbl;
    wire        data_tlb_refill_tlbs;
    wire        data_tlb_invalid_tlbl;
    wire        data_tlb_invalid_tlbs;
    wire        data_tlb_modify;

    gemini gemini0 (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .interrupt              (interrupt              ),
        .is_tlbp                (is_tlbp                ),
        .is_tlbr                (is_tlbr                ),
        .is_tlbwi               (is_tlbwi               ),
        .r_cp0_Index            (r_cp0_Index            ),    
        .r_cp0_EntryHi          (r_cp0_EntryHi          ),    
        .r_cp0_EntryLo0         (r_cp0_EntryLo0         ),    
        .r_cp0_EntryLo1         (r_cp0_EntryLo1         ),    
        .w_cp0_tlbp_ena         (w_cp0_tlbp_ena         ),    
        .w_cp0_tlbr_ena         (w_cp0_tlbr_ena         ),    
        .w_cp0_Index            (w_cp0_Index            ),    
        .w_cp0_EntryHi          (w_cp0_EntryHi          ),    
        .w_cp0_EntryLo0         (w_cp0_EntryLo0         ),    
        .w_cp0_EntryLo1         (w_cp0_EntryLo1         ),    
        .inst_ena               (inst_ena               ),
        .inst_addr_next_pc      (inst_addr_next_pc      ),        
        .inst_rdata_1           (inst_rdata_1           ),    
        .inst_rdata_2           (inst_rdata_2           ),    
        .inst_ok_1              (inst_ok_1              ),
        .inst_ok_2              (inst_ok_2              ),
        .i_cache_stall_req      (i_cache_stall_req      ),
        .inst_tlb_refill_tlbl   (inst_tlb_refill_tlbl   ),            
        .inst_tlb_invalid_tlbl  (inst_tlb_invalid_tlbl  ),            
        .data_ena               (data_ena               ),
        .data_wea               (data_wea               ),
        .data_addr              (data_addr              ),
        .data_wdata             (data_wdata             ),
        .data_rdata             (data_rdata             ),
        .d_cache_stall_req      (d_cache_stall_req      ),
        .data_tlb_refill_tlbl   (data_tlb_refill_tlbl   ),            
        .data_tlb_refill_tlbs   (data_tlb_refill_tlbs   ),            
        .data_tlb_invalid_tlbl  (data_tlb_invalid_tlbl  ),            
        .data_tlb_invalid_tlbs  (data_tlb_invalid_tlbs  ),            
        .data_tlb_modify        (data_tlb_modify        ),        
        
        .debug_wb_pc_1          (debug_wb_pc_1          ),
        .debug_wb_rf_wen_1      (debug_wb_rf_wen_1      ),
        .debug_wb_rf_wnum_1     (debug_wb_rf_wnum_1     ),
        .debug_wb_rf_wdata_1    (debug_wb_rf_wdata_1    ),
        .debug_wb_pc_2          (debug_wb_pc_2          ),
        .debug_wb_rf_wen_2      (debug_wb_rf_wen_2      ),
        .debug_wb_rf_wnum_2     (debug_wb_rf_wnum_2     ),
        .debug_wb_rf_wdata_2    (debug_wb_rf_wdata_2    )
    );

    mmu mmu0 (
        .clk                    (clk                    ),
        .rst                    (),
        
        .is_tlbp                (is_tlbp                ),
        .is_tlbr                (is_tlbr                ),
        .is_tlbwi               (is_tlbwi               ),
        .r_cp0_Index            (r_cp0_Index            ),
        .r_cp0_EntryHi          (r_cp0_EntryHi          ),
        .r_cp0_EntryLo0         (r_cp0_EntryLo0         ),
        .r_cp0_EntryLo1         (r_cp0_EntryLo1         ),
        .w_cp0_tlbp_ena         (w_cp0_tlbp_ena         ),
        .w_cp0_tlbr_ena         (w_cp0_tlbr_ena         ),
        .w_cp0_Index            (w_cp0_Index            ),
        .w_cp0_EntryHi          (w_cp0_EntryHi          ),
        .w_cp0_EntryLo0         (w_cp0_EntryLo0         ),
        .w_cp0_EntryLo1         (w_cp0_EntryLo1         ),
        .inst_ena               (inst_ena               ),
        .inst_addr_next_pc      (inst_addr_next_pc      ),
        .inst_rdata_1           (inst_rdata_1           ),
        .inst_rdata_2           (inst_rdata_2           ),
        .inst_ok_1              (inst_ok_1              ),
        .inst_ok_2              (inst_ok_2              ),
        .inst_tlb_refill_tlbl   (inst_tlb_refill_tlbl   ),
        .inst_tlb_invalid_tlbl  (inst_tlb_invalid_tlbl  ),
        .data_ena               (data_ena               ),
        .data_wea               (data_wea               ),
        .data_addr              (data_addr              ),
        .data_wdata             (data_wdata             ),
        .data_rdata             (data_rdata             ),
        .data_tlb_refill_tlbl   (data_tlb_refill_tlbl   ),
        .data_tlb_refill_tlbs   (data_tlb_refill_tlbs   ),
        .data_tlb_invalid_tlbl  (data_tlb_invalid_tlbl  ),
        .data_tlb_invalid_tlbs  (data_tlb_invalid_tlbs  ),
        .data_tlb_modify        (data_tlb_modify        ),

        .sram_inst_ena          (sram_inst_ena          ),
        .sram_inst_addr         (sram_inst_addr         ),
        .sram_inst_rdata_1      (sram_inst_rdata_1      ),
        .sram_inst_rdata_2      (sram_inst_rdata_2      ),
        .sram_inst_ok_1         (sram_inst_ok_1         ),
        .sram_inst_ok_2         (sram_inst_ok_2         ),
        .sram_data_ena          (sram_data_ena          ),
        .sram_data_wen          (sram_data_wen          ),
        .sram_data_addr         (sram_data_addr         ),
        .sram_data_wdata        (sram_data_wdata        ),
        .sram_data_rdata        (sram_data_rdata        )
    );

endmodule