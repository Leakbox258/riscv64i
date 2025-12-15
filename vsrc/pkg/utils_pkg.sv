`ifndef UTILS_PKG
`define UTILS_PKG

package utils_pkg;

  parameter DATA_WIDTH = 64;
  parameter INST_WIDTH = 32;

  function automatic logic [DATA_WIDTH-1:0] sext_12(input logic [11:0] value);
    logic [DATA_WIDTH-1:0] sexted;
    sexted = {{(DATA_WIDTH - 12) {value[11]}}, value};
    return sexted;
  endfunction

  function automatic logic [DATA_WIDTH-1:0] sext_13(input logic [12:1] value);
    logic [DATA_WIDTH-1:0] sexted;
    sexted = {{(DATA_WIDTH - 13) {value[12]}}, value, 1'b0};
    return sexted;
  endfunction

  function logic [DATA_WIDTH-1:0] sext_8(input logic [7:0] data);
    return {{DATA_WIDTH - 8{data[7]}}, data};
  endfunction

  function logic [DATA_WIDTH-1:0] sext_16(input logic [15:0] data);
    return {{DATA_WIDTH - 16{data[15]}}, data};
  endfunction

  function logic [DATA_WIDTH-1:0] sext_32(input logic [31:0] data);
    return {{DATA_WIDTH - 32{data[31]}}, data};
  endfunction

  function logic [DATA_WIDTH-1:0] zext_8(input logic [7:0] data);
    return {{DATA_WIDTH - 8{1'b0}}, data};
  endfunction

  function logic [DATA_WIDTH-1:0] zext_16(input logic [15:0] data);
    return {{DATA_WIDTH - 16{1'b0}}, data};
  endfunction

  function logic [DATA_WIDTH-1:0] zext_32(input logic [31:0] data);
    return {{DATA_WIDTH - 32{1'b0}}, data};
  endfunction

  function logic [31:0] sra_32(input logic [31:0] data, input logic [4:0] shift);
    // $signed(data)
    logic [31:0] intermedia, fixup;
    intermedia = data >> shift;
    fixup = data[31] == '1 ? 32'hffffffff << (32 - shift) : '0;
    return intermedia + fixup;
  endfunction

  function logic [63:0] sra_64(input logic [63:0] data, input logic [5:0] shift);
    // $signed(data)
    logic [63:0] intermedia, fixup;
    intermedia = data >> shift;
    fixup = data[63] == '1 ? 64'hffffffff << (64 - shift) : '0;
    return intermedia + fixup;
  endfunction

  function logic signed_slt(input logic [DATA_WIDTH-1:0] rs1, input logic [DATA_WIDTH-1:0] rs2);
    logic [1:0] flags;
    logic [DATA_WIDTH-2:0] intermedia1, intermedia2;
    logic result;

    flags = {rs1[DATA_WIDTH-1], rs2[DATA_WIDTH-1]};
    intermedia1 = rs1[DATA_WIDTH-2:0];
    intermedia2 = rs2[DATA_WIDTH-2:0];

    case (flags)
      'b00: result = intermedia1 < intermedia2;
      'b01: result = '0;
      'b10: result = '1;
      'b11: result = intermedia1 > intermedia2;
    endcase

    return result;
  endfunction

endpackage

`endif
