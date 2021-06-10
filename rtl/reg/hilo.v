`timescale 1ns / 1ps

module hilo (
    input   wire        clk,
    input   wire        rst,
    input   wire [1 :0] w_hilo_ena,
    input   wire [31:0] w_hi_data,
    input   wire [31:0] w_lo_data,
    output  wire [31:0] r_hi_data,
    output  wire [31:0] r_lo_data
);
    reg [31:0] hi, lo;
    always @(posedge clk) begin
        if (rst) begin
            hi <= 32'h0;
            lo <= 32'h0;
        end else begin
            if (w_hilo_ena[1]) begin
                hi <= w_hi_data;
            end

            if (w_hilo_ena[0]) begin
                lo <= w_lo_data;
            end
        end
    end

    assign r_hi_data = w_hilo_ena[1] ? w_hi_data : hi;
    assign r_lo_data = w_hilo_ena[0] ? w_lo_data : lo;
endmodule