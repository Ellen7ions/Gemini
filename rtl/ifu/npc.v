`timescale 1ns/1ps

`include "../exu/branch_def.v"

module npc (
    input   wire        clk,
    input   wire        rst,
    // input   wire        stall,

    // input   wire        id_take_jmp,
    input   wire [31:0] id2_rs_data,
    input   wire [31:0] id2_rt_data,
    input   wire        id2_is_branch,
    input   wire        id2_is_jr,
    input   wire        id2_is_j_imme,
    input   wire [3 :0] id2_branch_sel,
    input   wire [31:0] id2_jmp_target,
    input   wire        id2_pred_taken,
    input   wire [31:0] id2_pred_target,
    output  wire        flush_req,

    input   wire        exception_pc_ena,
    input   wire [31:0] exception_pc,

    input   wire [31:0] id_pc,
    
    input   wire [31:0] pc,
    output  wire        pc_pred_taken,
    output  wire [31:0] pc_pred_target,

    output  reg  [31:0] next_pc
);

  wire id2_take_jmp;
  wire id2_take_branch;
    
  wire beq_check      = id2_rs_data == id2_rt_data;
  wire bne_check      = id2_rs_data != id2_rt_data;
  wire bgez_check     = ~id2_rs_data[31];
  wire bgtz_check     = ~id2_rs_data[31] & |(id2_rs_data[30:0]);
  wire blez_check     = id2_rs_data[31] | !(|id2_rs_data);
  wire bltz_check     = id2_rs_data[31];

  assign id2_take_branch  =
    (!(id2_branch_sel ^ `BRANCH_SEL_BEQ     )) & (beq_check  )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BNE     )) & (bne_check  )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BGEZ    )) & (bgez_check )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BGTZ    )) & (bgtz_check )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BLEZ    )) & (blez_check )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BLTZ    )) & (bltz_check )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BGEZAL  )) & (bgez_check )  & id2_is_branch  |
    (!(id2_branch_sel ^ `BRANCH_SEL_BLTZAL  )) & (bltz_check )  & id2_is_branch  ;


  assign id2_take_jmp   =
          id2_is_jr | id2_take_branch | id2_is_j_imme;

  wire        pred_taken;
  wire [31:0] pred_target;

  b_predictor b_predictor0 (
    .clk            (clk            ),
    .rst            (rst            ),
    .pc             (pc             ),
    .pred_taken     (pred_taken     ),
    .pred_target    (pred_target    ),
    .update         (id2_is_branch | id2_is_j_imme | id2_is_jr),
    .update_pc      (id_pc          ),
    .act_taken      (id2_take_jmp   ),
    .act_target     (id2_jmp_target )
  );

  always @(*) begin
    if (exception_pc_ena) begin
      next_pc = exception_pc;
    end else if (id2_take_jmp) begin
      next_pc = id2_jmp_target;
    end else if (pred_taken) begin
      next_pc = pred_target;
    end else if (pc[2]) begin
      next_pc = pc + 32'h4;
    end else begin
      next_pc = pc + 32'h8;
    end
  end

  assign pc_pred_taken = pred_taken;
  assign pc_pred_target= pred_target;

  assign flush_req = id2_take_jmp & (~id2_pred_taken | id2_pred_taken & (id2_pred_target != id2_jmp_target));

  // If there is no branch predictor, 
  // the probability of successful branch prediction is 15%
  // 
  // reg [31:0] b_total_counter;
  // reg [31:0] b_pred_miss_counter;

  // always @(posedge clk) begin
  //   if (rst) begin
  //     b_total_counter <= 32'h0;
  //     b_pred_miss_counter  <= 32'h0;
  //   end else if (~stall) begin
  //     if (id2_is_jr | id2_is_branch | id2_is_j_imme) begin
  //       b_total_counter <= b_total_counter + 32'h1;
  //     end
  //     if (id2_take_jmp) begin
  //       b_pred_miss_counter <= b_pred_miss_counter + 32'h1;
  //     end
  //   end
  // end

endmodule