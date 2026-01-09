`include "utils_pkg.sv"

module MemControl
  import utils_pkg::*;
(
    input logic                  clk,
    input logic [DATA_WIDTH-1:0] pc,
    input logic [DATA_WIDTH-1:0] addr,
    input logic                  enwr,
    input logic                  En,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [           2:0] wid,

    output logic [DATA_WIDTH-1:0] rdata,
    output logic [INST_WIDTH-1:0] rinst,
    output logic unalign_access,
    output logic illegal_access

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
  logic instWEn = 0, instREn = 1;
  logic [INST_WIDTH-1:0] instRead;  // output

  parameter MEM_B = 3'b000, MEM_H = 3'b001, MEM_W = 3'b010,
            MEM_D = 3'b011, MEM_BU = 3'b100, MEM_HU = 3'b101 , MEM_WU = 3'b110;
  parameter Write = 1'b0, Read = 1'b1;

  always_comb begin

    dataAddr   = addr[IPRAM_SIZE-1:3];  // select DWORD
    dataByteEn = 0;
    dataWrite  = 0;

    if (enwr == Write) begin
      case (wid)
        MEM_B: begin
          dataByteEn = 8'b1 << addr[2:0];
          dataWrite  = {8{wdata[7:0]}};
        end
        MEM_H: begin
          dataByteEn = 8'b11 << addr[2:0];
          dataWrite  = {4{wdata[15:0]}};
        end
        MEM_W: begin
          dataByteEn = 8'h0f << addr[2:0];
          dataWrite  = {2{wdata[31:0]}};
        end
        MEM_D: begin
          dataByteEn = 8'hff;
          dataWrite  = wdata;
        end
        MEM_BU: begin  // read-only
          dataByteEn = 8'b1 << addr[2:0];
          dataWrite  = 0;
        end
        MEM_HU: begin  // read-only
          dataByteEn = 8'b11 << addr[2:0];
          dataWrite  = 0;
        end
        MEM_WU: begin  // read-only
          dataByteEn = 8'h0f << addr[2:0];
          dataWrite  = 0;
        end
        default: ;
      endcase
    end
  end


  always_comb begin
    dataWEn = 0;
    dataREn = 0;

    if (enwr == Write && En) begin
      dataWEn = 1;
    end

    if (enwr == Read && En) begin
      dataREn = 1;
    end
  end

  always_comb begin
    rdata = 0;

    if (enwr == Read && En) begin
      rdata = dataRead;
    end

  end

  logic [63:0] intermedia;
  always_comb begin
    intermedia = (pc - 64'h80000000) >> 2;
    instAddr = intermedia[13:0];
    illegal_access = pc[1:0] != 2'b0;
    rinst = instRead;  // delayed
  end

  /// check Execptions
  always_comb begin
    unalign_access = 1'b0;

    if (enwr == Write && En) begin
      case (wid)
        MEM_B:   unalign_access = 1'b0;
        MEM_H: begin
          if (addr[0] == 1'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_W: begin
          if (addr[1:0] == 2'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        MEM_D: begin
          if (addr[2:0] == 3'b0) unalign_access = 1'b0;
          else unalign_access = 1'b1;
        end
        default: unalign_access = 1'b1;
      endcase
    end

    if (enwr == Read && En) begin
      case (wid)
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

endmodule
