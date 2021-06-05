`timescale 1ns / 1ps

module gemini (
    input   wire        clk,
    input   wire        rst,
    input   wire [5 :0] interupt,
    
    output  wire        inst_ena,
    output  wire [31:0] inst_addr_1,
    output  wire [31:0] inst_addr_2,
    input   wire [31:0] inst_rdata_1,
    input   wire [31:0] inst_rdata_2,
    input   wire        inst_rdata_1_ok,
    input   wire        inst_rdata_2_ok,
    input   wire        i_cache_stall_req,

    output  wire        data_ena,
    output  wire [3 :0] data_wea,
    output  wire [31:0] data_waddr,
    output  wire [31:0] data_wdata,
    output  wire [31:0] data_rdata,
    input   wire        d_cache_stall_req,

    output  wire [31:0] debug_pc,
    output  wire        debug_w_ena,
    output  wire [31:0] debug_w_addr,
    output  wire [31:0] debug_w_data
);

    // pipeline regs
    // ii => id2
    reg         ii_id2_flush, ii_id2_stall;

    wire        id1c_valid_o;
    wire [31:0] id1c_pc_o;
    wire [31:0] id1c_inst_o;
    wire [5 :0] id1c_op_code_o;
    wire [4 :0] id1c_rs_o;
    wire [4 :0] id1c_rt_o;
    wire [4 :0] id1c_rd_o;
    wire [4 :0] id1c_sa_o;
    wire [5 :0] id1c_funct_o;
    wire        id1c_w_reg_ena_o;
    wire [4 :0] id1c_w_reg_dst_o;
    wire [15:0] id1c_imme_o;
    wire [25:0] id1c_j_imme_o;
    wire        id1c_is_branch_o;
    wire        id1c_is_j_imme_o;
    wire        id1c_is_jr_o;
    wire        id1c_is_ls_o;

    wire        id1c_valid_i;
    wire [31:0] id1c_pc_i;
    wire [31:0] id1c_inst_i;
    wire [5 :0] id1c_op_code_i;
    wire [4 :0] id1c_rs_i;
    wire [4 :0] id1c_rt_i;
    wire [4 :0] id1c_rd_i;
    wire [4 :0] id1c_sa_i;
    wire [5 :0] id1c_funct_i;
    wire        id1c_w_reg_ena_i;
    wire [4 :0] id1c_w_reg_dst_i;
    wire [15:0] id1c_imme_i;
    wire [25:0] id1c_j_imme_i;
    wire        id1c_is_branch_i;
    wire        id1c_is_j_imme_i;
    wire        id1c_is_jr_i;
    wire        id1c_is_ls_i;

    wire        id1p_valid_o;
    wire [31:0] id1p_pc_o;
    wire [31:0] id1p_inst_o;
    wire [5 :0] id1p_op_code_o;
    wire [4 :0] id1p_rs_o;
    wire [4 :0] id1p_rt_o;
    wire [4 :0] id1p_rd_o;
    wire [4 :0] id1p_sa_o;
    wire [5 :0] id1p_funct_o;
    wire        id1p_w_reg_ena_o;
    wire [4 :0] id1p_w_reg_dst_o;
    wire [15:0] id1p_imme_o;
    wire [25:0] id1p_j_imme_o;
    wire        id1p_is_branch_o;
    wire        id1p_is_j_imme_o;
    wire        id1p_is_jr_o;
    wire        id1p_is_ls_o;

    wire        id1p_valid_i;
    wire [31:0] id1p_pc_i;
    wire [31:0] id1p_inst_i;
    wire [5 :0] id1p_op_code_i;
    wire [4 :0] id1p_rs_i;
    wire [4 :0] id1p_rt_i;
    wire [4 :0] id1p_rd_i;
    wire [4 :0] id1p_sa_i;
    wire [5 :0] id1p_funct_i;
    wire        id1p_w_reg_ena_i;
    wire [4 :0] id1p_w_reg_dst_i;
    wire [15:0] id1p_imme_i;
    wire [25:0] id1p_j_imme_i;
    wire        id1p_is_branch_i;
    wire        id1p_is_j_imme_i;
    wire        id1p_is_jr_i;
    wire        id1p_is_ls_i;

    issue_id2 issue_id2c (
        .clk                (clk    ),
        .rst                (rst    ),
        .flush              (),
        .stall              (),

        .id1_valid_o        (id1c_valid_o       ),

        .id1_pc_o           (id1c_pc_o          ),
        .id1_inst_o         (id1c_inst_o        ),
        .id1_op_code_o      (id1c_op_code_o     ),
        .id1_rs_o           (id1c_rs_o          ),
        .id1_rt_o           (id1c_rt_o          ),
        .id1_rd_o           (id1c_rd_o          ),
        .id1_sa_o           (id1c_sa_o          ),
        .id1_funct_o        (id1c_funct_o       ),
        .id1_w_reg_ena_o    (id1c_w_reg_ena_o   ),
        .id1_w_reg_dst_o    (id1c_w_reg_dst_o   ),
        .id1_imme_o         (id1c_imme_o        ),
        .id1_j_imme_o       (id1c_j_imme_o      ),
        .id1_is_branch_o    (id1c_is_branch_o   ),
        .id1_is_j_imme_o    (id1c_is_j_imme_o   ),
        .id1_is_jr_o        (id1c_is_jr_o       ),
        .id1_is_ls_o        (id1c_is_ls_o       ),

        .id1_pc_i           (id1c_pc_i          ),
        .id1_inst_i         (id1c_inst_i        ),
        .id1_op_code_i      (id1c_op_code_i     ),
        .id1_rs_i           (id1c_rs_i          ),
        .id1_rt_i           (id1c_rt_i          ),
        .id1_rd_i           (id1c_rd_i          ),
        .id1_sa_i           (id1c_sa_i          ),
        .id1_funct_i        (id1c_funct_i       ),
        .id1_w_reg_ena_i    (id1c_w_reg_ena_i   ),
        .id1_w_reg_dst_i    (id1c_w_reg_dst_i   ),
        .id1_imme_i         (id1c_imme_i        ),
        .id1_j_imme_i       (id1c_j_imme_i      ),
        .id1_is_branch_i    (id1c_is_branch_i   ),
        .id1_is_j_imme_i    (id1c_is_j_imme_i   ),
        .id1_is_jr_i        (id1c_is_jr_i       ),
        .id1_is_ls_i        (id1c_is_ls_i       )
    );

    issue_id2 issue_id2p (
        .clk                (clk    ),
        .rst                (rst    ),
        .flush              (),
        .stall              (),

        .id1_valid_o        (id1p_valid_o       ),

        .id1_pc_o           (id1p_pc_o          ),
        .id1_inst_o         (id1p_inst_o        ),
        .id1_op_code_o      (id1p_op_code_o     ),
        .id1_rs_o           (id1p_rs_o          ),
        .id1_rt_o           (id1p_rt_o          ),
        .id1_rd_o           (id1p_rd_o          ),
        .id1_sa_o           (id1p_sa_o          ),
        .id1_funct_o        (id1p_funct_o       ),
        .id1_w_reg_ena_o    (id1p_w_reg_ena_o   ),
        .id1_w_reg_dst_o    (id1p_w_reg_dst_o   ),
        .id1_imme_o         (id1p_imme_o        ),
        .id1_j_imme_o       (id1p_j_imme_o      ),
        .id1_is_branch_o    (id1p_is_branch_o   ),
        .id1_is_j_imme_o    (id1p_is_j_imme_o   ),
        .id1_is_jr_o        (id1p_is_jr_o       ),
        .id1_is_ls_o        (id1p_is_ls_o       ),

        .id1_pc_i           (id1p_pc_i          ),
        .id1_inst_i         (id1p_inst_i        ),
        .id1_op_code_i      (id1p_op_code_i     ),
        .id1_rs_i           (id1p_rs_i          ),
        .id1_rt_i           (id1p_rt_i          ),
        .id1_rd_i           (id1p_rd_i          ),
        .id1_sa_i           (id1p_sa_i          ),
        .id1_funct_i        (id1p_funct_i       ),
        .id1_w_reg_ena_i    (id1p_w_reg_ena_i   ),
        .id1_w_reg_dst_i    (id1p_w_reg_dst_i   ),
        .id1_imme_i         (id1p_imme_i        ),
        .id1_j_imme_i       (id1p_j_imme_i      ),
        .id1_is_branch_i    (id1p_is_branch_i   ),
        .id1_is_j_imme_i    (id1p_is_j_imme_i   ),
        .id1_is_jr_i        (id1p_is_jr_i       ),
        .id1_is_ls_i        (id1p_is_ls_i       )
    );

    // id2 => ex

    wire        id2c_is_branch_o;
    wire        id2c_is_j_imme_o;
    wire        id2c_is_jr_o;
    wire        id2c_is_ls_o;
    wire [4 :0] id2c_rs_o;
    wire [4 :0] id2c_rt_o;
    wire [4 :0] id2c_rd_o;
    wire [4 :0] id2c_w_reg_dst_o;
    wire [4 :0] id2c_sa_o;
    wire [31:0] id2c_rs_data_o;
    wire [31:0] id2c_rt_data_o;
    wire [15:0] id2c_imme_o;
    wire [25:0] id2c_j_imme_o;
    wire [31:0] id2c_ext_imme_o;
    wire [31:0] id2c_pc_o;
    wire [2 :0] id2c_src_a_sel_o;
    wire [2 :0] id2c_src_b_sel_o;
    wire [5 :0] id2c_alu_sel_o;
    wire [2 :0] id2c_alu_res_sel_o;
    wire        id2c_w_reg_ena_o;
    wire [1 :0] id2c_w_hilo_ena_o;
    wire        id2c_ls_ena_o;
    wire [3 :0] id2c_ls_sel_o;
    wire        id2c_wb_reg_sel_o;
    wire        id2c_is_branch_i;
    wire        id2c_is_j_imme_i;
    wire        id2c_is_jr_i;
    wire        id2c_is_ls_i;
    wire [4 :0] id2c_rs_i;
    wire [4 :0] id2c_rt_i;
    wire [4 :0] id2c_rd_i;
    wire [4 :0] id2c_w_reg_dst_i;
    wire [4 :0] id2c_sa_i;
    wire [31:0] id2c_rs_data_i;
    wire [31:0] id2c_rt_data_i;
    wire [15:0] id2c_imme_i;
    wire [25:0] id2c_j_imme_i;
    wire [31:0] id2c_ext_imme_i;
    wire [31:0] id2c_pc_i;
    wire [2 :0] id2c_src_a_sel_i;
    wire [2 :0] id2c_src_b_sel_i;
    wire [5 :0] id2c_alu_sel_i;
    wire [2 :0] id2c_alu_res_sel_i;
    wire        id2c_w_reg_ena_i;
    wire [1 :0] id2c_w_hilo_ena_i;
    wire        id2c_ls_ena_i;
    wire [3 :0] id2c_ls_sel_i;
    wire        id2c_wb_reg_sel_i;

    wire        id2p_is_branch_o;
    wire        id2p_is_j_imme_o;
    wire        id2p_is_jr_o;
    wire        id2p_is_ls_o;
    wire [4 :0] id2p_rs_o;
    wire [4 :0] id2p_rt_o;
    wire [4 :0] id2p_rd_o;
    wire [4 :0] id2p_w_reg_dst_o;
    wire [4 :0] id2p_sa_o;
    wire [31:0] id2p_rs_data_o;
    wire [31:0] id2p_rt_data_o;
    wire [15:0] id2p_imme_o;
    wire [25:0] id2p_j_imme_o;
    wire [31:0] id2p_ext_imme_o;
    wire [31:0] id2p_pc_o;
    wire [2 :0] id2p_src_a_sel_o;
    wire [2 :0] id2p_src_b_sel_o;
    wire [5 :0] id2p_alu_sel_o;
    wire [2 :0] id2p_alu_res_sel_o;
    wire        id2p_w_reg_ena_o;
    wire [1 :0] id2p_w_hilo_ena_o;
    wire        id2p_ls_ena_o;
    wire [3 :0] id2p_ls_sel_o;
    wire        id2p_wb_reg_sel_o;
    wire        id2p_is_branch_i;
    wire        id2p_is_j_imme_i;
    wire        id2p_is_jr_i;
    wire        id2p_is_ls_i;
    wire [4 :0] id2p_rs_i;
    wire [4 :0] id2p_rt_i;
    wire [4 :0] id2p_rd_i;
    wire [4 :0] id2p_w_reg_dst_i;
    wire [4 :0] id2p_sa_i;
    wire [31:0] id2p_rs_data_i;
    wire [31:0] id2p_rt_data_i;
    wire [15:0] id2p_imme_i;
    wire [25:0] id2p_j_imme_i;
    wire [31:0] id2p_ext_imme_i;
    wire [31:0] id2p_pc_i;
    wire [2 :0] id2p_src_a_sel_i;
    wire [2 :0] id2p_src_b_sel_i;
    wire [5 :0] id2p_alu_sel_i;
    wire [2 :0] id2p_alu_res_sel_i;
    wire        id2p_w_reg_ena_i;
    wire [1 :0] id2p_w_hilo_ena_i;
    wire        id2p_ls_ena_i;
    wire [3 :0] id2p_ls_sel_i;
    wire        id2p_wb_reg_sel_i;

    wire        id2c_take_branch;
    wire        id2c_take_j_imme;
    wire        id2c_take_jr;
    wire        id2c_flush_req;

    id2_ex id2_exc (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (),
        .stall              (),
        .id2_is_branch_o    (id2c_is_branch_o   ),
        .id2_is_j_imme_o    (id2c_is_j_imme_o   ),
        .id2_is_jr_o        (id2c_is_jr_o       ),
        .id2_is_ls_o        (id2c_is_ls_o       ),
        .id2_rs_o           (id2c_rs_o          ),
        .id2_rt_o           (id2c_rt_o          ),
        .id2_rd_o           (id2c_rd_o          ),
        .id2_w_reg_dst_o    (id2c_w_reg_dst_o   ),
        .id2_sa_o           (id2c_sa_o          ),
        .id2_rs_data_o      (id2c_rs_data_o     ),
        .id2_rt_data_o      (id2c_rt_data_o     ),
        .id2_imme_o         (id2c_imme_o        ),
        .id2_j_imme_o       (id2c_j_imme_o      ),
        .id2_ext_imme_o     (id2c_ext_imme_o    ),
        .id2_pc_o           (id2c_pc_o          ),
        .id2_src_a_sel_o    (id2c_src_a_sel_o   ),
        .id2_src_b_sel_o    (id2c_src_b_sel_o   ),
        .id2_alu_sel_o      (id2c_alu_sel_o     ),
        .id2_alu_res_sel_o  (id2c_alu_res_sel_o ),
        .id2_w_reg_ena_o    (id2c_w_reg_ena_o   ),
        .id2_w_hilo_ena_o   (id2c_w_hilo_ena_o  ),
        .id2_ls_ena_o       (id2c_ls_ena_o      ),
        .id2_ls_sel_o       (id2c_ls_sel_o      ),
        .id2_wb_reg_sel_o   (id2c_wb_reg_sel_o  ),

        .id2_is_branch_i    (id2c_is_branch_i   ),
        .id2_is_j_imme_i    (id2c_is_j_imme_i   ),
        .id2_is_jr_i        (id2c_is_jr_i       ),
        .id2_is_ls_i        (id2c_is_ls_i       ),
        .id2_rs_i           (id2c_rs_i          ),
        .id2_rt_i           (id2c_rt_i          ),
        .id2_rd_i           (id2c_rd_i          ),
        .id2_w_reg_dst_i    (id2c_w_reg_dst_i   ),
        .id2_sa_i           (id2c_sa_i          ),
        .id2_rs_data_i      (id2c_rs_data_i     ),
        .id2_rt_data_i      (id2c_rt_data_i     ),
        .id2_imme_i         (id2c_imme_i        ),
        .id2_j_imme_i       (id2c_j_imme_i      ),
        .id2_ext_imme_i     (id2c_ext_imme_i    ),
        .id2_pc_i           (id2c_pc_i          ),
        .id2_src_a_sel_i    (id2c_src_a_sel_i   ),
        .id2_src_b_sel_i    (id2c_src_b_sel_i   ),
        .id2_alu_sel_i      (id2c_alu_sel_i     ),
        .id2_alu_res_sel_i  (id2c_alu_res_sel_i ),
        .id2_w_reg_ena_i    (id2c_w_reg_ena_i   ),
        .id2_w_hilo_ena_i   (id2c_w_hilo_ena_i  ),
        .id2_ls_ena_i       (id2c_ls_ena_i      ),
        .id2_ls_sel_i       (id2c_ls_sel_i      ),
        .id2_wb_reg_sel_i   (id2c_wb_reg_sel_i  )
    );

    id2_ex id2_exp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (),
        .stall              (),
        .id2_is_branch_o    (id2p_is_branch_o   ),
        .id2_is_j_imme_o    (id2p_is_j_imme_o   ),
        .id2_is_jr_o        (id2p_is_jr_o       ),
        .id2_is_ls_o        (id2p_is_ls_o       ),
        .id2_rs_o           (id2p_rs_o          ),
        .id2_rt_o           (id2p_rt_o          ),
        .id2_rd_o           (id2p_rd_o          ),
        .id2_w_reg_dst_o    (id2p_w_reg_dst_o   ),
        .id2_sa_o           (id2p_sa_o          ),
        .id2_rs_data_o      (id2p_rs_data_o     ),
        .id2_rt_data_o      (id2p_rt_data_o     ),
        .id2_imme_o         (id2p_imme_o        ),
        .id2_j_imme_o       (id2p_j_imme_o      ),
        .id2_ext_imme_o     (id2p_ext_imme_o    ),
        .id2_pc_o           (id2p_pc_o          ),
        .id2_src_a_sel_o    (id2p_src_a_sel_o   ),
        .id2_src_b_sel_o    (id2p_src_b_sel_o   ),
        .id2_alu_sel_o      (id2p_alu_sel_o     ),
        .id2_alu_res_sel_o  (id2p_alu_res_sel_o ),
        .id2_w_reg_ena_o    (id2p_w_reg_ena_o   ),
        .id2_w_hilo_ena_o   (id2p_w_hilo_ena_o  ),
        .id2_ls_ena_o       (id2p_ls_ena_o      ),
        .id2_ls_sel_o       (id2p_ls_sel_o      ),
        .id2_wb_reg_sel_o   (id2p_wb_reg_sel_o  ),

        .id2_is_branch_i    (id2p_is_branch_i   ),
        .id2_is_j_imme_i    (id2p_is_j_imme_i   ),
        .id2_is_jr_i        (id2p_is_jr_i       ),
        .id2_is_ls_i        (id2p_is_ls_i       ),
        .id2_rs_i           (id2p_rs_i          ),
        .id2_rt_i           (id2p_rt_i          ),
        .id2_rd_i           (id2p_rd_i          ),
        .id2_w_reg_dst_i    (id2p_w_reg_dst_i   ),
        .id2_sa_i           (id2p_sa_i          ),
        .id2_rs_data_i      (id2p_rs_data_i     ),
        .id2_rt_data_i      (id2p_rt_data_i     ),
        .id2_imme_i         (id2p_imme_i        ),
        .id2_j_imme_i       (id2p_j_imme_i      ),
        .id2_ext_imme_i     (id2p_ext_imme_i    ),
        .id2_pc_i           (id2p_pc_i          ),
        .id2_src_a_sel_i    (id2p_src_a_sel_i   ),
        .id2_src_b_sel_i    (id2p_src_b_sel_i   ),
        .id2_alu_sel_i      (id2p_alu_sel_i     ),
        .id2_alu_res_sel_i  (id2p_alu_res_sel_i ),
        .id2_w_reg_ena_i    (id2p_w_reg_ena_i   ),
        .id2_w_hilo_ena_i   (id2p_w_hilo_ena_i  ),
        .id2_ls_ena_i       (id2p_ls_ena_i      ),
        .id2_ls_sel_i       (id2p_ls_sel_i      ),
        .id2_wb_reg_sel_i   (id2p_wb_reg_sel_i  )
    );

    // ex => mem

    // mem => wb
    

    npc npc_cp (
        .id_take_j_imme     (id2c_take_j_imme   ),
        .id_j_imme          (id2c_j_imme        ),
        .id_take_branch     (id2c_take_branch   ),
        .id_branch_offset   (id2c_imme          ),
        .id_take_jr         (id2c_take_jr       ),
        .id_rs_data         (id2c_rs_data       ),
        .id_pc              (id2c_pc            ),
        .pc                 (pc_cur_pc          ),
        .inst_rdata_1_ok    (inst_rdata_1_ok    ),
        .inst_rdata_2_ok    (inst_rdata_2_ok    ),
        .next_pc            (npc_next_pc        )
    );

    assign inst_ena     = ~(rst | i_cache_stall_req);
    assign inst_addr_1  = npc_next_pc;
    assign inst_addr_2  = npc_next_pc + 32'h4;

    pc pc_cp (
        .clk                (clk                ),
        .rst                (rst                ),
        .stall              (),
        .flush              (),
        .next_pc            (npc_next_pc        ),
        .pc                 (pc_cur_pc          )
    );

    i_fifo i_fifo_cp (
        .clk                (clk                ),
        .rst                (rst                ),
        .flush              (                   ),
        .p_data_1           (ii_p_data_1        ),
        .p_data_2           (ii_p_data_2        ),
        .r_data_1           (fifo_r_data_1      ),
        .r_data_2           (fifo_r_data_2      ),
        .r_data_1_ok        (fifo_r_data_1_ok   ),
        .r_data_2_ok        (fifo_r_data_2_ok   ),
        .fifo_stall_req     (fifo_stall_req     ),  // attention !
        .w_ena_1            (inst_rdata_1_ok    ),
        .w_ena_2            (inst_rdata_2_ok    ),
        .w_data_1           (inst_rdata_1       ),
        .w_data_2           (inst_rdata_2       ) 
    );

    issue issue_inst (
        .stall              (),

        .fifo_r_data_1      (fifo_r_data_1      ),
        .fifo_r_data_1_ok   (fifo_r_data_1_ok   ),
        .fifo_r_data_2      (fifo_r_data_2      ),
        .fifo_r_data_2_ok   (fifo_r_data_2_ok   ),

        .p_data_1           (p_data_1           ),
        .p_data_2           (p_data_2           ),

        .id1_valid_1        (id1c_valid_o       ),
        .id1_pc_1           (id1c_pc_o          ),
        .id1_inst_1         (id1c_inst_o        ),
        .id1_op_code_1      (id1c_op_code_o     ),
        .id1_rs_1           (id1c_rs_o          ),
        .id1_rt_1           (id1c_rt_o          ),
        .id1_rd_1           (id1c_rd_o          ),
        .id1_sa_1           (id1c_sa_o          ),
        .id1_funct_1        (id1c_funct_o       ),
        .id1_w_reg_ena_1    (id1c_w_reg_ena_o   ),
        .id1_w_reg_dst_1    (id1c_w_reg_dst_o   ),
        .id1_imme_1         (id1c_imme_o        ),
        .id1_j_imme_1       (id1c_j_imme_o      ),
        .id1_is_branch_1    (id1c_is_branch_o   ),
        .id1_is_j_imme_1    (id1c_is_j_imme_o   ),
        .id1_is_jr_1        (id1c_is_jr_o       ),
        .id1_is_ls_1        (id1c_is_ls_o       ),

        .id1_valid_2        (id1p_valid_o       ),
        .id1_pc_2           (id1p_pc_o          ),
        .id1_inst_2         (id1p_inst_o        ),
        .id1_op_code_2      (id1p_op_code_o     ),
        .id1_rs_2           (id1p_rs_o          ),
        .id1_rt_2           (id1p_rt_o          ),
        .id1_rd_2           (id1p_rd_o          ),
        .id1_sa_2           (id1p_sa_o          ),
        .id1_funct_2        (id1p_funct_o       ),
        .id1_w_reg_ena_2    (id1p_w_reg_ena_o   ),
        .id1_w_reg_dst_2    (id1p_w_reg_dst_o   ),
        .id1_imme_2         (id1p_imme_o        ),
        .id1_j_imme_2       (id1p_j_imme_o      ),
        .id1_is_branch_2    (id1p_is_branch_o   ),
        .id1_is_j_imme_2    (id1p_is_j_imme_o   ),
        .id1_is_jr_2        (id1p_is_jr_o       ),
        .id1_is_ls_2        (id1p_is_ls_o       )
    );

    forward forward_c (
        .id_rs              (),
        .id_rt              (),

        .ex_w_reg_ena_1     (),
        .ex_w_reg_dst_1     (),
        .ex_alu_res_1       (),
        .ex_ls_ena_1        (),

        .ex_w_reg_ena_2     (),
        .ex_w_reg_dst_2     (),
        .ex_alu_res_2       (),
        .ex_ls_ena_2        (),

        .mem_w_reg_ena_1    (),
        .mem_w_reg_dst_1    (),
        .mem_alu_res_1      (),
        .mem_ls_ena_1       (),

        .mem_w_reg_ena_2    (),
        .mem_w_reg_dst_2    (),
        .mem_alu_res_2      (),
        .mem_ls_ena_2       (),

        .forward_rs         (),
        .forward_rt         (),

        .forward_stall_req  (),
        .forward_flush_req  ()
    );

    forward forward_p (
        .id_rs              (),
        .id_rt              (),
        
        .ex_w_reg_ena_1     (),
        .ex_w_reg_dst_1     (),
        .ex_alu_res_1       (),
        .ex_ls_ena_1        (),

        .ex_w_reg_ena_2     (),
        .ex_w_reg_dst_2     (),
        .ex_alu_res_2       (),
        .ex_ls_ena_2        (),

        .mem_w_reg_ena_1    (),
        .mem_w_reg_dst_1    (),
        .mem_alu_res_1      (),
        .mem_ls_ena_1       (),

        .mem_w_reg_ena_2    (),
        .mem_w_reg_dst_2    (),
        .mem_alu_res_2      (),
        .mem_ls_ena_2       (),

        .forward_rs         (),
        .forward_rt         (),

        .forward_stall_req  (),
        .forward_flush_req  ()
    );

    idu_2 idu2_c (
        .id1_op_code        (id1c_op_code_i     ),
        .id1_rs             (id1c_rs_i          ),
        .id1_rt             (id1c_rt_i          ),
        .id1_rd             (id1c_rd_i          ),
        .id1_sa             (id1c_sa_i          ),
        .id1_funct          (id1c_funct_i       ),
        .id1_w_reg_ena      (id1c_w_reg_ena_i   ),
        .id1_w_reg_dst      (id1c_w_reg_dst_i   ),
        .id1_imme           (id1c_imme_i        ),
        .id1_j_imme         (id1c_j_imme_i      ),
        .id1_is_branch      (id1c_is_branch_i   ),
        .id1_is_j_imme      (id1c_is_j_imme_i   ),
        .id1_is_jr          (id1c_is_jr_i       ),
        .id1_is_ls          (id1c_is_ls_i       ),

        .forward_rs         (),
        .forward_rt         (),

        .reg_r_addr_1       (id1c_r_addr_1      ),
        .reg_r_addr_2       (id1c_r_addr_2      ),
        .reg_r_data_1       (id1c_r_data_1      ),
        .reg_r_data_2       (id1c_r_data_2      ),

        .id2_is_branch      (id2c_is_branch_o   ),
        .id2_is_j_imme      (id2c_is_j_imme_o   ),
        .id2_is_jr          (id2c_is_jr_o       ),
        .id2_is_ls          (id2c_is_ls_o       ),

        .id2_rs             (id2c_rs_o          ),    
        .id2_rt             (id2c_rt_o          ),    
        .id2_rd             (id2c_rd_o          ),    
        .id2_w_reg_dst      (id2c_w_reg_dst_o   ),

        .id2_sa             (id2c_sa_o          ),
        .id2_rs_data        (id2c_rs_data_o     ),
        .id2_rt_data        (id2c_rt_data_o     ),
        .id2_imme           (id2c_imme_o        ),
        .id2_j_imme         (id2c_j_imme_o      ),
        .id2_ext_imme       (id2c_ext_imme_o    ),

        .id2_take_branch    (id2c_take_branch   ),
        .id2_take_j_imme    (id2c_take_j_imme   ),
        .id2_take_jr        (id2c_take_jr       ),
        .id2_flush_req      (id2c_flush_req     ),  // attention !

        .id2_src_a_sel      (id2c_src_a_sel_o   ),
        .id2_src_b_sel      (id2c_src_b_sel_o   ),
        .id2_alu_sel        (id2c_alu_sel_o     ),
        .id2_alu_res_sel    (id2c_alu_res_sel_o ),
        .id2_w_reg_ena      (id2c_w_reg_ena_o   ),
        .id2_w_hilo_ena     (id2c_w_hilo_ena_o  ),
        .id2_ls_ena         (id2c_ls_ena_o      ),
        .id2_ls_sel         (id2c_ls_sel_o      ),
        .id2_wb_reg_sel     (id2c_wb_reg_sel_o  )
    );

    idu_2 idu2_p (
        .id1_op_code        (id1p_op_code_i     ),
        .id1_rs             (id1p_rs_i          ),
        .id1_rt             (id1p_rt_i          ),
        .id1_rd             (id1p_rd_i          ),
        .id1_sa             (id1p_sa_i          ),
        .id1_funct          (id1p_funct_i       ),
        .id1_w_reg_ena      (id1p_w_reg_ena_i   ),
        .id1_w_reg_dst      (id1p_w_reg_dst_i   ),
        .id1_imme           (id1p_imme_i        ),
        .id1_j_imme         (id1p_j_imme_i      ),
        .id1_is_branch      (id1p_is_branch_i   ),
        .id1_is_j_imme      (id1p_is_j_imme_i   ),
        .id1_is_jr          (id1p_is_jr_i       ),
        .id1_is_ls          (id1p_is_ls_i       ),

        .forward_rs         (),
        .forward_rt         (),

        .reg_r_addr_1       (id1p_r_addr_1),
        .reg_r_addr_2       (id1p_r_addr_2),
        .reg_r_data_1       (id1p_r_data_1),
        .reg_r_data_2       (id1p_r_data_2),

        .id2_is_branch      (id2p_is_branch_o   ),
        .id2_is_j_imme      (id2p_is_j_imme_o   ),
        .id2_is_jr          (id2p_is_jr_o       ),
        .id2_is_ls          (id2p_is_ls_o       ),

        .id2_rs             (id2p_rs_o          ),    
        .id2_rt             (id2p_rt_o          ),    
        .id2_rd             (id2p_rd_o          ),    
        .id2_w_reg_dst      (id2p_w_reg_dst_o   ),

        .id2_sa             (id2p_sa_o          ),
        .id2_rs_data        (id2p_rs_data_o     ),
        .id2_rt_data        (id2p_rt_data_o     ),
        .id2_imme           (id2p_imme_o        ),
        .id2_j_imme         (id2p_j_imme_o      ),
        .id2_ext_imme       (id2p_ext_imme_o    ),

        .id2_take_branch    (                   ),
        .id2_take_j_imme    (                   ),
        .id2_take_jr        (                   ),
        .id2_flush_req      (                   ),

        .id2_src_a_sel      (id2p_src_a_sel_o   ),
        .id2_src_b_sel      (id2p_src_b_sel_o   ),
        .id2_alu_sel        (id2p_alu_sel_o     ),
        .id2_alu_res_sel    (id2p_alu_res_sel_o ),
        .id2_w_reg_ena      (id2p_w_reg_ena_o   ),
        .id2_w_hilo_ena     (id2p_w_hilo_ena_o  ),
        .id2_ls_ena         (id2p_ls_ena_o      ),
        .id2_ls_sel         (id2p_ls_sel_o      ),
        .id2_wb_reg_sel     (id2p_wb_reg_sel_o  )
    );

    regfile rg (
        .clk                (clk                ),
        .rst                (rst                ),
        
        .r_addr_1           (id1c_r_addr_1      ),
        .r_data_1           (id1c_r_data_1      ),
        
        .r_addr_2           (id1c_r_addr_2      ),
        .r_data_2           (id1c_r_data_2      ),
        
        .r_addr_3           (id1p_r_addr_1      ),
        .r_data_3           (id1p_r_data_1      ),
        
        .r_addr_4           (id1p_r_addr_2      ),
        .r_data_4           (id1p_r_data_2      ),
        
        .w_ena_1            (),
        .w_addr_1           (),
        .w_data_1           (),

        .w_ena_2            (),
        .w_addr_2           (),
        .w_data_2           ()
    );

    alu alu_c (
        .clk                (clk                ),
        .rst                (rst                ),
        .src_a              (id2c_src_a_sel_i   ),
        .src_b              (id2c_src_b_sel_i   ),
        .alu_sel            (id2c_alu_sel_i     ),
        .alu_res            (id2c_alu_res_i     ),
        .alu_hi_res         (id2c_hi_res        ),
        .alu_lo_res         (id2c_lo_res        ),
        .alu_stall_req      (aluc_stall_req     )
    );

    alu alu_p (
        .clk                (clk                ),
        .rst                (rst                ),
        .src_a              (id2p_src_a_sel_i   ),
        .src_b              (id2p_src_b_sel_i   ),
        .alu_sel            (id2p_alu_sel_i     ),
        .alu_res            (id2p_alu_res_i     ),
        .alu_hi_res         (                   ),
        .alu_lo_res         (                   ),
        .alu_stall_req      (                   )
    );

    lsu lsu_cp (
        .ex_alu_res         (),
        .ex_rt_data         (),
        .ex_ls_ena          (),
        .ex_ls_sel          (),
        .mem_alu_res        (),
        .mem_rt_data        (),
        .mem_ls_ena         (),
        .mem_ls_sel         (),
        .mem_r_data         (),
        .data_ram_en        (),
        .data_ram_wen       (),
        .data_ram_addr      (),
        .data_ram_wdata     (),
        .data_ram_rdata     ()
    );

    wbu wbu_c (
        .wb_sel             (),
        .alu_res            (),
        .mem_data           (),
        .w_reg_dst          (),
        .wb_w_reg_ena       (),
        .wb_w_reg_addr      (),
        .wb_w_reg_data      ()
    );

    wbu wbu_p (
        .wb_sel             (),
        .alu_res            (),
        .mem_data           (),
        .w_reg_dst          (),
        .wb_w_reg_ena       (),
        .wb_w_reg_addr      (),
        .wb_w_reg_data      ()
    );

endmodule