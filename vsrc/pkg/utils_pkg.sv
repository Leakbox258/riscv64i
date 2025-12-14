`ifndef UTILS_PKG
`define UTILS_PKG

package utils_pkg;

  parameter DATA_WIDTH = 64;

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

endpackage

`endif
