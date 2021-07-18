`timescale 1ns/1ps  

module tb_write_axi_buffer ();
    reg clk;
    reg rst;

    localparam LINE_SIZE = 8;

    reg                     en;
    reg                     addr;
    reg [32*LINE_SIZE-1:0]  data;
    wire                    empty;

    initial begin
        repeat (300) begin
            #5 clk = 1'b1;
            #5 clk = 1'b0;
        end
    end

    wire [3 :0] awid;
    wire [31:0] awaddr;
    wire [7 :0] awlen;
    wire [2 :0] awsize;
    wire [1 :0] awburst;
    wire        awvalid;
    wire        awready;
    wire [31:0] wdata;
    wire [3 :0] wstrb;
    wire        wlast;
    wire        wvalid;
    wire        wready;
    wire [3 :0] arid;
    reg  [31:0] araddr;
    reg  [7 :0] arlen;
    reg  [2 :0] arsize;
    reg  [1 :0] arburst;
    reg         arvalid;
    wire        arready;
    wire [3 :0] rid;
    wire [31:0] rdata;
    wire [1 :0] rresp;
    wire        rlast;
    wire        rvalid;
    reg         rready;
    wire [3 :0] bid;
    wire [1 :0] bresp;
    wire        bvalid;
    wire        bready;

    write_axi_buffer #(LINE_SIZE) write_axi_buffer0 (
        .clk            (clk        ),
        .rst            (rst        ),

        .en             (en         ),
        .addr           (addr       ),
        .data           (data       ),
        .empty          (empty      ),

        .axi_awaddr     (awaddr     ),
        .axi_awlen      (awlen      ),
        .axi_awsize     (awsize     ),
        .axi_awvalid    (awvalid    ),
        .axi_awready    (awready    ),
        .axi_wdata      (wdata      ),
        .axi_wstrb      (wstrb      ),
        .axi_wlast      (wlast      ),
        .axi_wvalid     (wvalid     ),
        .axi_wready     (wready     ),
        .axi_bvalid     (bvalid     ),
        .axi_bready     (bready     )
    );

    inst_ram axi_i_ram (
        .rsta_busy      (),
        .rstb_busy      (),
        .s_aclk         (clk    ),
        .s_aresetn      (~rst   ),

        .s_axi_awid     (4'h0       ),
        .s_axi_awaddr   (awaddr     ),
        .s_axi_awlen    (awlen      ),
        .s_axi_awsize   (awsize     ),
        .s_axi_awburst  (2'b01      ),
        .s_axi_awvalid  (awvalid    ),
        .s_axi_awready  (awready    ),

        .s_axi_wdata    (wdata      ),
        .s_axi_wstrb    (wstrb      ),
        .s_axi_wlast    (wlast      ),
        .s_axi_wvalid   (wvalid     ),
        .s_axi_wready   (wready     ),

        .s_axi_bid      (),
        .s_axi_bresp    (bresp      ),
        .s_axi_bvalid   (bvalid     ),
        .s_axi_bready   (bready     ),
        
        .s_axi_arid     (),
        .s_axi_araddr   (araddr     ),
        .s_axi_arlen    (arlen      ),
        .s_axi_arsize   (arsize     ),
        .s_axi_arburst  (arburst    ),
        .s_axi_arvalid  (arvalid    ),
        .s_axi_arready  (arready    ),
        
        .s_axi_rid      (),
        .s_axi_rdata    (rdata      ),
        .s_axi_rresp    (rresp      ),
        .s_axi_rlast    (rlast      ),
        .s_axi_rvalid   (rvalid     ),
        .s_axi_rready   (rready     ) 
    );

    initial begin
        rst = 1'b1;
        araddr  = 32'h0;
        arlen   = 8'h0;
        arsize  = 3'h0;
        arburst = 2'h0;
        arvalid = 0;
        rready  = 0;
        #100 rst = 1'b0;
        #100 begin
            en = 1'b1;
            addr = 32'hbfc0_0000;
            data = {
                8'h1,
                8'h2,
                8'h3,
                8'h4,
                8'h5,
                8'h6,
                8'h7,
                8'h8
            };
        end
        #10 begin
            en = 1'b0;
        end

        #200 begin
            araddr      = 32'hbfc0_0000;
            arlen       = LINE_SIZE / 4 - 1;
            arsize      = 3'b010;
            arburst     = 2'b01;
            arvalid     = 1'b1;
            rready      = 1'b1;
        end
    end
endmodule