`timescale 1ns / 1ps

module ctrl (
    input   wire    i_cache_stall_req,
    input   wire    d_cache_stall_req,
    input   wire    fifo_stall_req,
    input   wire    forwardc_req,
    input   wire    forwardp_req,
    input   wire    b_ctrl_flush_req,
    input   wire    flush_delay_slot,
    // the delaysolt issue with the branch inst in c datapath.
    input   wire    with_delaysolt,
    input   wire    exc_stall_req,
    input   wire    exc_cp0_stall,
    input   wire    exception_flush,
    input   wire    lsu1_tlb_stall_req,
    input   wire    mem_refetch,
    
    output  wire    ex_lsu1_flush,
    output  wire    ex_lsu1_exp_flush,
    output  wire    ex_lsu1_stall,
    output  wire    lsu1_lsu2_flush,
    output  wire    lsu1_lsu2_exp_flush,
    output  wire    lsu1_lsu2_stall,
    output  wire    pc_stall,
    output  wire    fifo_flush,
    output  wire    issue_stall,
    output  wire    ii_id2_flush,
    output  wire    ii_id2_exception_flush,
    output  wire    ii_id2_stall,
    output  wire    id2_ex_flush,
    output  wire    id2_ex_exception_flush,
    output  wire    id2_ex_stall,
    output  wire    mem_wb_flush,
    output  wire    mem_wb_exception_flush,
    output  wire    mem_wb_stall,
    output  wire    wb_stall
);
    assign ii_id2_exception_flush = (exception_flush | mem_refetch);
    assign id2_ex_exception_flush = (exception_flush | mem_refetch);
    assign mem_wb_exception_flush = 1'b0;

    assign pc_stall     =
            fifo_stall_req;
    
    assign fifo_flush   =
            b_ctrl_flush_req | ((exception_flush | mem_refetch));
    
    assign issue_stall  =
            i_cache_stall_req | d_cache_stall_req | (forwardc_req | forwardp_req) & (~b_ctrl_flush_req | b_ctrl_flush_req & ~with_delaysolt) | exc_stall_req | exc_cp0_stall | lsu1_tlb_stall_req;
    
    assign ii_id2_flush =
            b_ctrl_flush_req;
    
    assign ii_id2_stall =
            i_cache_stall_req | d_cache_stall_req | (pc_stall & fifo_flush) | (forwardc_req | forwardp_req) & (~b_ctrl_flush_req | b_ctrl_flush_req & ~with_delaysolt) | exc_stall_req | exc_cp0_stall | lsu1_tlb_stall_req;
    
    assign id2_ex_flush =
            b_ctrl_flush_req & with_delaysolt | flush_delay_slot | (forwardc_req | forwardp_req) & (~b_ctrl_flush_req | b_ctrl_flush_req & ~with_delaysolt);

    assign id2_ex_stall =
            i_cache_stall_req | d_cache_stall_req | exc_stall_req | exc_cp0_stall | lsu1_tlb_stall_req;

    
    assign ex_lsu1_flush       =
        lsu1_tlb_stall_req | exc_cp0_stall;
    assign ex_lsu1_exp_flush   =
        (exception_flush | mem_refetch);
    assign ex_lsu1_stall   =
        i_cache_stall_req | exc_stall_req | d_cache_stall_req;
    
    assign lsu1_lsu2_flush     =
        1'b0;
    assign lsu1_lsu2_exp_flush =
        (exception_flush | mem_refetch);
    assign lsu1_lsu2_stall =
        i_cache_stall_req | exc_stall_req | d_cache_stall_req;

    assign mem_wb_flush = 
            // 1'b0;
        i_cache_stall_req | d_cache_stall_req | ((exc_stall_req) & ~exception_flush & ~mem_refetch);
    
    assign mem_wb_stall = 1'b0;
        //     i_cache_stall_req | d_cache_stall_req | ((exc_stall_req) & ~exception_flush & ~mem_refetch);

    assign wb_stall     = 1'b0;
        //     i_cache_stall_req | d_cache_stall_req | ((exc_stall_req) & ~exception_flush & ~mem_refetch);
endmodule