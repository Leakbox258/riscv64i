`include "utils_pkg.sv"

module MemControl
  import utils_pkg::*;
#(
    RAM_SIZE = 16
) (
    input logic                  clk,
    input logic [DATA_WIDTH-1:0] pc_i,
    input logic [DATA_WIDTH-1:0] addr_i,
    input logic                  enwr_i,
    input logic                  En_i,
    input logic [DATA_WIDTH-1:0] data_i,
    input logic [           2:0] wid_i,

    output logic [DATA_WIDTH-1:0] data_o,
    output logic [INST_WIDTH-1:0] inst_o,
    output logic unalign_access,
    output logic illegal_access_o

);

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 1'b0, Read = 1'b1;

  /* verilator public_module */
  reg [7:0] ram_[2**(RAM_SIZE)-1:0];  // this varible here is only for simulation

  logic [RAM_SIZE-1:0] paddr;
  assign paddr = addr_i[RAM_SIZE-1:0];

  initial begin
    $readmemh("build/app.hex", ram_);
  end

  always_ff @(posedge clk) begin

    if (enwr_i == Write && En_i) begin
      case (wid_i)
        MEM_B: begin
          for (bit [RAM_SIZE-1:0] i = 0; i < 1; ++i) begin
            ram_[paddr+i] <= data_i[i*8+:8];
          end
        end
        MEM_H: begin
          if (paddr[0] == 1'b0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 2; ++i) begin
              ram_[paddr+i] <= data_i[i*8+:8];
            end
          end
        end
        MEM_W: begin
          if (paddr[1:0] == 2'b0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 4; ++i) begin
              ram_[paddr+i] <= data_i[i*8+:8];
            end
          end
        end
        MEM_D: begin
          if (paddr[2:0] == 3'b0) begin
            for (bit [RAM_SIZE-1:0] i = 0; i < 8; ++i) begin
              ram_[paddr+i] <= data_i[i*8+:8];
            end
          end
        end
        default: ;
      endcase
    end

    if (enwr_i == Read && En_i) begin
      case (wid_i)
        MEM_B: begin
          data_o <= sext_8(ram_[paddr]);
        end
        MEM_H: begin
          data_o <= sext_16({ram_[paddr+1], ram_[paddr]});
        end
        MEM_W: begin
          data_o <= sext_32({ram_[paddr+3], ram_[paddr+2], ram_[paddr+1], ram_[paddr]});
        end
        MEM_D: begin
          data_o <= {
            ram_[paddr+7],
            ram_[paddr+6],
            ram_[paddr+5],
            ram_[paddr+4],
            ram_[paddr+3],
            ram_[paddr+2],
            ram_[paddr+1],
            ram_[paddr]
          };
        end
        MEM_BU: begin
          data_o <= zext_8(ram_[paddr]);
        end
        MEM_HU: begin
          data_o <= zext_16({ram_[paddr+1], ram_[paddr]});
        end
        MEM_WU: begin
          data_o <= zext_32({ram_[paddr+3], ram_[paddr+2], ram_[paddr+1], ram_[paddr]});
        end
        default: begin
          data_o <= {DATA_WIDTH{1'b0}};
        end
      endcase
    end

  end

  always_comb begin
    unalign_access = 1'b0;

    if (enwr_i == Write && En_i) begin
      case (wid_i)
        MEM_B:   unalign_access = 1'b0;
        MEM_H: begin
          if (paddr[0] == 1'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_W: begin
          if (paddr[1:0] == 2'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_D: begin
          if (paddr[2:0] == 3'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        default: unalign_access = 1'b1;
      endcase
    end

    if (enwr_i == Read && En_i) begin
      case (wid_i)
        MEM_B:   unalign_access = 1'b0;
        MEM_H:   unalign_access = 1'b0;
        MEM_W:   unalign_access = 1'b0;
        MEM_D:   unalign_access = 1'b0;
        MEM_BU:  unalign_access = 1'b0;
        MEM_HU:  unalign_access = 1'b0;
        MEM_WU:  unalign_access = 1'b0;
        default: unalign_access = 1'b1;
      endcase
    end
  end

  logic [RAM_SIZE-1:0] pc;
  assign pc = pc_i[RAM_SIZE-1:0];

  //   always_ff @(posedge clk) begin
  //     if (pc[1:0] == 2'b0) begin
  //       illegal_access_o <= 0;
  //       inst_o <= {ram_[pc+3], ram_[pc+2], ram_[pc+1], ram_[pc]};
  //     end else begin
  //       illegal_access_o <= 1;  // unalign
  //       inst_o <= 0;
  //     end
  //   end

  always_comb begin
    if (pc[1:0] == 2'b0) begin
      illegal_access_o = 0;
      inst_o = {ram_[pc+3], ram_[pc+2], ram_[pc+1], ram_[pc]};
    end else begin
      illegal_access_o = 1;  // unalign
      inst_o = 0;
    end
  end

endmodule
