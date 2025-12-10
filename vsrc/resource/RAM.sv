module RAM #(
    parameter DATA_WIDTH = 64,
    parameter RAM_SIZE   = 16
) (
    input logic                  clk,
    input logic [  RAM_SIZE-1:0] addr_i,
    input logic                  ewr_i,
    input logic [DATA_WIDTH-1:0] data_i,
    input logic [           2:0] wid_i,

    output reg [DATA_WIDTH-1:0] data_o
);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 0, Read = 1;

  /* verilator public_module */
  reg [DATA_WIDTH- 1 : 0] ram_[2**RAM_SIZE - 1:0];

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

  always_ff @(posedge clk) begin

    if (ewr_i == Write) begin
      case (wid_i)
        MEM_B:   ram_[addr_i][7:0] <= data_i[7:0];
        MEM_H:   ram_[addr_i][15:0] <= data_i[15:0];
        MEM_W:   ram_[addr_i][31:0] <= data_i[31:0];
        MEM_D:   ram_[addr_i] <= data_i;
        default: ;
      endcase
    end

    if (ewr_i == Read) begin
      case (wid_i)
        MEM_B:   data_o <= sext_8(ram_[addr_i][7:0]);
        MEM_H:   data_o <= sext_16(ram_[addr_i][15:0]);
        MEM_W:   data_o <= sext_32(ram_[addr_i][31:0]);
        MEM_D:   data_o <= ram_[addr_i];
        MEM_BU:  data_o <= zext_8(ram_[addr_i][7:0]);
        MEM_HU:  data_o <= zext_16(ram_[addr_i][15:0]);
        MEM_WU:  data_o <= zext_32(ram_[addr_i][31:0]);
        default: data_o <= '0;
      endcase
    end

  end

endmodule
