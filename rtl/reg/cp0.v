`timescale 1ns / 1ps

module cp0 (
    input   wire        clk,
    input   wire        rst,
    input   wire [5 :0] interrupt,
    
    // read cp0 from software
    input   wire        r_ena,
    input   wire [7 :0] r_addr,
    output  reg  [31:0] r_data,
    
    // write cp0 from software
    input   wire        w_ena,
    input   wire [7 :0] w_addr,
    input   wire [31:0] w_data,

    // show
    output  wire [31:0] epc,
    output  wire        exception_is_interrupt,

    input   wire        cp0_cls_exl,

    input   wire        w_cp0_update_ena,
    input   wire [4 :0] w_cp0_exccode,
    input   wire        w_cp0_bd,
    input   wire        w_cp0_exl,
    input   wire [31:0] w_cp0_epc,
    input   wire        w_cp0_badvaddr_ena,
    input   wire [31:0] w_cp0_badvaddr
);

    // no rst
    reg [31:0]  BadVAddr;    // can't be written from software
    reg [31:0]  Count;
    reg [31:0]  Compare;
    reg [31:0]  EPC;
    
    // rst
    reg [31:0]  Status;
    reg [31:0]  Cause;

    assign epc                      = EPC;
    assign exception_is_interrupt   = Status[0] & ~Status[1] & |(Status[15:8] & Cause[15:8]);

    reg tick;

    always @(posedge clk) begin
        tick        <= ~tick;
        if (tick)
            Count   <= Count + 32'h1;
        Cause[15:8] <= {Cause[30] | interrupt[5], interrupt[4: 0]};

        if (rst) begin
            tick    <= 1'b0;
            Status  <= {9'd0, 1'd1, 6'd0, 8'd0, 6'd0, 1'd0, 1'd0};
            Cause   <= 32'd0;
        end else begin
            if (Compare != 32'h0 && Count == Compare)
                Cause[30]   <= 1'b1;

            if (cp0_cls_exl) begin
                Status[1]   <= 1'b0;
            end

            if (w_cp0_update_ena) begin
                Cause[6 :2] <= w_cp0_exccode;
                Cause[31]   <= w_cp0_bd;
                Status[1]   <= w_cp0_exl;
                EPC         <= w_cp0_epc;
                if (w_cp0_badvaddr_ena)
                    BadVAddr<= w_cp0_badvaddr;
            end

            if (w_ena) begin
                case (w_addr)
                {5'd9, 3'd0}: begin
                    Count           <= w_data;    
                end

                {5'd11, 3'd0}: begin
                    Compare         <= w_data;
                    Cause[30]       <= 1'b0;
                end

                {5'd12, 3'd0}: begin
                    Status[15:8]   <= w_data[15:8];
                    Status[1]       <= w_data[1];
                    Status[0]       <= w_data[0];
                end

                {5'd13, 3'd0}: begin
                    Cause[9 :8]     <= w_data[9 :8];
                end

                {5'd14, 3'd0}: begin
                    EPC             <= w_data;
                end

                default: begin
                    
                end
                endcase
            end           
        end
    end

    always @(*) begin
        if (rst) begin
            r_data = 32'd0;
        end else begin
            if (r_ena) begin
                if (w_ena & r_addr == w_addr) begin
                    r_data = w_data;
                end else begin
                    case (r_addr)
                    {5'd8, 3'd0}: begin
                        r_data      = BadVAddr;
                    end

                    {5'd11, 3'd0}: begin
                        r_data      = Compare;
                    end

                    {5'd9, 3'd0}: begin
                        r_data      = Count;
                    end

                    {5'd12, 3'd0}: begin
                        r_data      = Status;
                    end

                    {5'd13, 3'd0}: begin
                        r_data      = Cause;
                    end

                    {5'd14, 3'd0}: begin
                        r_data      = EPC; 
                    end

                    default: begin
                        r_data      = 32'd0;
                    end
                    endcase 
                end
            end else begin
                r_data = 32'd0;
            end
        end
    end
endmodule