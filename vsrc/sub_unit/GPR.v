module GPR #(
    DATA_LEN = 64,
    RF_SIZE  = 5
) (
    input clk,
    input [RF_SIZE-1:0] rs1_i,  // register read 1
    input [RF_SIZE-1:0] rs2_i,  // register read 2
    input [RF_SIZE-1:0] rd_i,  // register write
    input write_enable_i,
    input [DATA_LEN-1:0] data_i,

    output reg [DATA_LEN-1:0] rs1_data_o,
    output reg [DATA_LEN-1:0] rs2_data_o
);

  reg [DATA_LEN-1:0] gpr[2**RF_SIZE-1:0];

  always @(posedge clk) begin
    if (write_enable_i && rd_i != 0) gpr[rd_i] <= data_i;

    if (rs1_i != 0) rs1_data_o <= gpr[rs1_i];
    if (rs2_i != 0) rs2_data_o <= gpr[rs2_i];
  end

endmodule
