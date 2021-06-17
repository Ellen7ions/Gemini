`timescale 1ns / 1ps

module multiplier (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] src_a,
    input   wire [31:0] src_b,
    input   wire        en,
    input   wire        mul_sign,
    output  wire [31:0] s,
    output  wire [31:0] r,
    output  reg         res_ready,
    output  reg         stall_all
);
    reg  [31:0] a_reg, b_reg;
    reg         sign;
    wire [63:0] c;
    wire [63:0] res;

    assign res = sign ? -c : c;
    assign r = res[63:32];
    assign s = res[31: 0];

    localparam [1:0] MUL_FREE       = 0;
    localparam [1:0] MUL_RUNNING    = 1;
    reg [1:0] cur_state;
    reg [1:0] next_state;
    reg [2:0] counter;
    reg [2:0] next_counter;

    always @(posedge clk) begin
        if (rst) begin
            cur_state   <= MUL_FREE; 
        end else begin
            cur_state <= next_state;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            counter <= 3'h0;
        end else begin
            counter <= next_counter;
        end
    end

    always @(*) begin
        if (rst) begin
            stall_all = 1'b0;
            sign = 1'b0;
            next_state = MUL_FREE;
            a_reg = 32'h0;
            b_reg = 32'h0;
            res_ready = 1'b0;
            next_counter = 3'h0;
        end else begin
            case(cur_state)
            MUL_FREE:    begin
                if (en) begin
                    stall_all = 1'b1;
                    if (mul_sign) begin
                        sign = src_a[31] ^ src_b[31];
                        a_reg = src_a[31] ? ~src_a + 32'h1 : src_a;
                        b_reg = src_b[31] ? ~src_b + 32'h1 : src_b;
                    end else begin
                        sign  = 1'b0;
                        a_reg = src_a;
                        b_reg = src_b;
                    end
                    next_state = MUL_RUNNING;
                    next_counter = 3'h3;
                end else begin
                    stall_all = 1'b0;
                    next_state = MUL_FREE;
                end
            end

            MUL_RUNNING: begin
                if (counter == 3'h0) begin
                    stall_all = 1'b0;
                    next_state = MUL_FREE;
                    res_ready = 1'b1;
                end else begin
                    stall_all = 1'b1;
                    next_state = MUL_RUNNING;
                    res_ready = 1'b0;
                    next_counter = counter - 3'h1;
                end
            end

            default:     begin
                 stall_all = 1'b0;
                 sign = 1'b0;
                 next_state = MUL_FREE;
                 a_reg = 32'h0;
                 b_reg = 32'h0;
                 res_ready = 1'b0;
            end
            endcase 
        end
    end

    mult_unsigned uut (
        .CLK        (clk    ),
        .SCLR       (rst    ),
        .A          (a_reg  ),
        .B          (b_reg  ),
        .P          (c      )
    );
endmodule