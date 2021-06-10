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
    output  wire        alu_stall_req
);
    wire [32:0] ext_src_a, ext_src_b;
    assign ext_src_a = {1'b0, src_a};
    assign ext_src_b = {1'b0, src_b};
    reg  [32:0] ext_alu_res;

    wire [63:0] s_prod, u_prod;
    assign s_prod = $signed(src_a) * $signed(src_b);
    assign u_prod = src_a * src_b;

    reg  div_en;
    reg  div_sign;
    wire [31:0] s, r;
    wire res_ready;

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
        .stall_all  (alu_stall_req)
    );

    always @(*) begin
        ext_alu_res = 33'h0;
        alu_hi_res  = 32'h0;
        alu_lo_res  = 32'h0;
        div_en      = 1'b0;
        div_sign    = 1'b0;

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
            ext_alu_res = {31'h0, $signed(src_a) < $signed(src_b)};
        end
        `ALU_SEL_SLTU   : begin
            ext_alu_res = {31'h0, src_a < src_b};
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
            alu_hi_res = s_prod[63:32];
            alu_lo_res = s_prod[31: 0];
        end
        `ALU_SEL_MULTU  : begin
            alu_hi_res = u_prod[63:32];
            alu_lo_res = u_prod[31: 0];
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
            ext_alu_res = {1'b0, src_a << src_b[4:0]};
        end
        `ALU_SEL_SRA    : begin
            ext_alu_res = {1'b0, $signed(src_a) >>> src_b[4:0]};
        end
        `ALU_SEL_SRL    : begin
            ext_alu_res = {1'b0, src_a >> src_b[4:0]};
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