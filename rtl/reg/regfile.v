`timescale 1ns / 1ps   

module regfile (
    input   wire        clk,
    input   wire        rst,

    input   wire        w_ena,

    input   wire [5 :0] r_addr_1,
    output  reg  [31:0] r_data_1,

    input   wire [5 :0] r_addr_2,
    output  reg  [31:0] r_data_2,

    input   wire [5 :0] w_addr_1,
    input   wire [31:0] w_data_1,

    input   wire [5 :0] w_addr_2,
    input   wire [31:0] w_data_2
);

    reg [31:0] rf[31:0];

    always @(posedge clk) begin
        if (w_ena) begin
            if (w_addr_1 == w_addr_2) begin
                if (w_addr_1 != 32'h0) begin
                    rf[w_addr_1] <= w_data_2;
                end
            end else begin
                if (w_addr_1 != 32'h0) begin
                    rf[w_addr_1] <= w_data_1;
                end

                if (w_addr_2 != 32'h0) begin
                    rf[w_addr_2] <= w_data_2;
                end
            end
        end
    end

    always @(*) begin
        if (r_addr_1 == 32'h0) begin
            r_data_1 = {32{1'b0}};
        end else if ((w_addr_1 == w_addr_2) && (w_addr_1 == r_addr_1)) begin
            r_data_1 = w_data_2;
        end else if (w_addr_1 == r_addr_1) begin
            r_data_1 = w_data_1;
        end else if (w_addr_2 == r_addr_2) begin
            r_data_1 = w_data_2;
        end else begin
            r_data_1 = rf[r_addr_1];
        end

        if (r_addr_2 == 32'h0) begin
            r_data_2 = {32{1'b0}};
        end else if ((w_addr_1 == w_addr_2) && (w_addr_2 == r_addr_2)) begin
            r_data_2 = w_data_2;
        end else if (w_addr_1 == r_addr_2) begin
            r_data_2 = w_data_1;
        end else if (w_addr_2 == r_addr_2) begin
            r_data_2 = w_data_2;
        end else begin
            r_data_2 = rf[r_addr_2];
        end
    end

endmodule