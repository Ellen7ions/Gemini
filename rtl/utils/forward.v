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

    input   wire [1 :0] ex_mem_w_hilo_ena,

    output  reg  [2 :0] forward_rs,
    output  reg  [2 :0] forward_rt,
    output  reg         forward_hi,
    output  reg         forward_lo,

    output  wire        forward_stall_req,  // stall issue id1_id2
    output  wire        forward_flush_req   // flush id2_ex
);

    wire rs_hazard_ex_alu_2;
    wire rs_hazard_ex_alu_1;
    wire rs_hazard_mem_alu_2;
    wire rs_hazard_mem_alu_1;
    wire rs_hazard_mem_ls_1;

    wire rt_hazard_ex_alu_2;
    wire rt_hazard_ex_alu_1;
    wire rt_hazard_mem_alu_2;
    wire rt_hazard_mem_alu_1;
    wire rt_hazard_mem_ls_1;

    assign rs_hazard_ex_alu_2   = 
            (id_rs == ex_w_reg_dst_2) & ex_w_reg_ena_2;
    assign rs_hazard_ex_alu_1   = 
            (id_rs == ex_w_reg_dst_1) & ex_w_reg_ena_1;
    assign rs_hazard_mem_alu_2  =
            (id_rs == mem_w_reg_dst_2) & mem_w_reg_ena_2;
    assign rs_hazard_mem_alu_1  =
            (id_rs == mem_w_reg_dst_1) & mem_w_reg_ena_1;
    assign rs_hazard_mem_ls_1   =
            (id_rs == mem_w_reg_dst_1) & mem_w_reg_dst_1 & mem_ls_ena_1;

    assign rt_hazard_ex_alu_2   = 
            (id_rt == ex_w_reg_dst_2) & ex_w_reg_ena_2;
    assign rt_hazard_ex_alu_1   = 
            (id_rt == ex_w_reg_dst_1) & ex_w_reg_ena_1;
    assign rt_hazard_mem_alu_2  =
            (id_rt == mem_w_reg_dst_2) & mem_w_reg_ena_2;
    assign rt_hazard_mem_alu_1  =
            (id_rt == mem_w_reg_dst_1) & mem_w_reg_ena_1;
    assign rt_hazard_mem_ls_1   =
            (id_rt == mem_w_reg_dst_1) & mem_w_reg_dst_1 & mem_ls_ena_1;

    always @(*) begin
        if (rs_hazard_ex_alu_2) begin
            forward_rs = `FORWARD_EXP_ALU_RES;
        end else if (rs_hazard_ex_alu_1) begin
            forward_rs = `FORWARD_EXC_ALU_RES;
        end else if (rs_hazard_mem_alu_2) begin
            forward_rs = `FORWARD_MEMP_ALU_RES;
        end else if (rs_hazard_mem_alu_1) begin
            forward_rs = `FORWARD_MEMC_ALU_RES;
        end else if (rs_hazard_mem_ls_1) begin
            forward_rs = `FORWARD_MEMC_MEM_DATA;
        end else begin
            forward_rs = `FORWARD_NOP;
        end
    end

    always @(*) begin
        if (rt_hazard_ex_alu_2) begin
            forward_rt = `FORWARD_EXP_ALU_RES;
        end else if (rt_hazard_ex_alu_1) begin
            forward_rt = `FORWARD_EXC_ALU_RES;
        end else if (rt_hazard_mem_alu_2) begin
            forward_rt = `FORWARD_MEMP_ALU_RES;
        end else if (rt_hazard_mem_alu_1) begin
            forward_rt = `FORWARD_MEMC_ALU_RES;
        end else if (rt_hazard_mem_ls_1) begin
            forward_rt = `FORWARD_MEMC_MEM_DATA;
        end else begin
            forward_rt = `FORWARD_NOP;
        end
    end

    always @(*) begin
        forward_hi = ex_mem_w_hilo_ena[1];
    end

    always @(*) begin
        forward_lo = ex_mem_w_hilo_ena[0];
    end
    
    assign forward_stall_req = 
            (ex_ls_ena_1 & ex_w_reg_ena_1 & ((ex_w_reg_dst_1 == id_rs) || (ex_w_reg_dst_1 == id_rt)));
    assign forward_flush_req =
            forward_stall_req;


endmodule