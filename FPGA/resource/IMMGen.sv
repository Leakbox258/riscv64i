`include "utils_pkg.sv"

module IMMGen
  import utils_pkg::*;
(
    input [31:0] rinst,
    output logic [DATA_WIDTH-1:0] imme
);

  /* Instruction Type */
  // Rty = 7'h33, 
  // R64ty = 7'h3b,
  parameter
			Ity = 7'h13, 
			Load = 7'h03,
			Store = 7'h23, 
			Branch = 7'h63, 
			Jalr = 7'h67, 
			Jal = 7'h6f, 
			Auipc = 7'h17, 
			Lui = 7'h37, 
			I64ty = 7'h1b;

  // Env = 7'h73, // TODO: trap code

  wire [6:0] opcode;
  assign opcode = rinst[6:0];

  always_comb begin
    case (opcode)
      Ity: begin
        imme = sext_12(rinst[31:20]);
      end
      I64ty: begin
        imme = sext_12(rinst[31:20]);
      end
      Load: begin
        imme = sext_12(rinst[31:20]);
      end
      Store: begin
        imme = sext_12({rinst[31:25], rinst[11:7]});
      end
      Branch: begin
        imme = sext_13({rinst[31], rinst[7], rinst[30:25], rinst[11:8]});
      end
      Jalr: begin
        imme = sext_12(rinst[31:20]);
      end
      Jal: begin  // 21
        if (rinst[31])
          imme = {
            {(DATA_WIDTH - 21) {1'b1}}, rinst[31], rinst[19:12], rinst[20], rinst[30:21], 1'b0
          };
        else
          imme = {
            {(DATA_WIDTH - 21) {1'b0}}, rinst[31], rinst[19:12], rinst[20], rinst[30:21], 1'b0
          };
      end
      Auipc: begin
        imme = sext_32({rinst[31:12], 12'b0});  // << 12
      end
      Lui: begin
        imme = sext_32({rinst[31:12], 12'b0});  // << 12
      end
      default: imme = 0;
    endcase
  end

  //   initial begin
  //     $monitor("IMMGen imme: %h", imme);
  //   end

endmodule
