`timescale 1ns / 1ps

`include "../idu/id_def.v"

module dynamic_fetch (
    input   wire        clk,
    input   wire        rst,
    input   wire        stall,
    input   wire        flush,

    input   wire        ex_stall,
    input   wire [31:0] ex_pc,
    input   wire        ex_is_jmp,
    input   wire        ex_act_taken,
    input   wire        ex_pred_taken,
    input   wire [31:0] ex_pred_target,

    input   wire        fifo_stall,
    input   wire        i_cache_stall,

    // error predict
    input   wire        flush_req,

    input   wire        pc_valid,
    input   wire [31:0] pc,
    input   wire [31:0] pc_plus4,

    input   wire [31:0] inst_1,
    input   wire        inst_ok_1,
    input   wire [31:0] inst_2,
    input   wire        inst_ok_2,

    output  reg         flush_pc_reg,
    output  reg         fetch_ena,
    output  reg  [31:0] fetch_target,

    output  wire        pred_taken_1,
    output  wire [31:0] pred_target_1,
    output  wire        pred_taken_2,
    output  wire [31:0] pred_target_2,

    output  wire        w_fifo_en_1,
    output  wire        w_fifo_en_2
);
    localparam NORMAL_STATE = 0;
    localparam FETCH_DS     = 1;
    localparam FETCH_TARGET = 2;

    reg [1:0] cur_state;
    reg [1:0] next_state;

    wire inst_is_jmp_1 = 
        (!(inst_1[31:26]    ^ `BEQ_OP_CODE      ))   |
        (!(inst_1[31:26]    ^ `BNE_OP_CODE      ))   |
        (!(inst_1[31:26]    ^ `REGIMM_OP_CODE   ))   |
        (!(inst_1[31:26]    ^ `BGTZ_OP_CODE     ))   |
        (!(inst_1[31:26]    ^ `BLEZ_OP_CODE     ))   |
        (!(inst_1[31:26]    ^ `J_OP_CODE        ))   |
        (!(inst_1[31:26]    ^ `JAL_OP_CODE      ))   |
        (!(inst_1[31:26]    ^ `SPECIAL_OP_CODE  ) & (
         !(inst_1[5 : 0]    ^ `JR_FUNCT         )  |
         !(inst_1[5 : 0]    ^ `JALR_FUNCT       )
        ));

    wire inst_is_jmp_2 = 
        (!(inst_2[31:26]    ^ `BEQ_OP_CODE      ))   |
        (!(inst_2[31:26]    ^ `BNE_OP_CODE      ))   |
        (!(inst_2[31:26]    ^ `REGIMM_OP_CODE   ))   |
        (!(inst_2[31:26]    ^ `BGTZ_OP_CODE     ))   |
        (!(inst_2[31:26]    ^ `BLEZ_OP_CODE     ))   |
        (!(inst_2[31:26]    ^ `J_OP_CODE        ))   |
        (!(inst_2[31:26]    ^ `JAL_OP_CODE      ))   |
        (!(inst_2[31:26]    ^ `SPECIAL_OP_CODE  ) & (
         !(inst_2[5 : 0]    ^ `JR_FUNCT         )  |
         !(inst_2[5 : 0]    ^ `JALR_FUNCT       )
        ));

    branch_predictor predictor0 (
        .clk            (clk            ),
        .rst            (rst            ),
        .ex_stall       (ex_stall       ),
        .pc             (pc             ),
        .pc_plus4       (pc_plus4       ),
        .ex_pc          (ex_pc          ),
        .ex_is_jmp      (ex_is_jmp      ),
        .ex_act_taken   (ex_act_taken   ),
        .ex_pred_taken  (ex_pred_taken  ),
        .ex_pred_target (ex_pred_target ),

        .pred_taken_1   (pred_taken_1   ),
        .pred_target_1  (pred_target_1  ),
        .pred_taken_2   (pred_taken_2   ),
        .pred_target_2  (pred_target_2  )
    );

    wire pred_dir_1 = pred_taken_1 & inst_is_jmp_1 & inst_ok_1;
    wire pred_dir_2 = pred_taken_2 & inst_is_jmp_2 & inst_ok_2;

    always @(posedge clk) begin
        if (rst | flush) begin
            cur_state   <= NORMAL_STATE;
        end else if (~stall) begin
            cur_state   <= next_state;
        end
    end

    reg only_ds;
    assign w_fifo_en_1 = inst_ok_1 & ~fifo_stall & ~i_cache_stall & pc_valid;
    assign w_fifo_en_2 = inst_ok_2 & ~fifo_stall & ~i_cache_stall & pc_valid & ~only_ds;

    reg [31:0] _target;
    reg [31:0] target_reg;
    always @(posedge clk) begin
        if (rst) begin
            target_reg <= 32'h0;
        end else if (~stall & (next_state == FETCH_DS)) begin
            target_reg <= _target;
        end
    end

    always @(*) begin
        flush_pc_reg    = 1'b0;
        fetch_ena       = 1'b0;
        fetch_target    = 32'h0;
        
        _target         = 32'h0;
        only_ds         = 1'b0;

        case (cur_state)
        NORMAL_STATE: begin
            if (flush_req) begin
                next_state  = NORMAL_STATE;
                fetch_ena   = 1'b1;
                fetch_target= ex_pc + 32'h8;
                flush_pc_reg= 1'b1;
            end else if (pred_dir_1 & inst_ok_2) begin
                next_state  = NORMAL_STATE;
                fetch_ena   = 1'b1;
                fetch_target= pred_target_1;
                flush_pc_reg= 1'b1;
            end else if (pred_dir_1) begin
                next_state  = FETCH_DS;
                fetch_ena   = 1'b1;
                fetch_target= pc_plus4;
                flush_pc_reg= 1'b1;
                _target     = pred_dir_1;
            end else if (pred_dir_2) begin
                next_state  = FETCH_DS;
                fetch_ena   = 1'b1;
                fetch_target= pc_plus4;
                flush_pc_reg= 1'b1;
                _target     = pred_dir_2;
            end else begin
                next_state  = NORMAL_STATE; 
            end
        end

        FETCH_DS: begin
            if (flush_req) begin
                next_state  = NORMAL_STATE;
                fetch_ena   = 1'b1;
                fetch_target= ex_pc + 32'h8;
                flush_pc_reg= 1'b1;
            end else begin
                next_state  = FETCH_TARGET;
                fetch_ena   = 1'b1;
                fetch_target= target_reg;
            end
        end

        FETCH_TARGET: begin
            if (flush_req) begin
                next_state  = NORMAL_STATE;
                fetch_ena   = 1'b1;
                fetch_target= ex_pc + 32'h8;
                flush_pc_reg= 1'b1;
            end else begin
                next_state  = NORMAL_STATE;
                only_ds     = 1'b1;
            end
        end

        default: begin
            
        end
        endcase
    end

endmodule