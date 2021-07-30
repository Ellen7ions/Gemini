`timescale 1ns / 1ps

module branch_predictor #(
    parameter BHT_LINE = 256,
    parameter BHT_SIZE = 8,
    parameter PHT_LINE = 256
) (
    input   wire        clk,
    input   wire        rst,

    input   wire        ex_stall,

    input   wire [31:0] pc,
    input   wire [31:0] pc_plus4,

    input   wire [31:0] ex_pc,
    input   wire        ex_is_jmp,
    input   wire        ex_act_taken,
    input   wire [31:0] ex_act_target,
    input   wire        ex_pred_taken,
    input   wire [31:0] ex_pred_target,

    output  wire        pred_taken_1,
    output  wire [31:0] pred_target_1,
    output  wire        pred_taken_2,
    output  wire [31:0] pred_target_2
);
    localparam [1:0] SNT = 2'b00;
    localparam [1:0] WNT = 2'b01;
    localparam [1:0] WT  = 2'b10;
    localparam [1:0] ST  = 2'b11;

    // PHT
    reg [        1 :0]          pht[PHT_LINE-1:0];
    // BTB
    reg [PHT_LINE-1:0]          valid;
    reg [        31:0]          target[PHT_LINE-1:0];
    reg [        21:0]          tag[PHT_LINE-1:0];

    integer i;
    initial begin
        for (i = 0; i < PHT_LINE; i = i + 1) begin
            pht[i]      = 2'h0;
            target[i]   = 32'h0;
            tag[i]      = 22'h0;
        end
    end

    wire [$clog2(PHT_LINE)-1:0] index_1;
    wire [                21:0] tag_1;
    wire [$clog2(PHT_LINE)-1:0] index_2;
    wire [                21:0] tag_2;
    wire                        hit_1;
    wire                        hit_2;
    wire [1                 :0] pht_val_1;
    wire [1                 :0] pht_val_2;
    wire [$clog2(PHT_LINE)-1:0] ex_index;
    wire [1                 :0] ex_pht_val;

    assign index_1  = pc[9:2];
    assign tag_1    = pc[31:10];

    assign index_2  = pc_plus4[9:2];
    assign tag_2    = pc[31:10];
    
    assign hit_1    = valid[index_1] & (tag[index_1] == tag_1);
    assign hit_2    = valid[index_2] & (tag[index_2] == tag_2);

    assign pht_val_1        = pht[index_1];
    assign pht_val_2        = pht[index_2];
    
    assign pred_taken_1     = pht_val_1[1] & hit_1;
    assign pred_taken_2     = pht_val_2[1] & hit_2;
    assign pred_target_1    = target[index_1]; 
    assign pred_target_2    = target[index_2];

    // update
    
    assign ex_index    = ex_pc[9:2];
    assign ex_pht_val  = pht[ex_index];

    always @(posedge clk) begin
        if (rst) begin
            valid   <= {PHT_LINE{1'b0}};
        end else if (ex_is_jmp & ex_act_taken) begin
            valid   [ex_index]  <= 1'b1;
            tag     [ex_index]  <= ex_pc[31:10];
            target  [ex_index]  <= ex_act_target;
        end
    end

    always @(posedge clk ) begin
        if (rst) begin
            
        end else if (~ex_stall) begin
            case (ex_pht_val)
            SNT : begin
                if (ex_act_taken)
                    pht[ex_index]   <= WNT;
            end
            WNT : begin
                if (ex_act_taken)
                    pht[ex_index]   <= WT;
                else
                    pht[ex_index]   <= SNT;
            end
            WT  : begin
                if (ex_act_taken)
                    pht[ex_index]   <= ST;
                else
                    pht[ex_index]   <= WNT;
            end
            ST  : begin
                if (~ex_act_taken)
                    pht[ex_index]   <= WT;
            end
            default: begin

            end 
            endcase
        end
    end
endmodule