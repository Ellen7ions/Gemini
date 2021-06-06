`timescale 1ns / 1ps

module mem_wb (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        stall,
    input   wire [31:0] mem_alu_res_o,
    input   wire        mem_w_reg_ena_o,
    input   wire [4 :0] mem_w_reg_dst_o,
    input   wire [31:0] mem_r_data_o,
    input   wire        mem_wb_sel_o,
    output  reg  [31:0] mem_alu_res_i,
    output  reg         mem_w_reg_ena_i,
    output  reg  [4 :0] mem_w_reg_dst_i,
    output  reg  [31:0] mem_r_data_i,
    output  reg         mem_wb_sel_i
);

    always @(posedge clk) begin
        if (rst || (flush & !stall)) begin
            mem_alu_res_i   <= 32'h0;
            mem_w_reg_ena_i <= 1'h0;
            mem_w_reg_dst_i <= 5'h0;
            mem_r_data_i    <= 32'h0;
            mem_wb_sel_i    <= 1'h0;
        end else begin
            mem_alu_res_i   <= mem_alu_res_o;
            mem_w_reg_ena_i <= mem_w_reg_ena_o;
            mem_w_reg_dst_i <= mem_w_reg_dst_o;
            mem_r_data_i    <= mem_r_data_o;
            mem_wb_sel_i    <= mem_wb_sel_o;
        end
    end
    
endmodule