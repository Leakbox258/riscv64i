module PC (
    input clk,
    input rst,

    input EnWrite,

    input  [63:0] wdata,
    output [63:0] rdata
);

  logic [31:0] cycle;

  /* verilator public_module */
  logic [63:0] pc;

  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= 64'h80000000;
    end else if (EnWrite) begin
      pc <= wdata;
    end

    if (rst) begin
      cycle <= 32'b0;
    end else begin
      cycle <= cycle + 1;
    end
  end

  assign rdata = pc;

  /// display
  always_ff @(posedge clk) begin
    $strobe("PC: Cycle %0d, Current PC: 0x%h, Next PC: 0x%h, WriteEn %d", cycle, pc, wdata,
            EnWrite);
  end

endmodule
