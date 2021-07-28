`timescale 1ns / 1ps

`include "id_def.v"

module issue (
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,

    input   wire [98:0] fifo_r_data_1,
    input   wire        fifo_r_data_1_ok,
    input   wire [98:0] fifo_r_data_2,
    input   wire        fifo_r_data_2_ok,

    // pop fifo    
    output  reg         p_data_1,
    output  reg         p_data_2,

    // from mem
    input   wire        cls_refetch,

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
    output  wire        id1_pred_taken_1,
    output  wire [31:0] id1_pred_target_1,
    output  wire        id1_is_branch_1,
    output  wire        id1_is_j_imme_1,
    output  wire        id1_is_jr_1,
    output  wire        id1_is_ls_1,
    output  wire        id1_is_tlbp_1,
    output  wire        id1_is_tlbr_1,
    output  wire        id1_is_tlbwi_1,
    output  wire        id1_in_delay_slot_1,
    output  wire        id1_is_check_ov_1,
    output  wire        id1_is_inst_adel_1,
    output  wire        id1_is_i_refill_tlbl_1,
    output  wire        id1_is_i_invalid_tlbl_1,
    output  wire        id1_is_refetch_1,

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
    output  wire        id1_is_tlbp_2,
    output  wire        id1_is_tlbr_2,
    output  wire        id1_is_tlbwi_2,
    output  wire        id1_in_delay_slot_2,
    output  wire        id1_is_check_ov_2,
    output  wire        id1_is_inst_adel_2,
    output  wire        id1_is_i_refill_tlbl_2,
    output  wire        id1_is_i_invalid_tlbl_2,
    output  wire        id1_is_refetch_2
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

    reg refetch;
    wire update_refetch;
    always @(posedge clk) begin
        if (rst) begin
            refetch <= 1'b0;
        end else begin
            refetch <= update_refetch;
        end
    end

    assign update_refetch = 
        refetch ? ~cls_refetch : id1_valid_1 & (id1_is_tlbr_1 | id1_is_tlbwi_1) | id1_valid_2 & (id1_is_tlbr_2 | id1_is_tlbwi_2);

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

    reg in_ds;
    wire update_in_ds;
    always @(posedge clk) begin
        if (rst) begin
            in_ds <= 1'b0;
        end else begin
            in_ds <= update_in_ds;
        end
    end

    assign update_in_ds = in_ds & stall | ~in_ds & p_data_1 & inst_jmp_1 & ~p_data_2;

    always @(*) begin
        if (stall) begin
            p_data_1 = 1'b0;
            p_data_2 = 1'b0;
        end else begin
            if (!fifo_r_data_1_ok | !fifo_r_data_2_ok) begin
                p_data_1 = 1'b0;
                p_data_2 = 1'b0;
            end else begin
                p_data_1 = 1'b1;
                p_data_2 = 
                    ~(
                        in_ds               |
                        raw_conflict        |
                        inst_jmp_2          |
                        id1_is_hilo_2       |
                        id1_is_cop0_2       |
                        id1_is_ls_2         |
                        id1_is_ri_2         |
                        id1_is_check_ov_2   |
                        id1_is_inst_adel_2  |
                        id1_is_tlbwi_1      |
                        id1_is_tlbp_1       |
                        id1_is_tlbr_1       |
                        id1_is_i_refill_tlbl_2  |
                        id1_is_i_invalid_tlbl_2
                    );
                // if () begin
                //     p_data_2 = 1'b0;
                // end else if (id1_is_hilo_1 | id1_is_hilo_2) begin
                //     p_data_2 = ~id1_is_hilo_2;
                // end else if (id1_is_cop0_1 | id1_is_cop0_2) begin
                //     p_data_2 = ~id1_is_cop0_2;
                // end else if (id1_is_ls_1 | id1_is_ls_2) begin
                //     p_data_2 = ~id1_is_ls_2;
                // end else begin
                //     p_data_2 = 1'b1;
                // end
            end
        end
    end

    assign id1_valid_1              = p_data_1;
    assign id1_pc_1                 = fifo_r_data_1[63:32];
    assign id1_inst_1               = fifo_r_data_1[31: 0];
    assign id1_pred_taken_1         = fifo_r_data_1[98];
    assign id1_pred_target_1        = fifo_r_data_1[97:66];
    assign id1_in_delay_slot_1      = in_ds;
    assign id1_is_inst_adel_1       = id1_pc_1[1:0] != 2'b00;
    assign id1_is_i_refill_tlbl_1   = fifo_r_data_1[65];
    assign id1_is_i_invalid_tlbl_1  = fifo_r_data_1[64];
    assign id1_is_refetch_1         = refetch;

    assign id1_valid_2              = p_data_2;
    assign id1_pc_2                 = fifo_r_data_2[63:32];
    assign id1_inst_2               = fifo_r_data_2[31: 0];
    assign id1_in_delay_slot_2      = inst_jmp_1 & p_data_2;
    assign id1_is_inst_adel_2       = id1_pc_2[1:0] != 2'b00;
    assign id1_is_i_refill_tlbl_2   = fifo_r_data_2[65];
    assign id1_is_i_invalid_tlbl_2  = fifo_r_data_2[64];
    assign id1_is_refetch_2         = refetch;

    idu_1 idc (
        .inst           (id1_inst_1         ),
        .id1_op_codes   (id1_op_codes_1     ),
        .id1_func_codes (id1_func_codes_1   ),
        .id1_rs         (id1_rs_1           ),
        .id1_rt         (id1_rt_1           ),
        .id1_rd         (id1_rd_1           ),
        .id1_sa         (id1_sa_1           ),
        .id1_w_reg_ena  (id1_w_reg_ena_1    ),
        .id1_w_reg_dst  (id1_w_reg_dst_1    ),
        .id1_imme       (id1_imme_1         ),
        .id1_j_imme     (id1_j_imme_1       ),
        .id1_is_branch  (id1_is_branch_1    ),
        .id1_is_j_imme  (id1_is_j_imme_1    ),
        .id1_is_jr      (id1_is_jr_1        ),
        .id1_is_ls      (id1_is_ls_1        ),
        .id1_is_hilo    (id1_is_hilo_1      ),
        .id1_is_cop0    (id1_is_cop0_1      ),
        .id1_is_tlbp    (id1_is_tlbp_1      ),
        .id1_is_tlbr    (id1_is_tlbr_1      ),
        .id1_is_tlbwi   (id1_is_tlbwi_1     ),
        .id1_is_check_ov(id1_is_check_ov_1  ),
        .id1_is_ri      (id1_is_ri_1        )
    );

    idu_1 idp (
        .inst           (id1_inst_2         ),
        .id1_op_codes   (id1_op_codes_2     ),
        .id1_func_codes (id1_func_codes_2   ),
        .id1_rs         (id1_rs_2           ),
        .id1_rt         (id1_rt_2           ),
        .id1_rd         (id1_rd_2           ),
        .id1_sa         (id1_sa_2           ),
        .id1_w_reg_ena  (id1_w_reg_ena_2    ),
        .id1_w_reg_dst  (id1_w_reg_dst_2    ),
        .id1_imme       (id1_imme_2         ),
        .id1_j_imme     (id1_j_imme_2       ),
        .id1_is_branch  (id1_is_branch_2    ),
        .id1_is_j_imme  (id1_is_j_imme_2    ),
        .id1_is_jr      (id1_is_jr_2        ),
        .id1_is_ls      (id1_is_ls_2        ),
        .id1_is_hilo    (id1_is_hilo_2      ),
        .id1_is_cop0    (id1_is_cop0_2      ),
        .id1_is_tlbp    (id1_is_tlbp_2      ),
        .id1_is_tlbr    (id1_is_tlbr_2      ),
        .id1_is_tlbwi   (id1_is_tlbwi_2     ),
        .id1_is_check_ov(id1_is_check_ov_2  ),
        .id1_is_ri      (id1_is_ri_2        )
    );

endmodule