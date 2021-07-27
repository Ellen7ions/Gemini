`timescale 1ns / 1ps

module pc(
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,
    input   wire        flush,
    input   wire        exception_pc_ena,
    input   wire [31:0] next_pc,
    input   wire        next_fetch_ds,
    output  reg  [31:0] pc,
    input   wire        pc_pred_taken,
    input   wire [31:0] pc_pred_target,
    input   wire        tlb_ref_tlbl,
    input   wire        tlb_inv_tlbl,
    output  reg  [31:0] pc_reg,
    output  reg         pc_fetch_ds_reg,
    output  reg         pc_pred_taken_reg,
    output  reg  [31:0] pc_pred_target_reg,
    output  reg         tlb_ref_tlbl_reg,
    output  reg         tlb_inv_tlbl_reg,
    output  reg         w_fifo
);

    reg         reg_npc_ena;
    reg [31:0]  reg_npc;
    reg         reg_npc_fetch_ds;
    always @(posedge clk) begin
        if (rst) begin
            reg_npc_ena <= 1'b0;
            reg_npc     <= 32'h0;
            reg_npc_fetch_ds <= 1'b0;
        end else if (stall & ~reg_npc_ena) begin
            reg_npc     <= next_pc;
            reg_npc_fetch_ds <= next_fetch_ds;
            reg_npc_ena <= 1'b1;
        end else if (~stall & reg_npc_ena) begin
            reg_npc_ena <= 1'b0;
        end
    end

    reg pc_fetch_ds;

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'hbfc0_0000;
            pc_fetch_ds <= 1'b0;
        end else if (!stall | exception_pc_ena) begin
            pc <= reg_npc_ena & ~flush ? reg_npc : next_pc;
            pc_fetch_ds <= reg_npc_ena & ~flush ? reg_npc_fetch_ds : next_fetch_ds;
        end
    end

    always @(posedge clk ) begin
        if (rst | (flush & !stall) | exception_pc_ena) begin
            pc_reg              <= 32'hbfc0_0000;
            pc_fetch_ds_reg     <= 1'b0;
            pc_pred_taken_reg   <= 1'h0;
            pc_pred_target_reg  <= 32'h0;
            w_fifo              <= 1'b0;
            tlb_ref_tlbl_reg    <= 1'b0;
            tlb_inv_tlbl_reg    <= 1'b0;
        end else if (!flush & !stall) begin
            pc_reg              <= pc;
            pc_fetch_ds_reg     <= pc_fetch_ds;
            pc_pred_taken_reg   <= pc_pred_taken;
            pc_pred_target_reg  <= pc_pred_target;
            w_fifo              <= 1'b1;
            tlb_ref_tlbl_reg    <= tlb_ref_tlbl;
            tlb_inv_tlbl_reg    <= tlb_inv_tlbl;
        end
    end

endmodule