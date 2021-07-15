`timescale 1ns / 1ps

`include "../idu/id_def.v"

module alu_p (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] src_a,
    input   wire [31:0] src_b,
    input   wire [5 :0] alu_sel,
    output  wire [31:0] alu_res
);
    wire [31:0] ext_src_a, ext_src_b;
    assign ext_src_a = src_a;
    assign ext_src_b = src_b;
    reg  [31:0] ext_alu_res;


    wire        is_slt      = $signed(src_a) < $signed(src_b);
    wire        is_sltu     = src_a < src_b;
    wire [31:0] sll_val     = src_a << src_b[4:0];
    wire [31:0] sra_val     = $signed(src_a) >>> src_b[4:0];
    wire [31:0] srl_val     = src_a >> src_b[4:0];

    always @(*) begin
        ext_alu_res = 32'h0;

        case (alu_sel)
        `ALU_SEL_NOP    : begin
            ext_alu_res = 32'h0;    
        end
        `ALU_SEL_ADD    : begin
            ext_alu_res = ext_src_a + ext_src_b;
        end
        `ALU_SEL_SUB    : begin
            ext_alu_res = ext_src_a - ext_src_b;
        end
        `ALU_SEL_SLT    : begin
            ext_alu_res = is_slt;
        end
        `ALU_SEL_SLTU   : begin
            ext_alu_res = is_sltu;
        end
        `ALU_SEL_AND    : begin
            ext_alu_res = src_a & src_b;
        end
        `ALU_SEL_NOR    : begin
            ext_alu_res = ~(src_a | src_b);
        end
        `ALU_SEL_OR     : begin
            ext_alu_res = src_a | src_b;
        end
        `ALU_SEL_XOR    : begin
            ext_alu_res = src_a ^ src_b;
        end
        `ALU_SEL_SLL    : begin
            ext_alu_res = sll_val;
        end
        `ALU_SEL_SRA    : begin
            ext_alu_res = sra_val;
        end
        `ALU_SEL_SRL    : begin
            ext_alu_res = srl_val;
        end
        `ALU_SEL_LUI    : begin
            ext_alu_res = {src_b[15:0], 16'h0};
        end
        default: begin
            ext_alu_res = 32'h0;
        end
        endcase
    end

    assign alu_res = ext_alu_res[31:0];

endmodule