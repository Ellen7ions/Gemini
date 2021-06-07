`timescale 1ns / 1ps

module Top (
    input   wire    clk,
    input   wire    rst
);
    wire        inst_ena;
    wire [31:0] inst_addr_next_pc;
    wire [31:0] inst_addr_pc;
    wire [31:0] inst_rdata_1;
    wire [31:0] inst_rdata_2;
    reg         inst_rdata_1_ok;
    reg         inst_rdata_2_ok;
    wire        i_cache_stall_req;

    wire        data_ena;
    wire [31:0] data_wea;
    wire [31:0] data_waddr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;

    //cpu
    // wire [31:0]     cpu_instr_addr;
    // wire [31:0]     cpu_instr_addr_pc;
    // wire [31:0]     cpu_instr_data;
    // wire [31:0]     cpu_instr_data2;
    // wire            cpu_instr_data_1ok;
    // wire            cpu_instr_data_2ok;
    // wire            stall_all;
    wire [3:0]      awid;
    wire [31:0]     awaddr;
    wire [7:0]      awlen;
    wire [2:0]      awsize;
    wire [1:0]      awburst;
    wire            awvalid;
    wire            awready;
    wire [31 : 0]   wdata;
    wire [3 : 0]    wstrb;
    wire            wlast;
    wire            wvalid;
    wire            wready;
    wire [3 : 0]    arid;
    wire [31 : 0]   araddr;
    wire [7 : 0]    arlen;
    wire [2 : 0]    arsize;
    wire [1 : 0]    arburst;
    wire            arvalid;
    wire            arready;
    wire [3 : 0]    rid;
    wire [31 : 0]   rdata;
    wire [1 : 0]    rresp;
    wire            rlast;
    wire            rvalid;
    wire            rready;
    wire [3 : 0]    bid;
    wire [1 : 0]    bresp;
    wire            bvalid;
    wire            bready;

    gemini cpu_core (
        .clk                (clk                ),
        .rst                (rst                ),
        .interupt           (6'b000000          ),
        .inst_ena           (inst_ena           ),
        .inst_addr_next_pc  (inst_addr_next_pc  ),
        .inst_addr_pc       (inst_addr_pc       ),
        .inst_rdata_1       (inst_rdata_1       ),
        .inst_rdata_2       (inst_rdata_2       ),
        .inst_rdata_1_ok    (inst_rdata_1_ok    ),
        .inst_rdata_2_ok    (inst_rdata_2_ok    ),

        .i_cache_stall_req  (i_cache_stall_req  ),
        .data_ena           (data_ena           ),
        .data_wea           (data_wea           ),
        .data_waddr         (data_waddr         ),
        .data_wdata         (data_wdata         ),
        .data_rdata         (data_rdata         ),
        .d_cache_stall_req  (1'b0               ),
        
        .debug_pc           (),
        .debug_w_ena        (),
        .debug_w_addr       (),
        .debug_w_data       ()
    );

    wire [31:0] inst_addr_next_pc_plus_4;
    assign inst_addr_next_pc_plus_4 = inst_addr_next_pc + 32'h4;

    // reg flag;

    // always @(posedge clk) begin
    //     if (rst) begin
    //         flag <= 1'b0;
    //     end else begin
    //         flag <= 1'b1;
    //     end
    // end
    assign i_cache_stall_req = 1'b0;
    always @(posedge clk) begin
        if (!rst) begin
            inst_rdata_1_ok <= 1'b1;
            inst_rdata_2_ok <= 1'b1;
        end else begin
            inst_rdata_1_ok <= 1'b0;
            inst_rdata_2_ok <= 1'b0;
        end
    end

    dual_inst_ram your_instance_name (
        .clka   (clk            ),    // input wire clka
        .ena    (inst_ena       ),      // input wire ena
        .wea    (4'h0           ),      // input wire [3 : 0] wea
        .addra  (inst_addr_next_pc[11:2]),  // input wire [9 : 0] addra
        .dina   (32'h0          ),    // input wire [31 : 0] dina
        .douta  (inst_rdata_1   ),  // output wire [31 : 0] douta
        .clkb   (clk            ),    // input wire clkb
        .enb    (inst_ena       ),      // input wire enb
        .web    (4'h0           ),      // input wire [3 : 0] web
        .addrb  (inst_addr_next_pc_plus_4[11:2]),  // input wire [9 : 0] addrb
        .dinb   (32'h0          ),    // input wire [31 : 0] dinb
        .doutb  (inst_rdata_2   )  // output wire [31 : 0] doutb
    );

    // i_cache_final i_cache (
    //     .clk                (clk                ),
    //     .rst                (rst                ),
    //     .cpu_instr_ena      (inst_ena           ),
    //     .cpu_instr_addr     (inst_addr_next_pc  ),
    //     .cpu_instr_addr_pc  (inst_addr_pc       ),
    //     .cpu_instr_data     (inst_rdata_1       ),
    //     .cpu_instr_data2    (inst_rdata_2       ),
    //     .cpu_instr_data_1ok (inst_rdata_1_ok    ),
    //     .cpu_instr_data_2ok (inst_rdata_2_ok    ),
    //     .stall_all          (i_cache_stall_req  ),    
    //     .awid               (awid               ),
    //     .awaddr             (awaddr             ),
    //     .awlen              (awlen              ),
    //     .awsize             (awsize             ),
    //     .awburst            (awburst            ),    
    //     .awvalid            (awvalid            ),    
    //     .awready            (awready            ),    
    //     .wdata              (wdata              ),
    //     .wstrb              (wstrb              ),
    //     .wlast              (wlast              ),
    //     .wvalid             (wvalid             ),
    //     .wready             (wready             ),
    //     .arid               (arid               ),
    //     .araddr             (araddr             ),
    //     .arlen              (arlen              ),
    //     .arsize             (arsize             ),
    //     .arburst            (arburst            ),    
    //     .arvalid            (arvalid            ),    
    //     .arready            (arready            ),    
    //     .rid                (rid                ),
    //     .rdata              (rdata              ),
    //     .rresp              (rresp              ),
    //     .rlast              (rlast              ),
    //     .rvalid             (rvalid             ),
    //     .rready             (rready             ),
    //     .bid                (bid                ),
    //     .bresp              (bresp              ),
    //     .bvalid             (bvalid             ),
    //     .bready             (bready             )
    // );

    // inst_ram your_instance_name (
    //     .rsta_busy      (),
    //     .rstb_busy      (),
    //     .s_aclk         (clk        ),
    //     .s_aresetn      (~rst       ),

    //     .s_axi_awid     (awid       ),
    //     .s_axi_awaddr   (awaddr     ),
    //     .s_axi_awlen    (awlen      ),
    //     .s_axi_awsize   (awsize     ),
    //     .s_axi_awburst  (awburst    ),
    //     .s_axi_awvalid  (awvalid    ),
    //     .s_axi_awready  (awready    ),
    //     .s_axi_wdata    (wdata      ),
    //     .s_axi_wstrb    (wstrb      ),
    //     .s_axi_wlast    (wlast      ),
    //     .s_axi_wvalid   (wvalid     ),
    //     .s_axi_wready   (wready     ),
    //     .s_axi_bid      (bid        ),
    //     .s_axi_bresp    (bresp      ),
    //     .s_axi_bvalid   (bvalid     ),
    //     .s_axi_bready   (bready     ),
    //     .s_axi_arid     (arid       ),
    //     .s_axi_araddr   (araddr     ),
    //     .s_axi_arlen    (arlen      ),
    //     .s_axi_arsize   (arsize     ),
    //     .s_axi_arburst  (arburst    ),
    //     .s_axi_arvalid  (arvalid    ),
    //     .s_axi_arready  (arready    ),
    //     .s_axi_rid      (rid        ),
    //     .s_axi_rdata    (rdata      ),
    //     .s_axi_rresp    (rresp      ),
    //     .s_axi_rlast    (rlast      ),
    //     .s_axi_rvalid   (rvalid     ),
    //     .s_axi_rready   (rready     ) 
    // );

    data_ram dr (
        .clka               (clk                ),
        .ena                (data_ena           ),
        .wea                (data_wea           ),
        .addra              (data_waddr[11:2]   ),
        .dina               (data_wdata         ),
        .douta              (data_rdata         )
    );


endmodule