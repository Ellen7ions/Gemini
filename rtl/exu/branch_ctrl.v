`timescale 1ns / 1ps

`include "../idu/id_def.v"
`include "branch_def.v"

module branch_ctrl (
    // input   wire [28:0] id1_op_codes,
    // input   wire [28:0] id1_func_codes,
    input   wire [3:0]  id2_branch_sel,
    input   wire        id2_is_branch,
    input   wire        id2_is_j_imme,
    input   wire        id2_is_jr,
    input   wire [31:0] id2_rs_data,
    input   wire [31:0] id2_rt_data,

    output  wire        take_branch,
    output  wire        take_j_imme,
    output  wire        take_jr,
    output  wire        flush_req
);
    // wire beq_check      = $signed(id2_rs_data) == $signed(id2_rt_data);
    // wire bne_check      = $signed(id2_rs_data) != $signed(id2_rt_data);
    // wire bgez_check     = $signed(id2_rs_data) >= $signed(32'h0      );
    // wire bgtz_check     = $signed(id2_rs_data) >  $signed(32'h0      );
    // wire blez_check     = $signed(id2_rs_data) <= $signed(32'h0      );
    // wire bltz_check     = $signed(id2_rs_data) <  $signed(32'h0      );

    wire beq_check      = !(id2_rs_data ^ id2_rt_data);
    wire bne_check      = |(id2_rs_data ^ id2_rt_data);
    wire bgez_check     = ~id2_rs_data[31];
    wire bgtz_check     = ~id2_rs_data[31] & |(id2_rs_data[30:0]);
    wire blez_check     = id2_rs_data[31] | !(|id2_rs_data);
    wire bltz_check     = id2_rs_data[31];

    assign take_branch  =
            id2_is_branch & (
                (!(id2_branch_sel ^ `BRANCH_SEL_BEQ     )) & (beq_check  )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BNE     )) & (bne_check  )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BGEZ    )) & (bgez_check )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BGTZ    )) & (bgtz_check )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BLEZ    )) & (blez_check )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BLTZ    )) & (bltz_check )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BGEZAL  )) & (bgez_check )    |
                (!(id2_branch_sel ^ `BRANCH_SEL_BLTZAL  )) & (bltz_check )    
            );
    
    assign take_j_imme  = id2_is_j_imme;
    
    assign take_jr      = id2_is_jr;

    assign flush_req    =
            take_jr | take_j_imme | take_branch;
endmodule