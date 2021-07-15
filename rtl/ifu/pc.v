`timescale 1ns / 1ps

module pc(
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,
    input   wire        flush,
    input   wire        exception_pc_ena,
    input   wire [31:0] next_pc,
    output  reg  [31:0] pc,
    output  reg  [31:0] pc_reg,
    output  reg         w_fifo
);

    reg ce;
    always @(posedge clk ) begin
        if (rst) begin
            ce <= 1'b0;
        end else begin
            ce <= 1'b1;
        end
    end 

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'hbfc0_0000;
        end else if (!stall) begin
            pc <= next_pc;
        end
    end

    always @(posedge clk ) begin
        if (rst || (flush & !stall)) begin
            pc_reg  <= 32'h0;
            w_fifo  <= 1'b0;
        end else if (ce & !flush & !stall) begin
            pc_reg  <= pc;
            w_fifo  <= 1'b1;
        end
    end

endmodule