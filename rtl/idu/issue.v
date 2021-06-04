`timescale 1ns / 1ps

module issue (
    input   wire [63:0] fifo_r_data_1,
    input   wire        fifo_r_data_1_ok,
    input   wire [63:0] fifo_r_data_2,
    input   wire        fifo_r_data_2_ok,

    // pop fifo    
    output  reg          p_data_1,
    output  reg          p_data_2,

    // to iduc
    output  wire        id1_valid_1,
    output  wire [31:0] id1_pc_1,
    output  wire [31:0] id1_inst_1,
    output  wire [5 :0] id1_op_code_1,
    output  wire [4 :0] id1_rs_1,
    output  wire [4 :0] id1_rt_1,
    output  wire [4 :0] id1_rd_1,
    output  wire [4 :0] id1_sa_1,
    output  wire [5 :0] id1_funct_1,
    output  wire        id1_w_reg_dst_1,
    output  wire [15:0] id1_imme_1,
    output  wire [25:0] id1_j_imme_1,
    output  wire        id1_is_branch_1,
    output  wire        id1_is_j_imme_1,
    output  wire        id1_is_jr_1,
    output  wire        id1_is_ls_1,

    // to idup
    output  wire        id1_valid_2,
    output  wire [31:0] id1_pc_2,
    output  wire [31:0] id1_inst_2,
    output  wire [5 :0] id1_op_code_2,
    output  wire [4 :0] id1_rs_2,
    output  wire [4 :0] id1_rt_2,
    output  wire [4 :0] id1_rd_2,
    output  wire [4 :0] id1_sa_2,
    output  wire [5 :0] id1_funct_2,
    output  wire        id1_w_reg_dst_2,
    output  wire [15:0] id1_imme_2,
    output  wire [25:0] id1_j_imme_2,
    output  wire        id1_is_branch_2,
    output  wire        id1_is_j_imme_2,
    output  wire        id1_is_jr_2,
    output  wire        id1_is_ls_2
);

    wire inst_jmp_1, inst_jmp_2;
    assign inst_jmp_1 =
            id1_is_branch_1 | id1_is_j_imme_1 | id1_is_jr_1;
    assign inst_jmp_2 =
            id1_is_branch_2 | id1_is_j_imme_2 | id1_is_jr_2;

    always @(*) begin
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
            end else if (fifo_r_data_2_ok & (id1_w_reg_dst_1 == id1_rs_2 || id1_w_reg_dst_1 == id1_rt_2)) begin
                p_data_1 = 1'b1;
                p_data_2 = 1'b0; 
            end else if (id1_is_ls_1) begin
                p_data_1 = 1'b1;
                p_data_2 = 1'b0;
            end else if (!inst_jmp_1 & inst_jmp_2) begin
                p_data_1 = 1'b1;
                p_data_2 = 1'b0;
            end else begin
                p_data_1 = 1'b1;
                p_data_2 = 1'b1;
            end
        end
    end

    assign id1_valid1_1 = p_data_1;
    assign id1_pc_1     = fifo_r_data_1[63:32];
    assign id1_inst_1   = fifo_r_data_1[31: 0];

    assign id1_valid1_1 = p_data_2;
    assign id1_pc_2     = fifo_r_data_2[63:32];
    assign id1_inst_2   = fifo_r_data_2[31: 0];

    idu_1 idc (
        .inst           (id1_inst_1),
        .id1_op_code    (id1_op_code_1),
        .id1_rs         (id1_rs_1),
        .id1_rt         (id1_rt_1),
        .id1_rd         (id1_rd_1),
        .id1_sa         (id1_sa_1),
        .id1_funct      (id1_funct_1),
        .id1_w_reg_dst  (id1_w_reg_dst_1),
        .id1_imme       (id1_imme_1),
        .id1_j_imme     (id1_j_imme_1),
        .id1_is_branch  (id1_is_branch_1),
        .id1_is_j_imme  (id1_is_j_imme_1),
        .id1_is_jr      (id1_is_jr_1),
        .id1_is_ls      (id_is_ls_1)
    );

    idu_1 idp (
        .inst           (id1_inst_2),
        .id1_op_code    (id1_op_code_2),
        .id1_rs         (id1_rs_2),
        .id1_rt         (id1_rt_2),
        .id1_rd         (id1_rd_2),
        .id1_sa         (id1_sa_2),
        .id1_funct      (id1_funct_2),
        .id1_w_reg_dst  (id1_w_reg_dst_2),
        .id1_imme       (id1_imme_2),
        .id1_j_imme     (id1_j_imme_2),
        .id1_is_branch  (id1_is_branch_2),
        .id1_is_j_imme  (id1_is_j_imme_2),
        .id1_is_jr      (id1_is_jr_2),
        .id1_is_ls      (id1_is_ls_2)
    );

endmodule