`ifndef UTILS_PKG
`define UTILS_PKG

package utils_pkg;

  parameter DATA_WIDTH = 64;
  parameter INST_WIDTH = 32;

  function logic [DATA_WIDTH-1:0] sext_12(input logic [11:0] value);
    return {{(DATA_WIDTH - 12) {value[11]}}, value};
  endfunction

  function logic [DATA_WIDTH-1:0] sext_13(input logic [12:1] value);
    return {{(DATA_WIDTH - 13) {value[12]}}, value, 1'b0};
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
    return 32'($signed(data) >>> shift);
  endfunction

  function logic [63:0] sra_64(input logic [63:0] data, input logic [5:0] shift);
    return 64'($signed(data) >>> shift);
  endfunction

  function logic signed_slt(input logic [DATA_WIDTH-1:0] rs1, input logic [DATA_WIDTH-1:0] rs2);
    return $signed(rs1) < $signed(rs2);
  endfunction

endpackage

`endif
