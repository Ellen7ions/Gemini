`timescale 1ns / 1ps

module divider(
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] src_a,
    input   wire [31:0] src_b,
    input   wire        en,
    input   wire        div_sign,
    output  wire [31:0] s,
    output  wire [31:0] r,
    output  reg         res_ready,
    output  reg         stall_all
    );

    localparam [1:0] DIV_FREE   = 0;
    localparam [1:0] DIV_S      = 1;
    localparam [1:0] DIV_U      = 2;

    reg [63:0] res;
    assign s = res[63:32];
    assign r = res[31:0];
    reg [1:0] cur_state;
    reg [1:0] state_next;

    reg div_s_en_reg;
    reg div_u_en_reg;
    reg div_s_en_reg_next;
    reg div_u_en_reg_next;

    always @(posedge clk) begin
        if (rst) begin
            div_s_en_reg <= 1'b0;
            div_u_en_reg <= 1'b0;
        end else begin
            div_s_en_reg <= div_s_en_reg_next; 
            div_u_en_reg <= div_u_en_reg_next;
        end
    end

    wire        res_s_ready;
    wire        res_u_ready;
    wire [63:0] res_s;
    wire [63:0] res_u;

    always @(posedge clk) begin
        if (rst) begin
            cur_state <= DIV_FREE;
        end else begin
            cur_state <= state_next;
        end
    end

    always @(*) begin
        if (rst) begin
            state_next = DIV_FREE;
        end else begin
            case (cur_state)
            DIV_FREE: begin
                if (en) begin
                    state_next = div_sign ? DIV_S : DIV_U;
                end else begin
                    state_next = DIV_FREE;
                end
            end

            DIV_S: begin
                if (res_s_ready) begin
                    state_next = DIV_FREE;
                end else begin
                    state_next = DIV_S;
                end
            end 

            DIV_U: begin
                if (res_u_ready) begin
                    state_next = DIV_FREE;
                end else begin
                    state_next = DIV_U; 
                end
            end

            default: begin
                
            end 
            endcase
        end
    end

    always @(*) begin
        if (rst) begin
            div_s_en_reg_next   = 1'b0;
            div_u_en_reg_next   = 1'b0;
            stall_all           = 1'b0;
            res                 = 64'h0000_0000_0000_0000;
            res_ready           = 1'b0;
        end else begin
            case(cur_state)
            DIV_FREE: begin
                stall_all       = en;
                res             = 64'h0000_0000_0000_0000;
                res_ready       = 1'b0;
                if (en) begin
                    div_s_en_reg_next = div_sign;
                    div_u_en_reg_next = ~div_sign;
                end else begin
                    div_s_en_reg_next = 1'b0; 
                    div_u_en_reg_next = 1'b0;
                end
            end

            DIV_S: begin
                stall_all       = ~res_s_ready;
                div_s_en_reg_next    = 1'b0;
                div_u_en_reg_next    = 1'b0;
                res             = res_s_ready ? res_s : 64'h0000_0000_0000_0000;
                res_ready       = res_s_ready;
            end

            DIV_U: begin
                stall_all       = ~res_u_ready;
                div_s_en_reg_next    = 1'b0;
                div_u_en_reg_next    = 1'b0;
                res             = res_u_ready ? res_u : 64'h0000_0000_0000_0000;
                res_ready       = res_u_ready;
            end

            default: begin
                div_s_en_reg_next   = 1'b0;
                div_u_en_reg_next   = 1'b0;
                stall_all           = 1'b0;
                res                 = 64'h0000_0000_0000_0000;
                res_ready           = 1'b0;
            end
            endcase
        end
    end

    div_signed divs (
        .aclk(clk),                                      // input wire aclk
        .s_axis_divisor_tvalid  (div_s_en_reg),    // input wire s_axis_divisor_tvalid
        .s_axis_divisor_tdata   (src_b),      // input wire [31 : 0] s_axis_divisor_tdata
        .s_axis_dividend_tvalid (div_s_en_reg),  // input wire s_axis_dividend_tvalid
        .s_axis_dividend_tdata  (src_a),    // input wire [31 : 0] s_axis_dividend_tdata
        .m_axis_dout_tvalid     (res_s_ready),          // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata      (res_s)            // output wire [63 : 0] m_axis_dout_tdata
    );

    div_unsigned divu (
        .aclk(clk),                                      // input wire aclk
        .s_axis_divisor_tvalid  (div_u_en_reg),    // input wire s_axis_divisor_tvalid
        .s_axis_divisor_tdata   (src_b),      // input wire [31 : 0] s_axis_divisor_tdata
        .s_axis_dividend_tvalid (div_u_en_reg),  // input wire s_axis_dividend_tvalid
        .s_axis_dividend_tdata  (src_a),    // input wire [31 : 0] s_axis_dividend_tdata
        .m_axis_dout_tvalid     (res_u_ready),          // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata      (res_u)            // output wire [63 : 0] m_axis_dout_tdata
    );

endmodule