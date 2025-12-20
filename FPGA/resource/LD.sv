`include "utils_pkg.sv"

module LD
  import utils_pkg::*;
(
    input [DATA_WIDTH-1:0] data_i,
    input [2:0] wid_i,
    input [2:0] byteena_i,

    output logic [DATA_WIDTH-1:0] data_o
);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;

  logic [DATA_WIDTH-1:0] intermedia;

  always_comb begin
    intermedia = 0;
    data_o = 0;

    case (wid_i)
      MEM_B: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = sext_8(intermedia[7:0]);
      end
      MEM_H: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = sext_16(intermedia[15:0]);
      end
      MEM_W: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = sext_32(intermedia[31:0]);
      end
      MEM_D: begin
        data_o = data_i;
      end
      MEM_BU: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = zext_8(intermedia[7:0]);
      end
      MEM_HU: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = zext_16(intermedia[15:0]);
      end
      MEM_WU: begin
        intermedia = data_i >> (byteena_i * 8);
        data_o = zext_32(intermedia[31:0]);
      end
      default: ;
    endcase
  end

endmodule
