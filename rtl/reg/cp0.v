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
    output  wire [31:0] index,
    output  wire [31:0] entryhi,
    output  wire [31:0] entrylo0,
    output  wire [31:0] entrylo1,
    output  wire [31:0] config_,

    output  wire        cp0_has_int,

    input   wire        cp0_cls_exl,

    input   wire        w_cp0_update_ena,
    input   wire [4 :0] w_cp0_exccode,
    input   wire        w_cp0_bd,
    input   wire        w_cp0_exl,
    input   wire [31:0] w_cp0_epc,
    input   wire        w_cp0_badvaddr_ena,
    input   wire [31:0] w_cp0_badvaddr,
    input   wire        w_cp0_entryhi_ena,
    input   wire [31:0] w_cp0_entryhi,

    input   wire        w_cp0_tlbp_ena,
    input   wire        w_cp0_tlbr_ena,
    input   wire [31:0] w_cp0_Index,
    input   wire [31:0] w_cp0_EntryHi,
    input   wire [31:0] w_cp0_EntryLo0,
    input   wire [31:0] w_cp0_EntryLo1
);

    reg [31:0]  BadVAddr;    // can't be written from software
    reg [32:0]  Count;
    reg [31:0]  Compare;
    (*mark_debug = "true"*) reg [31:0]  EPC;
    reg [31:0]  Status;
    reg [31:0]  Cause;
    reg [31:0]  Index;
    reg [31:0]  EntryHi;
    reg [31:0]  EntryLo0;
    reg [31:0]  EntryLo1;
    reg [31:0]  Config;
    reg [31:0]  Config1;

    assign epc          = EPC;
    assign index        = Index;
    assign entryhi      = EntryHi;
    assign entrylo0     = EntryLo0;
    assign entrylo1     = EntryLo1;
    assign config_      = Config;
    assign cp0_has_int  = ((Cause[15:8] & Status[15:8]) != 8'h0) & Status[0] & ~Status[1];

    always @(posedge clk) begin
        if (rst) begin
            Status      <= {9'd0, 1'd1, 6'd0, 8'd0, 6'd0, 1'd0, 1'd0};
            Count       <= 32'h0;
            Cause       <= 32'd0;
            Index       <= 32'd0;
            EntryHi     <= 32'h0;
            Config      <= {1'b1, 15'd0, 1'b0, 2'd0, 3'd0, 3'd1, 4'd0, 3'd2};   // kseg0 3'd3=cached, 3'd2=uncached
            Config1     <= {1'b0, 6'd16, 3'd2, 3'd3, 3'd1, 3'd2, 3'd3, 3'd1, 7'd0};
        end else begin
            Count           <= Count + 32'h1;
            Cause[15:10]    <= {Cause[30] | interrupt[5], interrupt[4: 0]};

            if (Compare != 32'h0 && Count[32:1] == Compare)
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

            if (w_cp0_entryhi) begin
                EntryHi[31:13]  <= w_cp0_entryhi[31:13];
            end

            if (w_cp0_tlbp_ena) begin
                Index       <= w_cp0_Index;
            end

            if (w_cp0_tlbr_ena) begin
                EntryHi     <= w_cp0_EntryHi;
                EntryLo0    <= w_cp0_EntryLo0;
                EntryLo1    <= w_cp0_EntryLo1;
            end

            if (w_ena) begin
                case (w_addr)
                {5'd9, 3'd0}: begin
                    Count           <= {w_data, 1'b0};    
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
                    // if (~w_cp0_update_ena)
                    EPC             <= w_data;
                end

                {5'd0, 3'd0}: begin
                    Index           <= w_data[3 :0];
                end

                {5'd2, 3'd0}: begin
                    EntryLo0        <= {6'h0, w_data[25:0]};
                end

                {5'd3, 3'd0}: begin
                    EntryLo1        <= {6'h0, w_data[25:0]};
                end

                {5'd10, 3'd0}: begin
                    EntryHi         <= {w_data[31:13], 5'h0, w_data[7:0]};
                end

                {5'd16, 3'd0}: begin
                    Config[2:0]     <= w_data[2:0];
                end

                default: begin
                    
                end
                endcase
            end           
        end
    end

    always @(*) begin
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

        {5'd0, 3'd0}: begin
            r_data      = Index;
        end

        {5'd2, 3'd0}: begin
            r_data      = EntryLo0;
        end

        {5'd3, 3'd0}: begin
            r_data      = EntryLo1;
        end

        {5'd10, 3'd0}: begin
            r_data       = EntryHi; 
        end

        {5'd16, 3'd0}: begin
            r_data      = Config;
        end

        {5'd16, 3'd1}: begin
            r_data      = Config1;
        end

        default: begin
            r_data      = 32'd0;
        end
        endcase
    end
endmodule