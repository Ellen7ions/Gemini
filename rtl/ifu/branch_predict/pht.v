`timescale 1ns / 1ps

module PHT #(
    parameter LINE_NUM  = 1024,
    parameter WIDTH     = 6 
) (
    input   wire                        clk,
    input   wire                        rst,
    input   wire [$clog2(LINE_NUM)-1:0] r_addr,
    output  wire [WIDTH           -1:0] rdata,
    input   wire [$clog2(LINE_NUM)-1:0] w_addr,
    input   wire                        wen,
    input   wire [WIDTH           -1:0] wdata,
    output  wire [WIDTH           -1:0] wrdata
);
    reg [WIDTH-1:0] bht_reg[LINE_NUM-1:0];
    
    integer i;
    always @(posedge clk ) begin
        if (rst) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                bht_reg[i]  <= {WIDTH{1'b0}};
            end
        end else if (wen) begin
            bht_reg[w_addr]   <= wdata;
        end
    end

    assign wrdata= bht_reg[w_addr];
    assign rdata = bht_reg[r_addr];

endmodule