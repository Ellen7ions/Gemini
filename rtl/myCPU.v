`timescale 1ns / 1ps

module myCPU (
    input   wire        clk,
    input   wire        rst,
    input   wire [5:0]  interrupt,

    // output  wire        sram_inst_ena,
    // output  wire [31:0] sram_inst_addr,
    // input   wire [31:0] sram_inst_rdata_1,
    // input   wire [31:0] sram_inst_rdata_2,
    // input   wire        sram_inst_ok_1,
    // input   wire        sram_inst_ok_2,
    // input   wire        i_cache_stall_req,
    output  wire        sram_data_ena,
    output  wire [3 :0] sram_data_wen,
    output  wire [31:0] sram_data_addr,
    output  wire [31:0] sram_data_wdata,
    input   wire [31:0] sram_data_rdata,
    input   wire        d_cache_stall_req,

    output  wire [3 :0] awid,
    output  wire [31:0] awaddr,
    output  wire [7 :0] awlen,
    output  wire [2 :0] awsize,
    output  wire [1 :0] awburst,
    output  wire        awvalid,
    input   wire        awready,
    output  wire [31:0] wdata,
    output  wire [3 :0] wstrb,
    output  wire        wlast,
    output  wire        wvalid,
    input   wire        wready,
    output  wire [3 :0] arid,
    output  wire [31:0] araddr,
    output  wire [7 :0] arlen,
    output  wire [2 :0] arsize,
    output  wire [1 :0] arburst,
    output  wire        arvalid,
    input   wire        arready,
    input   wire [3 :0] rid,
    input   wire [31:0] rdata,
    input   wire [1 :0] rresp,
    input   wire        rlast,
    input   wire        rvalid,
    output  wire        rready,
    input   wire [3 :0] bid,
    input   wire [1 :0] bresp,
    input   wire        bvalid,
    output  wire        bready,

    output  wire [31:0] debug_wb_pc_1,
    output  wire [3 :0] debug_wb_rf_wen_1,
    output  wire [4 :0] debug_wb_rf_wnum_1,
    output  wire [31:0] debug_wb_rf_wdata_1,
    output  wire [31:0] debug_wb_pc_2,
    output  wire [3 :0] debug_wb_rf_wen_2,
    output  wire [4 :0] debug_wb_rf_wnum_2,
    output  wire [31:0] debug_wb_rf_wdata_2
);

    wire        sram_inst_ena;
    wire [31:0] sram_inst_addr;
    wire [31:0] sram_inst_rdata_1;
    wire [31:0] sram_inst_rdata_2;
    wire        sram_inst_ok_1;
    wire        sram_inst_ok_2;
    wire        i_cache_stall_req;

    gemini gemini0 (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .interrupt              (interrupt              ),
        
        .sram_inst_ena          (sram_inst_ena          ),
        .sram_inst_addr         (sram_inst_addr         ),
        .sram_inst_rdata_1      (sram_inst_rdata_1      ),    
        .sram_inst_rdata_2      (sram_inst_rdata_2      ),    
        .sram_inst_ok_1         (sram_inst_ok_1         ),
        .sram_inst_ok_2         (sram_inst_ok_2         ),
        .i_cache_stall_req      (i_cache_stall_req      ),

        .sram_data_ena          (sram_data_ena          ),
        .sram_data_wen          (sram_data_wen          ),
        .sram_data_addr         (sram_data_addr         ),
        .sram_data_wdata        (sram_data_wdata        ),    
        .sram_data_rdata        (sram_data_rdata        ),
        .d_cache_stall_req      (d_cache_stall_req      ),

        .debug_wb_pc_1          (debug_wb_pc_1          ),
        .debug_wb_rf_wen_1      (debug_wb_rf_wen_1      ),
        .debug_wb_rf_wnum_1     (debug_wb_rf_wnum_1     ),
        .debug_wb_rf_wdata_1    (debug_wb_rf_wdata_1    ),
        .debug_wb_pc_2          (debug_wb_pc_2          ),
        .debug_wb_rf_wen_2      (debug_wb_rf_wen_2      ),
        .debug_wb_rf_wnum_2     (debug_wb_rf_wnum_2     ),
        .debug_wb_rf_wdata_2    (debug_wb_rf_wdata_2    )
    );

    i_cache i_cache0 (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .cpu_instr_ena          (sram_inst_ena          ),
        .cpu_instr_addr         (sram_inst_addr         ),   
        .cpu_instr_data         (sram_inst_rdata_1      ),
        .cpu_instr_data2        (sram_inst_rdata_2      ),    
        .cpu_instr_data_1ok     (sram_inst_ok_1         ),    
        .cpu_instr_data_2ok     (sram_inst_ok_2         ),    
        .stall_all              (i_cache_stall_req      ),

        .awid                   (awid                   ),
        .awaddr                 (awaddr                 ),
        .awlen                  (awlen                  ),
        .awsize                 (awsize                 ),
        .awburst                (awburst                ),    
        .awvalid                (awvalid                ),    
        .awready                (awready                ),    
        .wdata                  (wdata                  ),
        .wstrb                  (wstrb                  ),
        .wlast                  (wlast                  ),
        .wvalid                 (wvalid                 ),
        .wready                 (wready                 ),
        .arid                   (arid                   ),
        .araddr                 (araddr                 ),
        .arlen                  (arlen                  ),
        .arsize                 (arsize                 ),
        .arburst                (arburst                ),    
        .arvalid                (arvalid                ),    
        .arready                (arready                ),    
        .rid                    (rid                    ),
        .rdata                  (rdata                  ),
        .rresp                  (rresp                  ),
        .rlast                  (rlast                  ),
        .rvalid                 (rvalid                 ),
        .rready                 (rready                 ),
        .bid                    (bid                    ),
        .bresp                  (bresp                  ),
        .bvalid                 (bvalid                 ),
        .bready                 (bready                 )
    );

endmodule