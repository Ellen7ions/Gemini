`timescale 1ns / 1ps

module b_predictor #(
    parameter   BHT_NUM     = 1024,
    parameter   BHT_WIDTH   = 6,
    parameter   PHT_NUM     = 64,
    parameter   PHT_WIDTH   = 2
) (
    input   wire        clk, 
    input   wire        rst,
    input   wire [31:0] pc,
    output  wire        pred_taken,
    output  wire [31:0] pred_target,

    input   wire        update,
    input   wire [31:0] update_pc,
    input   wire        act_taken,
    input   wire [31:0] act_target
);

    wire [$clog2(BHT_NUM)-1:0]  bht_raddr;
    wire [BHT_WIDTH      -1:0]  bht_rdata;
    wire [$clog2(BHT_NUM)-1:0]  bht_waddr;
    wire                        bht_wen;
    wire                        bht_wdata;
    wire [BHT_WIDTH      -1:0]  bht_wrdata;

    wire [$clog2(PHT_NUM)-1:0]  pht_raddr;
    wire [PHT_WIDTH      -1:0]  pht_rdata;
    wire [$clog2(PHT_NUM)-1:0]  pht_waddr;
    wire                        pht_wen;
    wire [PHT_WIDTH      -1:0]  pht_wdata;
    wire [PHT_WIDTH      -1:0]  pht_wrdata;

    BHT #(
        .LINE_NUM   (BHT_NUM),
        .WIDTH      (BHT_WIDTH)
    ) bht0 (
        .clk        (clk        ),
        .rst        (rst        ),
        .r_addr     (bht_raddr  ),
        .rdata      (bht_rdata  ),
        .w_addr     (bht_waddr  ),
        .wen        (bht_wen    ),
        .wdata      (bht_wdata  ),
        .wrdata     (bht_wrdata )
    );

    PHT #(
        .LINE_NUM   (PHT_NUM),
        .WIDTH      (PHT_WIDTH)
    )  pht0 (
        .clk        (clk        ),
        .rst        (rst        ),
        .r_addr     (pht_raddr  ),
        .rdata      (pht_rdata  ),
        .w_addr     (pht_waddr  ),
        .wen        (pht_wen    ),
        .wdata      (pht_wdata  ),
        .wrdata     (pht_wrdata )
    );

    wire [1:0]  pht_next_state;
    wire        pht_taken;
    pred_fsm pred_fsm0 (
        .clk        (clk            ),
        .if_taken   (act_taken      ),
        .cur_state  (pht_wrdata     ),
        .next_state (pht_next_state )
    );

    // predict
    assign bht_raddr= pc[12:3];
    assign pht_raddr= bht_rdata ^ pc[12:7];
    assign pht_taken= pht_rdata[1];

    // update PHT and BHT
    assign bht_wen  = 1'b1;
    assign bht_waddr= update_pc[12:3];
    assign bht_wdata= act_taken;

    assign pht_wen  = update;
    assign pht_waddr= bht_wrdata ^ update_pc[12:7];
    assign pht_wdata= pht_next_state;

    // BTB
    wire        btb_miss;
    wire [31:0] btb_pred_target;
    BTB btb0 (
        .clk            (clk                ),
        .pc             (pc                 ),
        .btb_miss       (btb_miss           ),
        .pred_pc        (btb_pred_target    ),
        
        .wen            (act_taken          ),
        .update_pc      (update_pc          ),
        .update_target  (act_target         )
    );

    assign pred_taken   = pht_taken & ~btb_miss;
    assign pred_target  = btb_pred_target;

endmodule