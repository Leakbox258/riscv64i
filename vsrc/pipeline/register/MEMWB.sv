`include "pipeline_pkg.sv"

module MEMWB
  import pipeline_pkg::*;
(
    input clk_i,
    input rst_i,

    input [DATA_WIDTH-1:0] WB_Data,
    input Mem_REn,

    input  MEMWB_Pipe_In_t  data_i,
    output MEMWB_Pipe_Out_t data_o
);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      data_o <= '0;
    end else begin
      data_o.PC <= data_i.PC;
      data_o.PC_Next <= data_i.PC_Next;
      data_o.RD_Addr <= data_i.RD_Addr;
      data_o.Reg_WEn <= data_i.Reg_WEn;
      data_o.enable <= data_i.enable;

      data_o.WB_Data <= WB_Data;
      data_o.Mem_REn <= Mem_REn;
    end
  end

endmodule
