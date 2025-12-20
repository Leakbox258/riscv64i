module riscv64i #(
    DATA_WIDTH = 64,
    INST_WIDTH = 32
) (
    input clk,
    input rst,

    output [6:0] seg0,
    output [6:0] seg1,
    output [6:0] seg2,
    output [6:0] seg3,
    output [6:0] seg4,
    output [6:0] seg5,
    output [6:0] seg6,
    output [6:0] seg7
);
  /* Interrupt code, which will display on the segs with 3 horizon lines */

  parameter
  // FetchError = 0, 
  // DecodeError = 1,
  ECALL = 3, EBREAK = 4;
  parameter Anormaly = 2;

  logic [7:0] exception;
  logic [DATA_WIDTH-1:0] pc, new_pc;

  /* verilator public_module */
  PC Pc (
      .clk_i(clk),
      .ewrite_i(state == NORMAL),
      .rst_i(rst),
      .data_i(new_pc),
      .pc_o(pc)
  );

  /* verilator public_module */
  CPU Cpu (
      .clk_i(clk),
      .rst_i(rst),
      .pc_i (pc),

      .new_pc_o(new_pc),
      .exceptions_o(exception)
  );

  wire [7:0] segs[7:0];
  Display display (
      .clk_i(clk),
      .rst_i(rst),
      .display_i(pc[INST_WIDTH-1:0]),
      .segs_reg(segs)
  );

  assign seg0 = segs[0][6:0];
  assign seg1 = segs[1][6:0];
  assign seg2 = segs[2][6:0];
  assign seg3 = segs[3][6:0];
  assign seg4 = segs[4][6:0];
  assign seg5 = segs[5][6:0];
  assign seg6 = segs[6][6:0];
  assign seg7 = segs[7][6:0];

  /* monitor state */
  parameter RST = 0, NORMAL = 1, HALT = 2, ERROR = 3;

  reg [2:0] state, nstate;

  always_comb begin
    if (exception[Anormaly:0] != {Anormaly + 1{1'b0}}) begin
      nstate = ERROR;
    end else if (exception[ECALL]) begin
      /// TODO: handle traps
      nstate = HALT;
    end else if (exception[EBREAK]) begin
      nstate = HALT;
    end else begin
      nstate = NORMAL;
    end
  end

  /// Display
  always_ff @(posedge clk) begin
    $strobe("Verilator: Exception code: %08b", exception);
  end


  always_ff @(posedge clk) begin
    if (rst) begin
      state <= RST;  // meanwhile reset PC to 0x80000000
    end else begin
      state <= nstate;
    end
  end

endmodule
