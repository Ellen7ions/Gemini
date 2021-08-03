`timescale 1ns / 1ps

module mycpu_top (
    input   wire        aclk,
    input   wire        aresetn,
    input   wire [5:0]  ext_int,

    output  wire [3 :0] awid,
    output  wire [31:0] awaddr,
    output  wire [3 :0] awlen,
    output  wire [2 :0] awsize,
    output  wire [1 :0] awburst,
    output  wire [1 :0] awlock,
    output  wire [3 :0] awcache,
    output  wire [2 :0] awprot,
    output  wire        awvalid,
    input   wire        awready,

    output  wire [3 :0] wid,
    output  wire [31:0] wdata,
    output  wire [3 :0] wstrb,
    output  wire        wlast,
    output  wire        wvalid,
    input   wire        wready,

    output  wire [3 :0] arid,
    output  wire [31:0] araddr,
    output  wire [3 :0] arlen,
    output  wire [2 :0] arsize,
    output  wire [1 :0] arburst,
    output  wire [1 :0] arlock,
    output  wire [3 :0] arcache,
    output  wire [2 :0] arprot,
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
    output  wire [31:0] debug_wb_rf_wdata_2,
    
    output  wire [31:0] debug_wb_pc,
    output  wire [3 :0] debug_wb_rf_wen,
    output  wire [4 :0] debug_wb_rf_wnum,
    output  wire [31:0] debug_wb_rf_wdata
);

    wire [31:0] i_araddr;
    wire [1 :0] i_arburst;
    wire [7 :0] i_arlen;
    wire        i_arvalid;
    wire        i_arready;
    wire [31:0] i_rdata;
    wire        i_rlast;
    wire        i_rvalid;
    wire        i_rready;

    wire [31:0] d_awaddr;
    wire [7 :0] d_awlen;
    wire [1 :0] d_awburst;
    wire [2 :0] d_awsize;
    wire        d_awvalid;
    wire        d_awready;
    wire [31:0] d_wdata;
    wire [3 :0] d_wstrb;
    wire        d_wlast;
    wire        d_wvalid;
    wire        d_wready;
    wire [31:0] d_araddr;
    wire [7 :0] d_arlen;
    wire [1 :0] d_arburst;
    wire [2 :0] d_arsize;
    wire        d_arvalid;
    wire        d_arready;
    wire [31:0] d_rdata;
    wire        d_rlast;
    wire        d_rvalid;
    wire        d_rready;
    wire        d_bvalid;
    wire        d_bready;

    wire        sram_inst_ena;
    wire        sram_inst_uncached;
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
        .clk                    (aclk                   ),
        .rst                    (~aresetn               ),
        .interrupt              (ext_int                ),
        
        .sram_inst_ena          (sram_inst_ena          ),
        .sram_inst_uncached     (sram_inst_uncached     ),
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
        .clk                    (aclk                   ),
        .rst                    (~aresetn               ),
        .cpu_en                 (sram_inst_ena          ),
        .cpu_uncached           (sram_inst_uncached     ),
        .cpu_vaddr              (sram_inst_vaddr        ),
        .cpu_psyaddr            (sram_inst_psyaddr      ),
        .cpu_rdata1             (sram_inst_rdata_1      ),
        .cpu_rdata2             (sram_inst_rdata_2      ),
        .cpu_ok_1               (sram_inst_ok_1         ),
        .cpu_ok_2               (sram_inst_ok_2         ),
        .cpu_i_cache_stall      (i_cache_stall_req      ),

        .axi_araddr             (i_araddr               ),
        .axi_arburst            (i_arburst              ),
        .axi_arlen              (i_arlen                ),
        .axi_arvalid            (i_arvalid              ),
        .axi_arready            (i_arready              ),
        .axi_rdata              (i_rdata                ),
        .axi_rlast              (i_rlast                ),
        .axi_rvalid             (i_rvalid               ),
        .axi_rready             (i_rready               )
    );

    d_cache d_cache0 (
        .clk                    (aclk                   ),
        .rst                    (~aresetn               ),
        
        .cpu_en                 (sram_data_ena          ),
        .cpu_wen                (sram_data_wen          ),
        .cpu_uncached           (sram_uncached          ),
        .cpu_load_type          (sram_load_type         ),
        .cpu_vaddr              (sram_data_vaddr        ),
        .cpu_psyaddr            (sram_data_psyaddr      ),
        .cpu_wdata              (sram_data_wdata        ),
        .cpu_rdata              (sram_data_rdata        ),
        .cpu_d_cache_stall      (d_cache_stall_req      ),
        
        .axi_awaddr             (d_awaddr               ),
        .axi_awlen              (d_awlen                ),
        .axi_awburst            (d_awburst              ),
        .axi_awsize             (d_awsize               ),
        .axi_awvalid            (d_awvalid              ),
        .axi_awready            (d_awready              ),
        .axi_wdata              (d_wdata                ),
        .axi_wstrb              (d_wstrb                ),
        .axi_wlast              (d_wlast                ),
        .axi_wvalid             (d_wvalid               ),
        .axi_wready             (d_wready               ),
        .axi_araddr             (d_araddr               ),
        .axi_arlen              (d_arlen                ),
        .axi_arburst            (d_arburst              ),
        .axi_arsize             (d_arsize               ),
        .axi_arvalid            (d_arvalid              ),
        .axi_arready            (d_arready              ),
        .axi_rdata              (d_rdata                ),
        .axi_rlast              (d_rlast                ),
        .axi_rvalid             (d_rvalid               ),
        .axi_rready             (d_rready               ),
        .axi_bvalid             (d_bvalid               ),
        .axi_bready             (d_bready               )
    );

    arbiter arbiter0 (
        .i_araddr               (i_araddr               ),
        .i_arburst              (i_arburst              ),
        .i_arlen                (i_arlen                ),
        .i_arvalid              (i_arvalid              ),
        .i_arready              (i_arready              ),
        .i_rdata                (i_rdata                ),
        .i_rlast                (i_rlast                ),
        .i_rvalid               (i_rvalid               ),
        .i_rready               (i_rready               ),

        .d_araddr               (d_araddr               ),
        .d_arlen                (d_arlen                ),
        .d_arburst              (d_arburst              ),
        .d_arsize               (d_arsize               ),
        .d_arvalid              (d_arvalid              ),
        .d_arready              (d_arready              ),
        .d_rdata                (d_rdata                ),
        .d_rlast                (d_rlast                ),
        .d_rvalid               (d_rvalid               ),
        .d_rready               (d_rready               ),
        .d_awaddr               (d_awaddr               ),
        .d_awlen                (d_awlen                ),
        .d_awburst              (d_awburst              ),
        .d_awsize               (d_awsize               ),
        .d_awvalid              (d_awvalid              ),
        .d_awready              (d_awready              ),
        .d_wdata                (d_wdata                ),
        .d_wstrb                (d_wstrb                ),
        .d_wlast                (d_wlast                ),
        .d_wvalid               (d_wvalid               ),
        .d_wready               (d_wready               ),
        .d_bvalid               (d_bvalid               ),
        .d_bready               (d_bready               ),

        .arid                   (arid                   ),
        .araddr                 (araddr                 ),
        .arlen                  (arlen                  ),
        .arsize                 (arsize                 ),
        .arburst                (arburst                ),
        .arlock                 (arlock                 ),
        .arcache                (arcache                ),
        .arprot                 (arprot                 ),
        .arvalid                (arvalid                ),
        .arready                (arready                ),
        .rid                    (rid                    ),
        .rdata                  (rdata                  ),
        .rresp                  (rresp                  ),
        .rlast                  (rlast                  ),
        .rvalid                 (rvalid                 ),
        .rready                 (rready                 ),
        .awid                   (awid                   ),
        .awaddr                 (awaddr                 ),
        .awlen                  (awlen                  ),
        .awsize                 (awsize                 ),
        .awburst                (awburst                ),
        .awlock                 (awlock                 ),
        .awcache                (awcache                ),
        .awprot                 (awprot                 ),
        .awvalid                (awvalid                ),
        .awready                (awready                ),
        .wid                    (wid                    ),
        .wdata                  (wdata                  ),
        .wstrb                  (wstrb                  ),
        .wlast                  (wlast                  ),
        .wvalid                 (wvalid                 ),
        .wready                 (wready                 ),
        .bid                    (bid                    ),
        .bresp                  (bresp                  ),
        .bvalid                 (bvalid                 ),
        .bready                 (bready                 )
    );

endmodule