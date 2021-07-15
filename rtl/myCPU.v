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

endmodule