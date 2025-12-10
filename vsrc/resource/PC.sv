module PC (
    input clk_i,
    input rst_i,

    input ewrite_i,

    input  [63:0] data_i,
    output [63:0] pc_o
);

  logic [31:0] cycle;

  /* verilator public_module */
  logic [63:0] pc;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc <= 64'h80000000;
    end else if (ewrite_i) begin
      pc <= data_i;
    end

    if (rst_i) begin
      cycle <= '0;
    end else begin
      cycle <= cycle + 1;
    end
  end

  assign pc_o = pc;

  /// display
  always_ff @(posedge clk_i) begin
    $strobe("Verilator: Cycle %0d, Current PC: 0x%h, Next PC: 0x%h, WriteEn %d", cycle, pc, data_i,
            ewrite_i);
  end

endmodule
