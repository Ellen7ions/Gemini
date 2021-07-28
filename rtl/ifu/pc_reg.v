`timescale 1ns / 1ps

module pc_reg (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        stall,
    input   wire        exception_pc_ena,

    input   wire        pc_valid_o,
    input   wire [31:0] pc_o,
    input   wire        tlb_refill_tlbl_o,
    input   wire        tlb_invalid_tlbl_o,
    
    output  reg         pc_valid_i,
    output  reg  [31:0] pc_i,
    output  reg         tlb_refill_tlbl_i,
    output  reg         tlb_invalid_tlbl_i
);
    always @(posedge clk ) begin
        if (rst | (flush & !stall) | exception_pc_ena) begin
            pc_i                <= 32'h0;
            tlb_refill_tlbl_i   <= 1'h0;
            tlb_invalid_tlbl_i  <= 1'h0;
            pc_valid_i          <= 1'b0;
        end else if (!flush & !stall) begin
            pc_valid_i          <= pc_valid_o;
            pc_i                <= pc_o;
            tlb_refill_tlbl_i   <= tlb_refill_tlbl_o;
            tlb_invalid_tlbl_i  <= tlb_invalid_tlbl_o;
        end
    end
endmodule