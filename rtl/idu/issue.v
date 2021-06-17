`timescale 1ns / 1ps

`include "id_def.v"

module issue (
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,

    input   wire [63:0] fifo_r_data_1,
    input   wire        fifo_r_data_1_ok,
    input   wire [63:0] fifo_r_data_2,
    input   wire        fifo_r_data_2_ok,

    // pop fifo    
    output  reg         p_data_1,
    output  reg         p_data_2,

    // to iduc
    output  wire        id1_valid_1,
    output  wire [28:0] id1_op_codes_1,
    output  wire [28:0] id1_func_codes_1,
    output  wire [31:0] id1_pc_1,
    output  wire [31:0] id1_inst_1,
    output  wire [4 :0] id1_rs_1,
    output  wire [4 :0] id1_rt_1,
    output  wire [4 :0] id1_rd_1,
    output  wire [4 :0] id1_sa_1,
    output  wire        id1_w_reg_ena_1,
    output  wire [4 :0] id1_w_reg_dst_1,
    output  wire [15:0] id1_imme_1,
    output  wire [25:0] id1_j_imme_1,
    output  wire        id1_is_branch_1,
    output  wire        id1_is_j_imme_1,
    output  wire        id1_is_jr_1,
    output  wire        id1_is_ls_1,
    output  wire        id1_in_delay_slot_1,
    output  wire        id1_is_inst_adel_1,

    // to idup
    output  wire        id1_valid_2,
    output  wire [28:0] id1_op_codes_2,
    output  wire [28:0] id1_func_codes_2,
    output  wire [31:0] id1_pc_2,
    output  wire [31:0] id1_inst_2,
    output  wire [4 :0] id1_rs_2,
    output  wire [4 :0] id1_rt_2,
    output  wire [4 :0] id1_rd_2,
    output  wire [4 :0] id1_sa_2,
    output  wire        id1_w_reg_ena_2,
    output  wire [4 :0] id1_w_reg_dst_2,
    output  wire [15:0] id1_imme_2,
    output  wire [25:0] id1_j_imme_2,
    output  wire        id1_is_branch_2,
    output  wire        id1_is_j_imme_2,
    output  wire        id1_is_jr_2,
    output  wire        id1_is_ls_2,
    output  wire        id1_in_delay_slot_2,
    output  wire        id1_is_inst_adel_2
);

    // Test the performance of dual issue
    reg [31:0] c_issue_counter, p_issue_counter;
    always @(posedge clk) begin
        if (rst) begin
            c_issue_counter <= 32'h0;
            p_issue_counter <= 32'h0;
        end else begin
            if (p_data_1) 
                c_issue_counter <= c_issue_counter + 32'h1;
            if (p_data_2) 
                p_issue_counter <= p_issue_counter + 32'h1;
        end
    end

    wire id1_is_hilo_1, id1_is_hilo_2;
    wire inst_jmp_1, inst_jmp_2;
    wire raw_conflict;
    wire id1_is_cop0_1, id1_is_cop0_2;
    assign inst_jmp_1 =
            id1_is_branch_1 | id1_is_j_imme_1 | id1_is_jr_1;
    assign inst_jmp_2 =
            id1_is_branch_2 | id1_is_j_imme_2 | id1_is_jr_2;
            
    assign raw_conflict = 
            (id1_w_reg_ena_1  & ((id1_w_reg_dst_1 == id1_rs_2) & (id1_rs_2 != 5'h0))) |
            (id1_w_reg_ena_1  & ((id1_w_reg_dst_1 == id1_rt_2) & (id1_rt_2 != 5'h0)));

    always @(*) begin
        if (stall) begin
            p_data_1 = 1'b0;
            p_data_2 = 1'b0;
        end else begin
            if (!fifo_r_data_1_ok) begin
                p_data_1 = 1'b0;
                p_data_2 = 1'b0;
            end else begin
                if (inst_jmp_1 & !fifo_r_data_2_ok) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else if (inst_jmp_1 & fifo_r_data_2_ok) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b1;
                end else if (fifo_r_data_2_ok & raw_conflict) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0; 
                end else if (id1_is_cop0_2) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else if (id1_is_cop0_1) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else if (id1_is_ls_1) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else if (!inst_jmp_1 & inst_jmp_2) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else if (id1_is_hilo_1) begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b0;
                end else begin
                    p_data_1 = 1'b1;
                    p_data_2 = 1'b1;
                end
            end
        end
    end

    assign id1_valid_1              = p_data_1;
    assign id1_pc_1                 = fifo_r_data_1[63:32];
    assign id1_inst_1               = fifo_r_data_1[31: 0];
    assign id1_in_delay_slot_1      = 1'b0;
    assign id1_is_inst_adel_1       = id1_pc_1[1:0] != 2'b00;

    assign id1_valid_2              = p_data_2;
    assign id1_pc_2                 = fifo_r_data_2[63:32];
    assign id1_inst_2               = fifo_r_data_2[31: 0];
    assign id1_in_delay_slot_2      = inst_jmp_1;
    assign id1_is_inst_adel_2       = id1_pc_2[1:0] != 2'b00;

    idu_1 idc (
        .inst           (id1_inst_1),
        .id1_op_codes   (id1_op_codes_1),
        .id1_func_codes (id1_func_codes_1),
        .id1_rs         (id1_rs_1),
        .id1_rt         (id1_rt_1),
        .id1_rd         (id1_rd_1),
        .id1_sa         (id1_sa_1),
        .id1_w_reg_ena  (id1_w_reg_ena_1),
        .id1_w_reg_dst  (id1_w_reg_dst_1),
        .id1_imme       (id1_imme_1),
        .id1_j_imme     (id1_j_imme_1),
        .id1_is_branch  (id1_is_branch_1),
        .id1_is_j_imme  (id1_is_j_imme_1),
        .id1_is_jr      (id1_is_jr_1),
        .id1_is_ls      (id1_is_ls_1),
        .id1_is_hilo    (id1_is_hilo_1),
        .id1_is_cop0    (id1_is_cop0_1)
    );

    idu_1 idp (
        .inst           (id1_inst_2),
        .id1_op_codes   (id1_op_codes_2),
        .id1_func_codes (id1_func_codes_2),
        .id1_rs         (id1_rs_2),
        .id1_rt         (id1_rt_2),
        .id1_rd         (id1_rd_2),
        .id1_sa         (id1_sa_2),
        .id1_w_reg_ena  (id1_w_reg_ena_2),
        .id1_w_reg_dst  (id1_w_reg_dst_2),
        .id1_imme       (id1_imme_2),
        .id1_j_imme     (id1_j_imme_2),
        .id1_is_branch  (id1_is_branch_2),
        .id1_is_j_imme  (id1_is_j_imme_2),
        .id1_is_jr      (id1_is_jr_2),
        .id1_is_ls      (id1_is_ls_2),
        .id1_is_hilo    (id1_is_hilo_2),
        .id1_is_cop0    (id1_is_cop0_2)
    );

endmodule