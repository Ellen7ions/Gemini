`timescale 1ns / 1ps

`include "pred_def.v"

module pred_fsm (
    input   wire        if_taken,
    input   wire [1 :0] cur_state,
    output  reg  [1 :0] next_state
);

    always @(*) begin
        case (cur_state)
        `STRONG_NOT_TAKEN: begin
            next_state = if_taken ? `WEAK_NOT_TAKEN : `STRONG_NOT_TAKEN;
        end
        `WEAK_NOT_TAKEN: begin
            next_state = if_taken ? `WEAK_TAKEN : `STRONG_NOT_TAKEN;
        end
        `WEAK_TAKEN: begin
            next_state = if_taken ? `STRONG_TAKEN : `WEAK_NOT_TAKEN;
        end
        `STRONG_TAKEN: begin
            next_state = if_taken ? `STRONG_TAKEN : `WEAK_TAKEN;
        end
        default: begin
            next_state = `STRONG_NOT_TAKEN;
        end
        endcase
    end
endmodule