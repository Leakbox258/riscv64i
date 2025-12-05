module RAM #(
    DATA_WIDTH = 64,
    RAM_SIZE   = 16
) (
    input clk,
    input [RAM_SIZE-1:0] addr_i,
    input [1:0] access_mode_i,
    input [DATA_WIDTH-1:0] data_i,
    input [2:0] memwid_i,

    output reg [DATA_WIDTH-1:0] data_o,
    output reg illegal_access_o
);

  parameter RAM_NONE = 0, RAM_READ = 1, RAM_WRITE = 2;

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;

  reg [DATA_WIDTH- 1 : 0] _ram[2**RAM_SIZE - 1:0];

  always @(posedge clk) begin
    case (access_mode_i)
      RAM_READ: begin
        case (memwid_i)
          MEM_B: begin
            data_o <= {{DATA_WIDTH - 8{_ram[addr_i][7]}}, _ram[addr_i][7:0]};
          end
          MEM_H: begin
            data_o <= {{DATA_WIDTH - 16{_ram[addr_i][15]}}, _ram[addr_i][15:0]};
          end
          MEM_W: begin
            data_o <= {{DATA_WIDTH - 32{_ram[addr_i][31]}}, _ram[addr_i][31:0]};
          end
          MEM_D: begin
            data_o <= _ram[addr_i];
          end
          MEM_BU: begin
            data_o <= {{DATA_WIDTH - 8{1'b0}}, _ram[addr_i][7:0]};
          end
          MEM_HU: begin
            data_o <= {{DATA_WIDTH - 16{1'b0}}, _ram[addr_i][15:0]};
          end
          MEM_WU: begin
            data_o <= {{DATA_WIDTH - 32{1'b0}}, _ram[addr_i][31:0]};
          end
          default: begin
            data_o <= 0;
          end
        endcase
      end
      RAM_WRITE: begin
        case (memwid_i)
          MEM_B: begin
            data_o <= {{DATA_WIDTH - 8{_ram[addr_i][7]}}, data_i[7:0]};
            _ram[addr_i][7:0] <= data_i[7:0];
          end
          MEM_H: begin
            data_o <= {{DATA_WIDTH - 16{_ram[addr_i][15]}}, data_i[15:0]};
            _ram[addr_i][15:0] <= data_i[15:0];
          end
          MEM_W: begin
            data_o <= {{DATA_WIDTH - 32{_ram[addr_i][31]}}, data_i[31:0]};
            _ram[addr_i][31:0] <= data_i[31:0];
          end
          MEM_D: begin
            data_o <= data_i;
            _ram[addr_i] <= data_i;
          end
          default: begin
            data_o <= 0;
          end
        endcase
      end
      default: data_o <= 0;
    endcase
  end

  always @(*) begin
    if (access_mode_i == RAM_NONE) illegal_access_o = 1;
    else if (memwid_i == 3'b111) illegal_access_o = 1;
    else illegal_access_o = 0;
  end

endmodule
