`timescale 1ns / 1ps

module forward (
    input   wire [4 :0] id_rs,
    input   wire [4 :0] id_rt,
    // ex
    input   wire        ex_w_reg_ena_1,
    input   wire [4 :0] ex_w_reg_dst_1,
    input   wire [4 :0] ex_alu_res_1,
    input   wire        ex_ls_ena_1,

    input   wire        ex_w_reg_ena_2,
    input   wire [4 :0] ex_w_reg_dst_2,
    input   wire [4 :0] ex_alu_res_2,
    input   wire        ex_ls_ena_2,
    // ls
    input   wire        mem_w_reg_ena_1,
    input   wire [4 :0] mem_w_reg_dst_1,
    input   wire [4 :0] mem_alu_res_1,
    input   wire        mem_ls_ena_1,

    input   wire        mem_w_reg_ena_2,
    input   wire [4 :0] mem_w_reg_dst_2,
    input   wire [4 :0] mem_alu_res_2,
    input   wire        mem_ls_ena_2,

    output  wire [2 :0] forward_rs,
    output  wire [2 :0] forward_rt,

    output  wire        forward_stall_req,  // stall issue id1_id2
    output  wire        forward_flush_req   // flush id2_ex
);

    assign forward_rs = 
            ( ex_w_reg_ena_2 &                                                          (ex_w_reg_dst_2  == id_rs)) ? 3'b001 :
            (!ex_w_reg_ena_2 &  ex_w_reg_ena_1 &                                        (ex_w_reg_dst_1  == id_rs)) ? 3'b010 :
            (!ex_w_reg_ena_2 & !ex_w_reg_ena_1 &  mem_w_reg_ena_2 &                     (mem_w_reg_dst_2 == id_rs)) ? 3'b011 :
            (!ex_w_reg_ena_2 & !ex_w_reg_ena_1 & !mem_w_reg_ena_2 & mem_w_reg_ena_1 &   (mem_w_reg_dst_1 == id_rs)) ? 3'b100 :
            3'b000;
    
    assign forward_rt = 
            ( ex_w_reg_ena_2 &                                                          (ex_w_reg_dst_2  == id_rt)) ? 3'b001 :
            (!ex_w_reg_ena_2 &  ex_w_reg_ena_1 &                                        (ex_w_reg_dst_1  == id_rt)) ? 3'b010 :
            (!ex_w_reg_ena_2 & !ex_w_reg_ena_1 &  mem_w_reg_ena_2 &                     (mem_w_reg_dst_2 == id_rt)) ? 3'b011 :
            (!ex_w_reg_ena_2 & !ex_w_reg_ena_1 & !mem_w_reg_ena_2 & mem_w_reg_ena_1 &   (mem_w_reg_dst_1 == id_rt)) ? 3'b100 :
            3'b000;
    
    assign forward_stall_req = 
            (ex_ls_ena_1 & ex_w_reg_ena_1 & ((ex_w_reg_dst_1 == id_rs) || (ex_w_reg_dst_1 == id_rt)));
    assign forward_flush_req =
            forward_stall_req;


endmodule