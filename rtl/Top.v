`timescale 1ns / 1ps

module Top (
    input   wire    clk,
    input   wire    rst
);

    gemini cpu_core (
        .clk                (clk            ),
        .rst                (rst            ),
        .interupt           (6'b000000      ),
        .inst_ena           (),
        .inst_addr_1        (),
        .inst_addr_2        (),
        .inst_rdata_1       (),
        .inst_rdata_2       (),
        .inst_rdata_1_ok    (1'b0           ),
        .inst_rdata_2_ok    (1'b0           ),

        .i_cache_stall_req  (),
        .data_ena           (),
        .data_wea           (),
        .data_waddr         (),
        .data_wdata         (),
        .data_rdata         (),
        .d_cache_stall_req  (),
        
        .debug_pc           (),
        .debug_w_ena        (),
        .debug_w_addr       (),
        .debug_w_data       ()
    );

endmodule