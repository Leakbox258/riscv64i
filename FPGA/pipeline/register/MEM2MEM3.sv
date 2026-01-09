`include "pipeline_pkg.sv"

module MEM2MEM3
  import pipeline_pkg::*;
(
    input clk,
    input rst,

    input MEM1MEM2_Pipe_t wdata,
    input [DATA_WIDTH-1:0] wMemRead,

    output MEM2MEM3_Pipe_t rdata
);


  MEM2MEM3_Pipe_t next_data;

  always_comb begin
    if (rst) begin
      next_data = 0;
    end else begin
      next_data.PC = wdata.PC;
      next_data.PC_Next = wdata.PC_Next;
      next_data.RD_Addr = wdata.RD_Addr;
      next_data.ALU_Result = wdata.ALU_Result;
      next_data.Reg_WEn = wdata.Reg_WEn;
      next_data.Mem_REn = wdata.Mem_REn;
      next_data.enable = wdata.enable;
      next_data.MemRead = wMemRead;
    end
  end

  always_ff @(posedge clk) begin
    rdata <= next_data;
  end

endmodule
