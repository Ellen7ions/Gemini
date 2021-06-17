`timescale 1ns / 1ps

`include "../idu/id_def.v"

module alu (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] src_a,
    input   wire [31:0] src_b,
    input   wire [5 :0] alu_sel,
    output  wire [31:0] alu_res,
    output  reg  [31:0] alu_hi_res,
    output  reg  [31:0] alu_lo_res,
    output  reg         alu_overflow,
    output  wire        alu_stall_req
);
    wire [32:0] ext_src_a, ext_src_b;
    assign ext_src_a = {1'b0, src_a};
    assign ext_src_b = {1'b0, src_b};
    reg  [32:0] ext_alu_res;

    reg  div_en;
    reg  div_sign;
    wire [31:0] s, r;
    wire res_ready;
    wire div_stall_req;

    divider div (
        .clk        (clk),
        .rst        (rst),
        .src_a      (src_a),
        .src_b      (src_b),
        .en         (div_en),
        .div_sign   (div_sign),
        .s          (s),
        .r          (r),
        .res_ready  (res_ready),
        .stall_all  (div_stall_req)
    );

    reg  mul_en;
    reg  mul_sign;
    wire [31:0] m_s, m_r;
    wire mul_res_ready;
    wire mul_stall_req;

    multiplier mul (
        .clk        (clk),
        .rst        (rst),
        .src_a      (src_a),
        .src_b      (src_b),
        .en         (mul_en),
        .mul_sign   (mul_sign),
        .s          (m_s),
        .r          (m_r),
        .res_ready  (mul_res_ready),
        .stall_all  (mul_stall_req)
    );

    assign alu_stall_req = mul_stall_req | div_stall_req;

    wire        is_slt      = $signed(src_a) < $signed(src_b);
    wire        is_sltu     = src_a < src_b;
    wire [31:0] sll_val     = src_a << src_b[4:0];
    wire [31:0] sra_val     = $signed(src_a) >>> src_b[4:0];
    wire [31:0] srl_val     = src_a >> src_b[4:0];

    always @(*) begin
        ext_alu_res = 33'h0;
        alu_hi_res  = 32'h0;
        alu_lo_res  = 32'h0;
        div_en      = 1'b0;
        div_sign    = 1'b0;
        mul_en      = 1'b0;
        mul_sign    = 1'b0;
        alu_overflow= 1'b0;

        case (alu_sel)
        `ALU_SEL_NOP    : begin
            ext_alu_res = 32'h0;    
        end
        `ALU_SEL_ADD    : begin
            ext_alu_res = ext_src_a + ext_src_b;
            alu_overflow= ((src_a[31] ~^ src_b[31]) & (src_a[31] ^ ext_alu_res[31]));
        end
        `ALU_SEL_SUB    : begin
            ext_alu_res = ext_src_a - ext_src_b;
            alu_overflow= ((src_a[31]  ^ src_b[31]) & (src_a[31] ^ ext_alu_res[31]));
        end
        `ALU_SEL_SLT    : begin
            ext_alu_res = {31'h0, is_slt};
        end
        `ALU_SEL_SLTU   : begin
            ext_alu_res = {31'h0, is_sltu};
        end
        `ALU_SEL_DIV    : begin
            div_en      = 1'b1;
            div_sign    = 1'b1;
            alu_hi_res  = res_ready ? r : 32'h0;
            alu_lo_res  = res_ready ? s : 32'h0;
        end
        `ALU_SEL_DIVU   : begin
            div_en      = 1'b1;
            div_sign    = 1'b0;
            alu_hi_res  = res_ready ? r : 32'h0;
            alu_lo_res  = res_ready ? s : 32'h0;
        end
        `ALU_SEL_MULT   : begin
            mul_en      = 1'b1;
            mul_sign    = 1'b1;
            alu_hi_res  = mul_res_ready ? m_r : 32'h0;
            alu_lo_res  = mul_res_ready ? m_s : 32'h0;
        end
        `ALU_SEL_MULTU  : begin
            mul_en      = 1'b1;
            mul_sign    = 1'b0;
            alu_hi_res  = mul_res_ready ? m_r : 32'h0;
            alu_lo_res  = mul_res_ready ? m_s : 32'h0;
        end
        `ALU_SEL_AND    : begin
            ext_alu_res = {1'b0, src_a & src_b};
        end
        `ALU_SEL_NOR    : begin
            ext_alu_res = {1'b0, ~(src_a | src_b)};
        end
        `ALU_SEL_OR     : begin
            ext_alu_res = {1'b0, src_a | src_b};
        end
        `ALU_SEL_XOR    : begin
            ext_alu_res = {1'b0, src_a ^ src_b};
        end
        `ALU_SEL_SLL    : begin
            ext_alu_res = {1'b0, sll_val};
        end
        `ALU_SEL_SRA    : begin
            ext_alu_res = {1'b0, sra_val};
        end
        `ALU_SEL_SRL    : begin
            ext_alu_res = {1'b0, srl_val};
        end
        `ALU_SEL_LUI    : begin
            ext_alu_res = {src_b, 16'h0};
        end
        `ALU_SEL_MTHI   : begin
            alu_hi_res  = src_a;
            alu_lo_res  = 32'h0;
        end
        `ALU_SEL_MTLO   : begin
            alu_hi_res  = 32'h0;
            alu_lo_res  = src_a;
        end
        default: begin
            ext_alu_res = 33'h0;
            alu_hi_res  = 32'h0;
            alu_lo_res  = 32'h0;
        end
        endcase
    end

    assign alu_res = ext_alu_res[31:0];

endmodule