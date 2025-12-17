`include "utils_pkg.sv"

module MemControl
  import utils_pkg::*;
(
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
  // FPGA IP Core
  RAM ram_ (
      .clock(clk),

      .address_a(dataAddr),
      .byteena_a(dataByteEn),
      .data_a(dataWrite),
      .rden_a(dataREn),
      .wren_a(dataWEn),

      .address_b(instAddr),
      .data_b(instWrite),
      .rden_b(instREn),
      .wren_b(instWEn),

      .q_a(dataRead),
      .q_b(instRead)
  );

  parameter IPRAM_SIZE = 16;  // byte 

  logic [12:0] dataAddr;
  logic [7:0] dataByteEn;
  logic [DATA_WIDTH-1:0] dataWrite;
  logic dataWEn, dataREn;
  logic [DATA_WIDTH-1:0] dataRead;  // output

  logic [13:0] instAddr;
  logic [INST_WIDTH-1:0] instWrite = 0;
  logic instWEn = 0, instREn;
  logic [INST_WIDTH-1:0] instRead;  // output

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 1'b0, Read = 1'b1;

  assign inst_o = instRead;

  always_comb begin
    dataWEn = 0;
    dataREn = 0;
    dataByteEn = 0;
    data_o = 0;

    dataAddr = addr_i[IPRAM_SIZE-1:3];  // select DWORD

    case (wid_i)
      MEM_B: begin
        dataByteEn = 8'b1 << addr_i[2:0];
      end
      MEM_H: begin
        dataByteEn = 8'b11 << addr_i[2:0];
      end
      MEM_W: begin
        dataByteEn = 8'h0f << addr_i[2:0];
      end
      MEM_D: begin
        dataByteEn = 8'hff;
      end
      default: ;
    endcase

    if (enwr_i == Write && En_i) begin
      dataWEn = 1;
    end

    if (enwr_i == Read && En_i) begin
      dataREn = 1;

      case (wid_i)
        MEM_B: begin
          data_o = sext_8(dataRead[7:0]);
        end
        MEM_H: begin
          data_o = sext_16(dataRead[15:0]);
        end
        MEM_W: begin
          data_o = sext_32(dataRead[31:0]);
        end
        MEM_D: begin
          data_o = dataRead;
        end
        MEM_BU: begin
          data_o = zext_8(dataRead[7:0]);
        end
        MEM_HU: begin
          data_o = zext_16(dataRead[15:0]);
        end
        MEM_WU: begin
          data_o = zext_32(dataRead[31:0]);
        end
        default: begin
          data_o = 0;
        end
      endcase
    end

  end

  /// check Execptions
  always_comb begin
    unalign_access = 1'b0;

    if (enwr_i == Write && En_i) begin
      case (wid_i)
        MEM_B:   unalign_access = 1'b0;
        MEM_H: begin
          if (addr_i[0] == 1'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_W: begin
          if (addr_i[1:0] == 2'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_D: begin
          if (addr_i[2:0] == 3'b0) unalign_access = 1'b0;
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

  //   /// Read Instrutions
  //   always_ff @(posedge clk) begin
  //     if (pc_i[1:0] == 2'b0) begin
  //       illegal_access_o <= 0;
  //       inst_o <= {ram_[pc_i+3], ram_[pc_i+2], ram_[pc_i+1], ram_[pc_i]};
  //     end else begin
  //       illegal_access_o <= 1;  // unalign
  //       inst_o <= 0;
  //     end
  //   end

  //   always_comb begin
  //     if (pc_i[1:0] == 2'b0) begin
  //       illegal_access_o = 0;
  //       inst_o = {ram_[pc_i+3], ram_[pc_i+2], ram_[pc_i+1], ram_[pc_i]};
  //     end else begin
  //       illegal_access_o = 1;  // unalign
  //       inst_o = 0;
  //     end
  //   end

endmodule
