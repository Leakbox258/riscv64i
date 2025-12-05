module CodeROM #(
    ADDR_WIDTH = 64,
    DATA_WIDTH = 32,
    ROM_SIZE   = 12   // 2 ** ... bytes
) (
    input clk,
    input [ADDR_WIDTH-1:0] addr_i,
    output reg [DATA_WIDTH-1:0] data_o,
    output reg illegal_access_o
);

  reg [DATA_WIDTH-1:0] _rom[2**ROM_SIZE-1:0];

  initial begin
    $readmemh("build/app.byte", _rom);
  end

  always @(posedge clk) begin
    if (addr_i[1:0] == 2'b0) begin
      illegal_access_o <= 0;
      data_o <= _rom[addr_i[ROM_SIZE-1:0]];
    end else begin
      illegal_access_o <= 1;
      data_o <= 0;
    end

  end

endmodule
