`timescale 1ns/1ps

`include "../exu/branch_def.v"

module npc (
    input   wire        clk,
    input   wire        rst,

    input   wire        fetch_ena,
    input   wire [31:0] fetch_target,

    input   wire        exception_pc_ena,
    input   wire [31:0] exception_pc,
    
    input   wire [31:0] pc,

    output  reg  [31:0] next_pc
);

  always @(*) begin
    if (exception_pc_ena) begin
      next_pc = exception_pc;
    end else if (fetch_ena) begin
      next_pc = fetch_target;
    end else if (pc[2]) begin
      next_pc = pc + 32'h4;
    end else begin
      next_pc = pc + 32'h8;
    end
  end

endmodule