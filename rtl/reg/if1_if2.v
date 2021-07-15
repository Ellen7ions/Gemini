`timescale 1ns / 1ps

module if1_if2 (
    input   wire        clk,
    input   wire        rst, 
    input   wire        flush,
    input   wire        stall,
    input   wire        exception_flush,

    input   wire [31:0] npc_o,
    output  reg  [31:0] npc_i
);

    always @(posedge clk ) begin
        if (rst || (flush & !stall) || exception_flush) begin
            npc_i <= 32'hbfc0_0000;
        end else if (!flush & !stall) begin
            npc_i <= npc_o;
        end
    end
    
endmodule