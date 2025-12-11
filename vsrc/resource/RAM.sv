module RAM #(
    parameter DATA_WIDTH = 64,
    parameter RAM_SIZE   = 16
) (
    input logic                  clk,
    input logic [  RAM_SIZE-1:0] addr_i,
    input logic                  ewr_i,
    input logic [DATA_WIDTH-1:0] data_i,
    input logic [           2:0] wid_i,

    output logic [DATA_WIDTH-1:0] data_o,
    output logic unalign_access
);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 0, Read = 1;

  /* verilator public_module */
  //   reg [DATA_WIDTH- 1 : 0] ram_[2**RAM_SIZE - 1:0];
  reg [7:0] ram_[2**(RAM_SIZE)-1:0];

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
        MEM_B: begin
          for (bit [RAM_SIZE-1:0] i = 0; i < 1; ++i) begin
            ram_[addr_i+i] <= data_i[i*8+:8];
          end

        end
        MEM_H: begin
          if (addr_i[0] == '0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 2; ++i) begin
              ram_[addr_i+i] <= data_i[i*8+:8];
            end
          end
        end
        MEM_W: begin
          if (addr_i[1:0] == '0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 4; ++i) begin
              ram_[addr_i+i] <= data_i[i*8+:8];
            end
          end
        end
        MEM_D: begin
          if (addr_i[2:0] == '0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 8; ++i) begin
              ram_[addr_i+i] <= data_i[i*8+:8];
            end
          end
        end
        default: ;
      endcase
    end

    if (ewr_i == Read) begin
      case (wid_i)
        MEM_B: begin
          data_o <= sext_8(ram_[addr_i]);
        end
        MEM_H: begin
          data_o <= sext_16({ram_[addr_i+1], ram_[addr_i]});
        end
        MEM_W: begin
          data_o <= sext_32({ram_[addr_i+3], ram_[addr_i+2], ram_[addr_i+1], ram_[addr_i]});
        end
        MEM_D: begin
          for (bit [RAM_SIZE-1:0] i = 0; i < 8; ++i) begin
            data_o[i*8+:8] <= ram_[addr_i+i];
          end
        end
        MEM_BU: begin
          data_o <= zext_8(ram_[addr_i]);
        end
        MEM_HU: begin
          data_o <= zext_16({ram_[addr_i+1], ram_[addr_i]});
        end
        MEM_WU: begin
          data_o <= zext_32({ram_[addr_i+3], ram_[addr_i+2], ram_[addr_i+1], ram_[addr_i]});
        end
        default: begin
          data_o <= '0;
        end
      endcase
    end

  end

  always_comb begin
    unalign_access = '0;

    if (ewr_i == Write) begin
      case (wid_i)
        MEM_B:   unalign_access = '0;
        MEM_H: begin
          if (addr_i[0] == '0) unalign_access = '0;
          else unalign_access = '1;
        end
        MEM_W: begin
          if (addr_i[1:0] == '0) unalign_access = '0;
          else unalign_access = '1;
        end
        MEM_D: begin
          if (addr_i[2:0] == '0) unalign_access = '0;
          else unalign_access = '1;
        end
        default: unalign_access = '1;
      endcase
    end

    if (ewr_i == Read) begin
      case (wid_i)
        MEM_B:   unalign_access = '0;
        MEM_H:   unalign_access = '0;
        MEM_W:   unalign_access = '0;
        MEM_D:   unalign_access = '0;
        MEM_BU:  unalign_access = '0;
        MEM_HU:  unalign_access = '0;
        MEM_WU:  unalign_access = '0;
        default: unalign_access = '1;
      endcase
    end
  end


endmodule
