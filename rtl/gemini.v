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

    npc npc_cp (
        .id_take_j_imme     (),
        .id_j_imme          (), 
        .id_take_branch     (),
        .id_branch_offset   (),    
        .id_take_jr         (),
        .id_rs_data         (),
        .id_pc              (),
        .pc                 (),
        .inst_rdata_1_ok    (),    
        .inst_rdata_2_ok    (),    
        .next_pc            ()
    );

    pc pc_cp (
        .clk                (clk),
        .rst                (rst),
        .stall              (),
        .flush              (),
        .next_pc            (),
        .pc                 ()
    );

    i_fifo i_fifo_cp (
        .clk                (clk),
        .rst                (rst),
        .flush              (),
        .p_data_1           (),    
        .p_data_2           (),    
        .r_data_1           (),    
        .r_data_2           (),    
        .r_data_1_ok        (),        
        .r_data_2_ok        (),        
        .fifo_stall_req     (),        
        .w_ena_1            (),    
        .w_ena_2            (),    
        .w_data_1           (),    
        .w_data_2           ()    
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



    idu_1 idu1_c (
        .inst               (),
        .id1_op_code        (),
        .id1_rs             (),
        .id1_rt             (),
        .id1_rd             (),
        .id1_sa             (),
        .id1_funct          (),
        .id1_w_reg_ena      (),
        .id1_w_reg_dst      (),
        .id1_imme           (),
        .id1_j_imme         (),
        .id1_is_branch      (),
        .id1_is_j_imme      (),
        .id1_is_jr          (),
        .id1_is_ls          ()
    );

    idu_1 idu1_p (
        .inst               (),
        .id1_op_code        (),
        .id1_rs             (),
        .id1_rt             (),
        .id1_rd             (),
        .id1_sa             (),
        .id1_funct          (),
        .id1_w_reg_ena      (),
        .id1_w_reg_dst      (),
        .id1_imme           (),
        .id1_j_imme         (),
        .id1_is_branch      (),
        .id1_is_j_imme      (),
        .id1_is_jr          (),
        .id1_is_ls          ()
    );

    idu_2 idu2_c (
        .id1_op_code        (),
        .id1_rs             (),
        .id1_rt             (),
        .id1_rd             (),
        .id1_sa             (),
        .id1_funct          (),
        .id1_w_reg_ena      (),
        .id1_w_reg_dst      (),
        .id1_imme           (),
        .id1_j_imme         (),
        .id1_is_branch      (),
        .id1_is_j_imme      (),
        .id1_is_jr          (),
        .id1_is_ls          (),
        .forward_rs         (),
        .forward_rt         (),

        .reg_r_addr_1       (),
        .reg_r_addr_2       (),
        .reg_r_data_1       (),
        .reg_r_data_2       (),

        .id2_is_branch      (),
        .id2_is_j_imme      (),
        .id2_is_jr          (),
        .id2_is_ls          (),

        .id2_rs             (),    
        .id2_rt             (),    
        .id2_rd             (),    
        .id2_w_reg_dst      (),

        .id2_sa             (),
        .id2_rs_data        (),        
        .id2_rt_data        (),        
        .id2_imme           (),    
        .id2_j_imme         (),    
        .id2_ext_imme       (),

        .id2_take_branch    (),
        .id2_take_j_imme    (),
        .id2_take_jr        (),

        .id2_src_a_sel      (),
        .id2_src_b_sel      (),
        .id2_alu_sel        (),
        .id2_alu_res_sel    (),
        .id2_w_reg_ena      (),
        .id2_w_hilo_ena     (),
        .id2_ls_ena         (),
        .id2_ls_sel         (),
        .id2_wb_reg_sel     ()
    );

    idu_2 idu2_p (
        .id1_op_code        (),
        .id1_rs             (),
        .id1_rt             (),
        .id1_rd             (),
        .id1_sa             (),
        .id1_funct          (),
        .id1_w_reg_ena      (),
        .id1_w_reg_dst      (),
        .id1_imme           (),
        .id1_j_imme         (),
        .id1_is_branch      (),
        .id1_is_j_imme      (),
        .id1_is_jr          (),
        .id1_is_ls          (),
        .forward_rs         (),
        .forward_rt         (),

        .reg_r_addr_1       (),
        .reg_r_addr_2       (),
        .reg_r_data_1       (),
        .reg_r_data_2       (),

        .id2_is_branch      (),
        .id2_is_j_imme      (),
        .id2_is_jr          (),
        .id2_is_ls          (),

        .id2_rs             (),    
        .id2_rt             (),    
        .id2_rd             (),    
        .id2_w_reg_dst      (),

        .id2_sa             (),
        .id2_rs_data        (),        
        .id2_rt_data        (),        
        .id2_imme           (),    
        .id2_j_imme         (),    
        .id2_ext_imme       (),

        .id2_take_branch    (),
        .id2_take_j_imme    (),
        .id2_take_jr        (),

        .id2_src_a_sel      (),
        .id2_src_b_sel      (),
        .id2_alu_sel        (),
        .id2_alu_res_sel    (),
        .id2_w_reg_ena      (),
        .id2_w_hilo_ena     (),
        .id2_ls_ena         (),
        .id2_ls_sel         (),
        .id2_wb_reg_sel     ()
    );

    regfile rg (
        .clk                (),
        .rst                (),
        
        .r_addr_1           (),
        .r_data_1           (),
        
        .r_addr_2           (),
        .r_data_2           (),
        
        .r_addr_3           (),
        .r_data_3           (),
        
        .r_addr_4           (),
        .r_data_4           (),
        
        .w_ena_1            (),
        .w_addr_1           (),
        .w_data_1           (),

        .w_ena_2            (),
        .w_addr_2           (),
        .w_data_2           ()
    );

    alu alu_c (
        .clk                (),
        .rst                (),
        .src_a              (),
        .src_b              (),
        .alu_sel            (),
        .alu_res            (),
        .alu_hi_res         (),
        .alu_lo_res         (),
        .alu_stall_req      ()
    );

    alu alu_p (
        .clk                (),
        .rst                (),
        .src_a              (),
        .src_b              (),
        .alu_sel            (),
        .alu_res            (),
        .alu_hi_res         (),
        .alu_lo_res         (),
        .alu_stall_req      ()
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