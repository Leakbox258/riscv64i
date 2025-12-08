module RAM #(
    DATA_WIDTH = 64,
    RAM_SIZE   = 16
) (
    input clk,
    input [RAM_SIZE-1:0] addr_i,
    input ewr_i,
    input [DATA_WIDTH-1:0] data_i,
    input [2:0] wid_i,

    output reg [DATA_WIDTH-1:0] data_o
);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 0, Read = 1;


  reg [DATA_WIDTH- 1 : 0] _ram[2**RAM_SIZE - 1:0];

  function logic [DATA_WIDTH-1:0] sext_8([7:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 8{data[7]}}, data};
    return data_sext;
  endfunction

  function logic [DATA_WIDTH-1:0] sext_16([15:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 16{data[15]}}, data};
    return data_sext;
  endfunction

  function logic [DATA_WIDTH-1:0] sext_32([31:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 32{data[31]}}, data};
    return data_sext;
  endfunction

  function logic [DATA_WIDTH-1:0] zext_8([7:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 8{1'b0}}, data};
    return data_sext;
  endfunction

  function logic [DATA_WIDTH-1:0] zext_16([15:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 16{1'b0}}, data};
    return data_sext;
  endfunction

  function logic [DATA_WIDTH-1:0] zext_32([31:0] data);
    logic [DATA_WIDTH-1:0] data_sext;
    assign data_sext = {{DATA_WIDTH - 32{1'b0}}, data};
    return data_sext;
  endfunction

  always @(*) begin
    data_o = 0;

    /// Read / Load (Write First)
    if (ewr_i == Read) begin
      case (wid_i)
        MEM_B: begin
          data_o = sext_8(_ram[addr_i][7:0]);
        end
        MEM_H: begin
          data_o = sext_16(_ram[addr_i][15:0]);
        end
        MEM_W: begin
          data_o = sext_32(_ram[addr_i][31:0]);
        end
        MEM_D: begin
          data_o = _ram[addr_i];
        end
        MEM_BU: begin
          data_o = zext_8(_ram[addr_i][7:0]);
        end
        MEM_HU: begin
          data_o = zext_16(_ram[addr_i][15:0]);
        end
        MEM_WU: begin
          data_o = zext_32(_ram[addr_i][31:0]);
        end
        default: ;
      endcase
    end
  end

  always @(posedge clk) begin
    /// Write / Store
    if (ewr_i == Write) begin
      case (wid_i)
        MEM_B: begin
          _ram[addr_i][7:0] <= data_i[7:0];
        end
        MEM_H: begin
          _ram[addr_i][15:0] <= data_i[15:0];
        end
        MEM_W: begin
          _ram[addr_i][31:0] <= data_i[31:0];
        end
        MEM_D: begin
          _ram[addr_i] <= data_i;
        end
        default:  /* need something? */;
      endcase
    end
  end

endmodule
