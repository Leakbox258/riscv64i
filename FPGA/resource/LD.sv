`include "utils_pkg.sv"

module LD
  import utils_pkg::*;
(
    input [DATA_WIDTH-1:0] wdata,
    input [2:0] wid_i,
    input [2:0] byteena_i,

    output logic [DATA_WIDTH-1:0] rdata
);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;

  logic [DATA_WIDTH-1:0] intermedia;

  always_comb begin
    logic [5:0] shift_amt;
    shift_amt  = {3'b0, byteena_i[2:0]} << 3;  // byteena_i * 8

    intermedia = wdata >> shift_amt;

    case (wid_i)
      MEM_B:   rdata = sext_8(intermedia[7:0]);
      MEM_H:   rdata = sext_16(intermedia[15:0]);
      MEM_W:   rdata = sext_32(intermedia[31:0]);  // sext.w
      MEM_D:   rdata = intermedia;
      MEM_BU:  rdata = zext_8(intermedia[7:0]);
      MEM_HU:  rdata = zext_16(intermedia[15:0]);
      MEM_WU:  rdata = zext_32(intermedia[31:0]);
      default: rdata = 0;
    endcase
  end

endmodule
