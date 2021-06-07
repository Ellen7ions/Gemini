`timescale 1ns / 1ps   

// 4R 2W
module regfile (
    input   wire        clk,
    input   wire        rst,
    input   wire [4 :0] r_addr_1,
    output  reg  [31:0] r_data_1,
    input   wire [4 :0] r_addr_2,
    output  reg  [31:0] r_data_2,
    input   wire [4 :0] r_addr_3,
    output  reg  [31:0] r_data_3,
    input   wire [4 :0] r_addr_4,
    output  reg  [31:0] r_data_4,
    input   wire        w_ena_1,
    input   wire [4 :0] w_addr_1,
    input   wire [31:0] w_data_1,
    input   wire        w_ena_2,
    input   wire [4 :0] w_addr_2,
    input   wire [31:0] w_data_2
);

    reg [31:0] rf[31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            rf[i] = 32'h0;
        end
    end

    always @(posedge clk) begin
        case ({w_ena_1, w_ena_2})
        2'b11: begin
            if (w_addr_1 == w_addr_2) begin
                if (w_addr_1 != 32'h0) begin
                    rf[w_addr_2] <= w_data_2;
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

        2'b10: begin
            if (w_addr_1 != 32'h0) begin
                rf[w_addr_1]    <= w_data_1;
            end
        end

        2'b01: begin
            if (w_addr_2 != 32'h0) begin
                rf[w_addr_2]    <= w_data_2;
            end
        end

        default: begin
            
        end
        endcase
    end

    always @(*) begin
        if (r_addr_1 == 32'h0) begin
            r_data_1 = 32'h0;
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 == w_addr_2)) begin
            if (r_addr_1 == w_addr_1) begin
                r_data_1 = w_data_2;
            end else begin
                r_data_1 = rf[r_addr_1];
            end
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 != w_addr_2)) begin
            if (r_addr_1 == w_addr_1) begin
                r_data_1 = w_data_1;
            end else if (r_addr_1 == w_addr_2) begin
                r_data_1 = w_data_2;
            end else begin
                r_data_1 = rf[r_addr_1];
            end
        end else if ( w_ena_1 & !w_ena_2) begin
            if (r_addr_1 == w_addr_1) begin
                r_data_1 = w_data_1;
            end else begin
                r_data_1 = rf[r_addr_1];
            end
        end else if (!w_ena_1 &  w_ena_2) begin
            if (r_addr_1 == w_addr_2) begin
                r_data_1 = w_data_2;
            end else begin
                r_data_1 = rf[r_addr_1];
            end
        end else begin
            r_data_1 = rf[r_addr_1];
        end

        if (r_addr_2 == 32'h0) begin
            r_data_2 = 32'h0;
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 == w_addr_2)) begin
            if (r_addr_2 == w_addr_1) begin
                r_data_2 = w_data_2;
            end else begin
                r_data_2 = rf[r_addr_2];
            end
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 != w_addr_2)) begin
            if (r_addr_2 == w_addr_1) begin
                r_data_2 = w_data_1;
            end else if (r_addr_2 == w_addr_2) begin
                r_data_2 = w_data_2;
            end else begin
                r_data_2 = rf[r_addr_2];
            end
        end else if ( w_ena_1 & !w_ena_2) begin
            if (r_addr_2 == w_addr_1) begin
                r_data_2 = w_data_1;
            end else begin
                r_data_2 = rf[r_addr_2];
            end
        end else if (!w_ena_1 &  w_ena_2) begin
            if (r_addr_2 == w_addr_2) begin
                r_data_2 = w_data_2;
            end else begin
                r_data_2 = rf[r_addr_2];
            end
        end else begin
            r_data_2 = rf[r_addr_2];
        end

        if (r_addr_3 == 32'h0) begin
            r_data_3 = 32'h0;
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 == w_addr_2)) begin
            if (r_addr_3 == w_addr_1) begin
                r_data_3 = w_data_2;
            end else begin
                r_data_3 = rf[r_addr_3];
            end
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 != w_addr_2)) begin
            if (r_addr_3 == w_addr_1) begin
                r_data_3 = w_data_1;
            end else if (r_addr_3 == w_addr_2) begin
                r_data_3 = w_data_2;
            end else begin
                r_data_3 = rf[r_addr_3];
            end
        end else if ( w_ena_1 & !w_ena_2) begin
            if (r_addr_3 == w_addr_1) begin
                r_data_3 = w_data_1;
            end else begin
                r_data_3 = rf[r_addr_3];
            end
        end else if (!w_ena_1 &  w_ena_2) begin
            if (r_addr_3 == w_addr_2) begin
                r_data_3 = w_data_2;
            end else begin
                r_data_3 = rf[r_addr_3];
            end
        end else begin
            r_data_3 = rf[r_addr_3];
        end

        if (r_addr_4 == 32'h0) begin
            r_data_4 = 32'h0;
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 == w_addr_2)) begin
            if (r_addr_4 == w_addr_1) begin
                r_data_4 = w_data_2;
            end else begin
                r_data_4 = rf[r_addr_4];
            end
        end else if (w_ena_1 & w_ena_2 & (w_addr_1 != w_addr_2)) begin
            if (r_addr_4 == w_addr_1) begin
                r_data_4 = w_data_1;
            end else if (r_addr_4 == w_addr_2) begin
                r_data_4 = w_data_2;
            end else begin
                r_data_4 = rf[r_addr_4];
            end
        end else if ( w_ena_1 & !w_ena_2) begin
            if (r_addr_4 == w_addr_1) begin
                r_data_4 = w_data_1;
            end else begin
                r_data_4 = rf[r_addr_4];
            end
        end else if (!w_ena_1 &  w_ena_2) begin
            if (r_addr_4 == w_addr_2) begin
                r_data_4 = w_data_2;
            end else begin
                r_data_4 = rf[r_addr_4];
            end
        end else begin
            r_data_4 = rf[r_addr_4];
        end

    end

endmodule