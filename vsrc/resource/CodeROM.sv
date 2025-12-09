module CodeROM #(
    ADDR_WIDTH = 64,
    DATA_WIDTH = 32,
    ROM_SIZE   = 12
) (
    input [ADDR_WIDTH-1:0] addr_i,
    output logic [DATA_WIDTH-1:0] data_o,
    output logic illegal_access_o
);

  /* verilator public_module */
  logic [DATA_WIDTH-1:0] rom_[2**ROM_SIZE-1:0];

  initial begin
    $readmemh("build/app.hex", rom_);
  end

  always_comb begin
    if (addr_i[1:0] == 2'b0) begin
      illegal_access_o = 0;
      data_o = rom_[addr_i[ROM_SIZE-1:0]/4];
    end else begin
      illegal_access_o = 1;  // unalign
      data_o = 0;
    end
  end

endmodule
