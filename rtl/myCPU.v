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
    // output  wire        sram_data_ena,
    // output  wire [3 :0] sram_data_wen,
    // output  wire [31:0] sram_data_addr,
    // output  wire [31:0] sram_data_wdata,
    // input   wire [31:0] sram_data_rdata,
    // input   wire        d_cache_stall_req,

    output  wire [3 :0] i_awid,
    output  wire [31:0] i_awaddr,
    output  wire [7 :0] i_awlen,
    output  wire [2 :0] i_awsize,
    output  wire [1 :0] i_awburst,
    output  wire        i_awvalid,
    input   wire        i_awready,
    output  wire [31:0] i_wdata,
    output  wire [3 :0] i_wstrb,
    output  wire        i_wlast,
    output  wire        i_wvalid,
    input   wire        i_wready,
    output  wire [3 :0] i_arid,
    output  wire [31:0] i_araddr,
    output  wire [7 :0] i_arlen,
    output  wire [2 :0] i_arsize,
    output  wire [1 :0] i_arburst,
    output  wire        i_arvalid,
    input   wire        i_arready,
    input   wire [3 :0] i_rid,
    input   wire [31:0] i_rdata,
    input   wire [1 :0] i_rresp,
    input   wire        i_rlast,
    input   wire        i_rvalid,
    output  wire        i_rready,
    input   wire [3 :0] i_bid,
    input   wire [1 :0] i_bresp,
    input   wire        i_bvalid,
    output  wire        i_bready,

    output  wire [3 :0] d_awid,
    output  wire [31:0] d_awaddr,
    output  wire [7 :0] d_awlen,
    output  wire [2 :0] d_awsize,
    output  wire [1 :0] d_awburst,
    output  wire        d_awvalid,
    input   wire        d_awready,
    output  wire [31:0] d_wdata,
    output  wire [3 :0] d_wstrb,
    output  wire        d_wlast,
    output  wire        d_wvalid,
    input   wire        d_wready,
    output  wire [3 :0] d_arid,
    output  wire [31:0] d_araddr,
    output  wire [7 :0] d_arlen,
    output  wire [2 :0] d_arsize,
    output  wire [1 :0] d_arburst,
    output  wire        d_arvalid,
    input   wire        d_arready,
    input   wire [3 :0] d_rid,
    input   wire [31:0] d_rdata,
    input   wire [1 :0] d_rresp,
    input   wire        d_rlast,
    input   wire        d_rvalid,
    output  wire        d_rready,
    input   wire [3 :0] d_bid,
    input   wire [1 :0] d_bresp,
    input   wire        d_bvalid,
    output  wire        d_bready,

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
    wire [31:0] sram_inst_vaddr;
    wire [31:0] sram_inst_psyaddr;
    wire [31:0] sram_inst_rdata_1;
    wire [31:0] sram_inst_rdata_2;
    wire        sram_inst_ok_1;
    wire        sram_inst_ok_2;
    wire        i_cache_stall_req;

    wire        sram_data_ena;
    wire [3 :0] sram_data_wen;
    wire [3 :0] sram_load_type;
    wire        sram_uncached;
    wire [31:0] sram_data_vaddr;
    wire [31:0] sram_data_psyaddr;
    wire [31:0] sram_data_wdata;
    wire [31:0] sram_data_rdata;
    wire        d_cache_stall_req;

    gemini gemini0 (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .interrupt              (interrupt              ),
        
        .sram_inst_ena          (sram_inst_ena          ),
        .sram_inst_vaddr        (sram_inst_vaddr        ),
        .sram_inst_psyaddr      (sram_inst_psyaddr      ),
        .sram_inst_rdata_1      (sram_inst_rdata_1      ),    
        .sram_inst_rdata_2      (sram_inst_rdata_2      ),    
        .sram_inst_ok_1         (sram_inst_ok_1         ),
        .sram_inst_ok_2         (sram_inst_ok_2         ),
        .i_cache_stall_req      (i_cache_stall_req      ),

        .sram_data_ena          (sram_data_ena          ),
        .sram_data_wen          (sram_data_wen          ),
        .sram_load_type         (sram_load_type         ),
        .sram_uncached          (sram_uncached          ),
        .sram_data_vaddr        (sram_data_vaddr        ),
        .sram_data_psyaddr      (sram_data_psyaddr      ),
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
        .cpu_instr_vaddr        (sram_inst_vaddr        ),
        .cpu_instr_psyaddr      (sram_inst_psyaddr      ),
        .cpu_instr_data         (sram_inst_rdata_1      ),
        .cpu_instr_data2        (sram_inst_rdata_2      ),
        .cpu_instr_data_1ok     (sram_inst_ok_1         ),
        .cpu_instr_data_2ok     (sram_inst_ok_2         ),
        .stall_all              (i_cache_stall_req      ),

        .awid                   (i_awid                 ),
        .awaddr                 (i_awaddr               ),
        .awlen                  (i_awlen                ),
        .awsize                 (i_awsize               ),
        .awburst                (i_awburst              ),    
        .awvalid                (i_awvalid              ),    
        .awready                (i_awready              ),    
        .wdata                  (i_wdata                ),
        .wstrb                  (i_wstrb                ),
        .wlast                  (i_wlast                ),
        .wvalid                 (i_wvalid               ),
        .wready                 (i_wready               ),
        .arid                   (i_arid                 ),
        .araddr                 (i_araddr               ),
        .arlen                  (i_arlen                ),
        .arsize                 (i_arsize               ),
        .arburst                (i_arburst              ),    
        .arvalid                (i_arvalid              ),    
        .arready                (i_arready              ),    
        .rid                    (i_rid                  ),
        .rdata                  (i_rdata                ),
        .rresp                  (i_rresp                ),
        .rlast                  (i_rlast                ),
        .rvalid                 (i_rvalid               ),
        .rready                 (i_rready               ),
        .bid                    (i_bid                  ),
        .bresp                  (i_bresp                ),
        .bvalid                 (i_bvalid               ),
        .bready                 (i_bready               )
    );

    d_cache d_cache0 (
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        
        .cpu_en                 (sram_data_ena          ),
        .cpu_wen                (sram_data_wen          ),
        .cpu_uncached           (sram_uncached          ),
        .cpu_load_type          (sram_load_type         ),
        .cpu_vaddr              (sram_data_vaddr        ),
        .cpu_psyaddr            (sram_data_psyaddr      ),
        .cpu_wdata              (sram_data_wdata        ),
        .cpu_rdata              (sram_data_rdata        ),
        .cpu_d_cache_stall      (d_cache_stall_req      ),
        
        .axi_awid               (d_awid                 ),
        .axi_awaddr             (d_awaddr               ),
        .axi_awlen              (d_awlen                ),
        .axi_awsize             (d_awsize               ),
        .axi_awburst            (d_awburst              ),
        .axi_awvalid            (d_awvalid              ),
        .axi_awready            (d_awready              ),
        .axi_wdata              (d_wdata                ),
        .axi_wstrb              (d_wstrb                ),
        .axi_wlast              (d_wlast                ),
        .axi_wvalid             (d_wvalid               ),
        .axi_wready             (d_wready               ),
        .axi_arid               (d_arid                 ),
        .axi_araddr             (d_araddr               ),
        .axi_arlen              (d_arlen                ),
        .axi_arsize             (d_arsize               ),
        .axi_arburst            (d_arburst              ),
        .axi_arvalid            (d_arvalid              ),
        .axi_arready            (d_arready              ),
        .axi_rid                (d_rid                  ),
        .axi_rdata              (d_rdata                ),
        .axi_rresp              (d_rresp                ),
        .axi_rlast              (d_rlast                ),
        .axi_rvalid             (d_rvalid               ),
        .axi_rready             (d_rready               ),
        .axi_bid                (d_bid                  ),
        .axi_bresp              (d_bresp                ),
        .axi_bvalid             (d_bvalid               ),
        .axi_bready             (d_bready               )
    );

endmodule