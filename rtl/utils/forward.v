`timescale 1ns / 1ps

`include "forward_def.v"

module forward (
    input   wire [4 :0] id_rs,
    input   wire [4 :0] id_rt,
    // ex
    input   wire        ex_w_reg_ena_1,
    input   wire [4 :0] ex_w_reg_dst_1,
    input   wire        ex_ls_ena_1,

    input   wire        ex_w_reg_ena_2,
    input   wire [4 :0] ex_w_reg_dst_2,
    input   wire        ex_ls_ena_2,
    // ls
    input   wire        mem_w_reg_ena_1,
    input   wire [4 :0] mem_w_reg_dst_1,
    input   wire        mem_ls_ena_1,

    input   wire        mem_w_reg_ena_2,
    input   wire [4 :0] mem_w_reg_dst_2,
    input   wire        mem_ls_ena_2,

    output  reg  [2 :0] forward_rs,
    output  reg  [2 :0] forward_rt,

    output  wire        forward_stall_req,  // stall issue id1_id2
    output  wire        forward_flush_req   // flush id2_ex
);

    always @(*) begin
        if (id_rs != 5'h0) begin
            if          ( ex_w_reg_ena_2 & !ex_ls_ena_2     & (ex_w_reg_dst_2 == id_rs)) begin
                forward_rs = `FORWARD_EXP_ALU_RES;
            end else if ( ex_w_reg_ena_1 & !ex_ls_ena_1     & (ex_w_reg_dst_1 == id_rs)) begin
                forward_rs = `FORWARD_EXC_ALU_RES;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_2 & !mem_ls_ena_2 & (mem_w_reg_dst_2 == id_rs)) begin
                forward_rs = `FORWARD_MEMP_ALU_RES;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_1 &  mem_ls_ena_1 & (mem_w_reg_dst_1 == id_rs)) begin
                forward_rs = `FORWARD_MEMC_MEM_DATA;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_1 & !mem_ls_ena_1 & (mem_w_reg_dst_1 == id_rs)) begin
                forward_rs = `FORWARD_MEMC_ALU_RES;
            end else begin
                forward_rs = `FORWARD_NOP;
            end
        end else begin
            forward_rs = `FORWARD_NOP;
        end
    end
    
    always @(*) begin
        if (id_rt != 5'h0) begin
            if          ( ex_w_reg_ena_2 & !ex_ls_ena_2     & (ex_w_reg_dst_2 == id_rt)) begin
                forward_rt = `FORWARD_EXP_ALU_RES;
            end else if ( ex_w_reg_ena_1 & !ex_ls_ena_1     & (ex_w_reg_dst_1 == id_rt)) begin
                forward_rt = `FORWARD_EXC_ALU_RES;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_2 & !mem_ls_ena_2 & (mem_w_reg_dst_2 == id_rt)) begin
                forward_rt = `FORWARD_MEMP_ALU_RES;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_1 &  mem_ls_ena_1 & (mem_w_reg_dst_1 == id_rt)) begin
                forward_rt = `FORWARD_MEMC_MEM_DATA;
            end else if (!ex_w_reg_ena_1 & !ex_w_reg_ena_2  &  mem_w_reg_ena_1 & !mem_ls_ena_1 & (mem_w_reg_dst_1 == id_rt)) begin
                forward_rt = `FORWARD_MEMC_ALU_RES;
            end else begin
                forward_rt = `FORWARD_NOP;
            end
        end else begin
            forward_rt = `FORWARD_NOP;
        end
    end
    
    assign forward_stall_req = 
            (ex_ls_ena_1 & ex_w_reg_ena_1 & ((ex_w_reg_dst_1 == id_rs) || (ex_w_reg_dst_1 == id_rt)));
    assign forward_flush_req =
            forward_stall_req;


endmodule