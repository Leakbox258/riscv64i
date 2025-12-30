module GPR #(
    DATA_WIDTH = 64,
    RF_SIZE = 5
) (
    input clk,
    input [RF_SIZE-1:0] rs1,  // register read 1
    input [RF_SIZE-1:0] rs2,  // register read 2
    input [RF_SIZE-1:0] rd,  // register write
    input write_enable,
    input [DATA_WIDTH-1:0] wdata,

    output [DATA_WIDTH-1:0] rs1_rdata,
    output [DATA_WIDTH-1:0] rs2_rdata
);

  /* verilator public_module */
  reg [DATA_WIDTH-1:0] gprs[2**RF_SIZE-1:0];

  always_ff @(posedge clk) begin

    if (write_enable && rd != 0) gprs[rd] <= wdata;

    // $strobe("read x%d: %h and x%d: %h, write in x%d: %h", rs1, gprs[rs1], rs2, gprs[rs2],
    //         rd, wdata);
  end

  /// Write First
  assign rs1_rdata = (rd == rs1 && write_enable && rd != 0) ? wdata : gprs[rs1];
  assign rs2_rdata = (rd == rs2 && write_enable && rd != 0) ? wdata : gprs[rs2];

endmodule
