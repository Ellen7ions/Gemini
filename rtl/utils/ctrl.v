`timescale 1ns / 1ps

module ctrl (
    input   wire    i_cache_stall_req,
    input   wire    d_cache_stall_req,
    input   wire    fifo_stall_req,
    input   wire    forwardc_stall_req,
    input   wire    forwardc_flush_req,
    input   wire    forwardp_stall_req,
    input   wire    forwardp_flush_req,
    input   wire    id2c_flush_req,
    input   wire    exc_stall_req,
    
    output  wire    pc_stall,
    output  wire    pc_flush,
    output  wire    fifo_flush,
    output  wire    issue_stall,
    output  wire    ii_id2_flush,
    output  wire    ii_id2_stall,
    output  wire    id2_ex_flush,
    output  wire    id2_ex_stall,
    output  wire    ex_mem_flush,
    output  wire    ex_mem_stall,
    output  wire    mem_wb_flush,
    output  wire    mem_wb_stall,
    output  wire    wb_stall
);

    assign pc_stall     =
            i_cache_stall_req | fifo_stall_req | exc_stall_req | forwardc_stall_req | forwardp_stall_req;
    
    assign pc_flush     = 
            1'b0;
    
    assign fifo_flush   =
            id2c_flush_req & (~forwardc_stall_req & ~forwardp_stall_req);
    
    assign issue_stall  =
            d_cache_stall_req | forwardc_stall_req | forwardp_stall_req | exc_stall_req;
    
    assign ii_id2_flush =
            id2c_flush_req;
    
    assign ii_id2_stall =
            issue_stall | (pc_stall & fifo_flush) | forwardc_stall_req | forwardp_stall_req;
    
    assign id2_ex_flush =
            forwardc_flush_req | forwardp_flush_req;

    assign id2_ex_stall =
            d_cache_stall_req | exc_stall_req;
    
    assign ex_mem_flush =
            1'b0;

    assign ex_mem_stall =
            d_cache_stall_req | exc_stall_req;
    
    assign mem_wb_flush =
            1'b0;
    
    assign mem_wb_stall =
            d_cache_stall_req | exc_stall_req;

    assign wb_stall     =
            d_cache_stall_req | exc_stall_req;
endmodule