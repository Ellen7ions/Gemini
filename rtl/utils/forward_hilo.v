`timescale 1ns / 1ps

`include "forward_def.v"

module forward_hilo (
    input   wire [1 :0]  lsu1c_w_hilo_ena,
    input   wire [1 :0]  lsu2c_w_hilo_ena,
    output  reg  [2 :0]  forward_hi,
    output  reg  [2 :0]  forward_lo
);

    always @(*) begin
        forward_hi = `FORWARD_HILI_NOP;
        if (lsu1c_w_hilo_ena[1]) begin
            forward_hi = `FORWARD_LS1C_HI;
        end else if (lsu2c_w_hilo_ena[1]) begin
            forward_hi = `FORWARD_LS2C_HI;
        end
    end

    always @(*) begin
        forward_lo = `FORWARD_HILI_NOP;
        if (lsu1c_w_hilo_ena[0]) begin
            forward_lo = `FORWARD_LS1C_LO;
        end else if (lsu2c_w_hilo_ena[0]) begin
            forward_lo = `FORWARD_LS2C_LO;
        end
    end

endmodule