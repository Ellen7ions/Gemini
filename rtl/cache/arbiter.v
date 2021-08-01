`timescale 1ns / 1ps

module arbiter (
    input   wire [31:0] i_araddr,
    input   wire [1 :0] i_arburst,
    input   wire [7 :0] i_arlen,
    input   wire        i_arvalid,
    output  wire        i_arready,
    output  wire [31:0] i_rdata,
    output  wire        i_rlast,
    output  wire        i_rvalid,
    input   wire        i_rready,

    input   wire [31:0] d_araddr,
    input   wire [7 :0] d_arlen,
    input   wire [1 :0] d_arburst,
    input   wire [2 :0] d_arsize,
    input   wire        d_arvalid,
    output  wire        d_arready,
    output  wire [31:0] d_rdata,
    output  wire        d_rlast,
    output  wire        d_rvalid,
    input   wire        d_rready,
    input   wire [31:0] d_awaddr,
    input   wire [7 :0] d_awlen,
    input   wire [1 :0] d_awburst,
    input   wire [2 :0] d_awsize,
    input   wire        d_awvalid,
    output  wire        d_awready,
    input   wire [31:0] d_wdata,
    input   wire [3 :0] d_wstrb,
    input   wire        d_wlast,
    input   wire        d_wvalid,
    output  wire        d_wready,
    output  wire        d_bvalid,
    input   wire        d_bready,

    output  wire [3 :0] arid,
    output  wire [31:0] araddr,
    output  wire [3 :0] arlen,
    output  wire [2 :0] arsize,
    output  wire [1 :0] arburst,
    output  wire [1 :0] arlock,
    output  wire [3 :0] arcache,
    output  wire [2 :0] arprot,
    output  wire        arvalid,
    input   wire        arready,
    input   wire [3 :0] rid,
    input   wire [31:0] rdata,
    input   wire [1 :0] rresp,
    input   wire        rlast,
    input   wire        rvalid,
    output  wire        rready,
    output  wire [3 :0] awid,
    output  wire [31:0] awaddr,
    output  wire [3 :0] awlen,
    output  wire [2 :0] awsize,
    output  wire [1 :0] awburst,
    output  wire [1 :0] awlock,
    output  wire [3 :0] awcache,
    output  wire [2 :0] awprot,
    output  wire        awvalid,
    input   wire        awready,
    output  wire [3 :0] wid,
    output  wire [31:0] wdata,
    output  wire [3 :0] wstrb,
    output  wire        wlast,
    output  wire        wvalid,
    input   wire        wready,
    input   wire [3 :0] bid,
    input   wire [1 :0] bresp,
    input   wire        bvalid,
    output  wire        bready
);

    wire    raddr_sel;
    assign  raddr_sel = ~i_arvalid & d_arvalid;

    wire    rdata_sel;
    assign  rdata_sel   = rid[0];

    assign  i_arready   = arready & ~raddr_sel;
    assign  i_rdata     = ~rdata_sel ? rdata : 32'h0;
    assign  i_rlast     = ~rdata_sel ? rlast : 1'b0;
    assign  i_rvalid    = ~rdata_sel ? rvalid: 1'b0;

    assign  d_arready   = arready & raddr_sel;
    assign  d_rdata     = rdata_sel ? rdata : 32'h0;
    assign  d_rlast     = rdata_sel ? rlast : 1'b0;
    assign  d_rvalid    = rdata_sel ? rvalid: 1'b0;

    assign  arid        = {3'h0, raddr_sel};
    assign  araddr      = raddr_sel ? d_araddr  : i_araddr;
    assign  arlen       = raddr_sel ? d_arlen[3:0]   : i_arlen[3:0];
    assign  arsize      = raddr_sel ? d_arsize  : 2'b10;
    assign  arburst     = raddr_sel ? d_arburst : i_arburst;
    assign  arlock      = 2'h0;
    assign  arcache     = 4'h0;
    assign  arprot      = 3'h0;
    assign  arvalid     = raddr_sel ? d_arvalid : i_arvalid;

    assign  rready      = rdata_sel ? d_rready  : i_rready;

    assign  awid        = 4'd0;
    assign  awaddr      = d_awaddr;
    assign  awlen       = d_awlen[3:0];
    assign  awsize      = d_awsize;
    assign  awburst     = d_awburst;
    assign  awlock      = 2'd0;
    assign  awcache     = 4'd0;
    assign  awprot      = 3'd0;
    assign  awvalid     = d_awvalid;
    assign  wid         = 4'd0;
    assign  wdata       = d_wdata;
    assign  wstrb       = d_wstrb;
    assign  wlast       = d_wlast;
    assign  wvalid      = d_wvalid;
    assign  bready      = d_bready;
    assign  d_awready   = awready;
    assign  d_wready    = wready;
    assign  d_bvalid    = bvalid;

endmodule