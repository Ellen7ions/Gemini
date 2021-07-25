`timescale 1ns / 1ps

module forward_req (
    input   wire        rs_ena,
    input   wire [4 :0] id_rs,
    input   wire        rt_ena,
    input   wire [4 :0] id_rt,
    input   wire        ex_ls_ena,
    input   wire        ex_w_reg_ena,
    input   wire [4 :0] ex_w_reg_dst,
    input   wire        lsu1_ls_ena,
    input   wire        lsu1_w_reg_ena,
    input   wire [4 :0] lsu1_w_reg_dst,
    output  wire        forward_req_o
);

    assign forward_req_o    =
        (ex_ls_ena      & ex_w_reg_ena      & (rs_ena & (id_rs != 5'h0) & (ex_w_reg_dst     == id_rs) | rt_ena & (id_rt != 5'h0) & (ex_w_reg_dst    == id_rt))) |
        (lsu1_ls_ena    & lsu1_w_reg_ena    & (rs_ena & (id_rs != 5'h0) & (lsu1_w_reg_dst   == id_rs) | rt_ena & (id_rt != 5'h0) & (lsu1_w_reg_dst  == id_rt))) ;

endmodule