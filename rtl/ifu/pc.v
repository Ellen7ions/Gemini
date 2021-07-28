`timescale 1ns / 1ps

module pc(
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,
    input   wire        flush,
    input   wire        exception_pc_ena,
    input   wire [31:0] next_pc,
    output  reg  [31:0] pc
);

    reg         reg_npc_ena;
    reg [31:0]  reg_npc;
    always @(posedge clk) begin
        if (rst) begin
            reg_npc_ena <= 1'b0;
            reg_npc     <= 32'h0;
        end else if (stall & ~reg_npc_ena) begin
            reg_npc     <= next_pc;
            reg_npc_ena <= 1'b1;
        end else if (~stall & reg_npc_ena) begin
            reg_npc_ena <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'hbfc0_0000;
        end else if (!stall | exception_pc_ena) begin
            pc <= reg_npc_ena & ~flush ? reg_npc : next_pc;
        end
    end

endmodule