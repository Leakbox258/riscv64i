module GPR #(
    DATA_WIDTH = 64,
    RF_SIZE = 5
) (
    input clk,
    input [RF_SIZE-1:0] rs1_i,  // register read 1
    input [RF_SIZE-1:0] rs2_i,  // register read 2
    input [RF_SIZE-1:0] rd_i,  // register write
    input write_enable_i,
    input [DATA_WIDTH-1:0] data_i,

    output reg [DATA_WIDTH-1:0] rs1_data_o,
    output reg [DATA_WIDTH-1:0] rs2_data_o
);

  reg [DATA_WIDTH-1:0] _gpr[2**RF_SIZE-1:0];

  always @(posedge clk) begin

    if (write_enable_i && rd_i != 0) _gpr[rd_i] <= data_i;

    $strobe("read x%d: %h and x%d: %h, write in x%d: %h", rs1_i, _gpr[rs1_i], rs2_i, _gpr[rs2_i],
            rd_i, data_i);
  end

  always @(*) begin
    rs1_data_o = rs1_i != 0 ? _gpr[rs1_i] : 0;
    rs2_data_o = rs2_i != 0 ? _gpr[rs2_i] : 0;
  end


endmodule
