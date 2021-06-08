`timescale 1ns / 1ps

module i_fifo (
    input   wire        clk,
    input   wire        rst,
    input   wire        flush,
    input   wire        p_data_1,
    input   wire        p_data_2,
    output  wire [63:0] r_data_1,
    output  wire [63:0] r_data_2,
    output  wire        r_data_1_ok,
    output  wire        r_data_2_ok,
    output  wire        fifo_stall_req,
    input   wire        w_ena_1,
    input   wire        w_ena_2,
    input   wire [63:0] w_data_1,
    input   wire [63:0] w_data_2
);
    localparam SIZE         = 8;
    localparam INDEX        = $clog2(SIZE);

    localparam [1:0] NORMAL = 2'b00;
    localparam [1:0] WAIT_1 = 2'b01;
    localparam [1:0] WAIT_2 = 2'b10;
    reg  [1:0]  cstate;

    reg  [63:0] wait_reg_1, wait_reg_2;

    reg  [63:0] queue[SIZE-1:0];
    reg  [INDEX:0] w_ptr, r_ptr;
    wire [INDEX:0] wptr_plus_one;
    wire [INDEX:0] rptr_plus_one;
    wire left_one, full, empty;
    assign full         = (w_ptr[INDEX] ^ r_ptr[INDEX]) & (w_ptr[INDEX-1:0] == r_ptr[INDEX-1:0]);
    assign empty        = (r_ptr == w_ptr);
    assign wptr_plus_one= (w_ptr + 4'h1);
    assign rptr_plus_one= (r_ptr + 4'h1);
    assign left_one     = (wptr_plus_one[INDEX] ^ r_ptr[INDEX]) & (wptr_plus_one[INDEX-1:0] == r_ptr[INDEX-1:0]);

    assign r_data_1_ok  = ~empty & ~flush;
    assign r_data_2_ok  = ~empty & (r_ptr + 4'h1 != w_ptr) & ~flush;
    assign fifo_stall_req = 
            (full | (cstate != NORMAL)) & ~flush;

    assign r_data_1     = queue[r_ptr           [INDEX-1:0]];
    assign r_data_2     = queue[rptr_plus_one   [INDEX-1:0]];

    always @(posedge clk) begin
        if (rst || flush) begin
            w_ptr           <= {INDEX{1'b0}};
            r_ptr           <= {INDEX{1'b0}};
            cstate          <= NORMAL;
            wait_reg_1      <= 64'h0;
            wait_reg_2      <= 64'h0;
        end else begin
            // pop
            case({p_data_1, p_data_2})
            2'b10: begin
                if (r_data_1_ok) 
                    r_ptr       <= r_ptr + 5'h1;
            end

            2'b11: begin
                if (r_data_1_ok & r_data_2_ok)
                    r_ptr       <= r_ptr + 5'h2;
            end
            default: begin
                r_ptr       <= r_ptr;
            end
            endcase
            
            // append
            case(cstate)
            NORMAL: begin
                if          (full       &&  w_ena_1 &&  w_ena_2) begin
                    cstate      <= WAIT_2;

                    wait_reg_1  <= w_data_1;
                    wait_reg_2  <= w_data_2;
                end else if (full       &&  w_ena_1 && !w_ena_2) begin
                    cstate  <= WAIT_1;

                    wait_reg_1  <= w_data_1;
                end else if (left_one   &&  w_ena_1 &&  w_ena_2) begin
                    cstate  <= WAIT_1;

                    queue[w_ptr[INDEX-1:0]] <= w_data_1;
                    w_ptr   <= w_ptr + 5'h1;
                    wait_reg_1  <= w_data_2;
                end else if (!full      &&  w_ena_1 &&  w_ena_2) begin
                    cstate  <= NORMAL;

                    queue[w_ptr[INDEX-1:0]          ] <= w_data_1;
                    queue[wptr_plus_one[INDEX-1:0]  ] <= w_data_2;
                    w_ptr   <= w_ptr + 5'h2;
                end else if (!full      &&  w_ena_1 && !w_ena_2) begin
                    cstate  <= NORMAL;
                    queue[w_ptr[INDEX-1:0]          ] <= w_data_1;
                    w_ptr   <= w_ptr + 5'h1;
                end else begin
                    cstate  <= NORMAL;
                end
            end

            WAIT_1:   begin
                if (!full) begin
                    cstate                  <= NORMAL;

                    queue[w_ptr[INDEX-1:0]] <= wait_reg_1;
                    w_ptr                   <= w_ptr + 5'h1;
                end else begin  
                    cstate                  <= WAIT_1;
                end
            end

            WAIT_2:   begin
                if (left_one) begin
                    cstate                  <= WAIT_1;

                    queue[w_ptr[INDEX-1:0]] <= wait_reg_1;
                    wait_reg_1              <= wait_reg_2;
                    w_ptr                   <= w_ptr + 5'h1;
                end if (!full) begin
                    cstate                  <= NORMAL;

                    queue[w_ptr[INDEX-1:0]]         <= wait_reg_1;
                    queue[wptr_plus_one[INDEX-1:0]] <= wait_reg_2;
                    w_ptr                           <= w_ptr + 5'h2;
                end else begin  
                    cstate              <= WAIT_2;
                end
            end

            default: begin
                cstate  <= NORMAL;
            end
            endcase
        end
    end
    
endmodule