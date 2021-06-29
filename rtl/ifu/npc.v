`timescale 1ns/1ps

module npc (
    input   wire        id_take_jmp,
    input   wire [31:0] id_jmp_target,
    output  wire        flush_req,

    input   wire        exception_pc_ena,
    input   wire [31:0] exception_pc,

    input   wire [31:0] id_pc,
    
    input   wire [31:0] pc,
    input   wire        inst_rdata_1_ok,
    input   wire        inst_rdata_2_ok,

    output  reg  [31:0] next_pc
);

  always @(*) begin
    if (exception_pc_ena) begin
      next_pc = exception_pc;
    end else if (id_take_jmp) begin
      next_pc = id_jmp_target;
    end else if (inst_rdata_1_ok & inst_rdata_2_ok) begin
      next_pc = {pc + 32'h8};
    end else if (inst_rdata_1_ok) begin
      next_pc = {pc + 32'h4};
    end else begin
      next_pc = pc;
    end
  end

  assign flush_req = id_take_jmp;

endmodule