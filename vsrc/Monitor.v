module Monitor (
    input clk_i,
    input rst_i,

    output [7:0] seg0,
    output [7:0] seg1,
    output [7:0] seg2,
    output [7:0] seg3,
    output [7:0] seg4,
    output [7:0] seg5,
    output [7:0] seg6,
    output [7:0] seg7
);
  /* Interrupt code, which will display on the segs with 3 horizon lines */
  parameter FetchError = 0, 
            DecodeError = 1,
            MemAccessError = 2,
            UnknownBrtyError = 3,
            ECALL = 4,
            EBREAK = 5;

  parameter Anormaly = 3;
  wire [ 5:0] interrupt;

  wire [63:0] pc;
  wire [63:0] new_pc;
  PC Pc (
      .clk_i (clk_i),
      .we_i  (nstate == NORMAL),
      .rst_i (rst_i),
      .data_i(new_pc),
      .pc_o  (pc)
  );

  wire [31:0] inst;

  IFU Ifu (
      .clk(clk_i),
      .pc_i(pc),
      .inst_o(inst),
      .fecth_error_o(interrupt[0])
  );

  wire rd_enable, rs1_enable, rs2_enable;
  wire memread, memwrite;
  wire [3:0] alu_op;
  wire branch, jal, jalr, auipc;
  wire [4:0] rd, rs1, rs2;
  wire [2:0] memwid;
  wire [2:0] brty;
  wire alu_2nd_src;
  wire [63:0] imme;

  IDU Idu (
      .inst_i(inst),

      .rd_enable_o(rd_enable),
      .rs1_enable_o(rs1_enable),
      .rs2_enable_o(rs2_enable),
      .memread_o(memread),
      .memwrite_o(memwrite),
      .alu_op_o(alu_op),
      .alu_2nd_src_o(alu_2nd_src),
      .branch_o(branch),
      .jal_o(jal),
      .jalr_o(jalr),
      .auipc_o(auipc),
      //   .lui_o(),

      .rd_o(rd),
      .rs1_o(rs1),
      .rs2_o(rs2),
      .memwid_o(memwid),
      .brty_o(brty),

      .imme_o(imme),
      .decode_error_o(interrupt[1]),
      .env_interrupt_o(interrupt[5:4])
  );

  EXU Exu (
      .clk(clk_i),
      .rd_enable_i(rd_enable),
      .rs1_enable_i(rs1_enable),
      .rs2_enable_i(rs2_enable),
      .memread_i(memread),
      .memwrite_i(memwrite),
      .alu_op_i(alu_op),
      .alu_2nd_src_i(alu_2nd_src),
      .br_i(branch),
      .jal_i(jal),
      .jalr_i(jalr),
      .auipc_i(auipc),

      .rd_i (rd),
      .rs1_i(rs1),
      .rs2_i(rs2),

      .pc_i(pc),
      .imme_i(imme),
      .memwid_i(memwid),
      .brty_i(brty),

      .new_pc_o(new_pc),
      .execute_error_o(interrupt[3:2])
  );

  /* monitor state */
  parameter NORMAL = 0, HALT = 1, ERROR = 2;

  reg [2:0] state, nstate;

  always @(*) begin
    if (interrupt[Anormaly:0] != 0) begin
      nstate = ERROR;
    end else if (interrupt[ECALL]) begin
      /// TODO: handle traps
      nstate = HALT;
    end else if (interrupt[EBREAK]) begin
      nstate = HALT;
    end else begin
      nstate = NORMAL;
    end
  end

  always @(posedge clk_i) begin

    if (rst_i) begin
      state <= NORMAL;  // meanwhile reset PC to 0x80000000
    end else begin
      state <= nstate;
    end
  end

  /* Seg7 display */
  reg [7:0] segs_reg[8];
  reg [7:0] segs_combine[8];

  parameter   
            SEGNONE = ~(8'b00000000),
            SEGERROR = ~(8'b10010010),
            SEG0 = ~(8'b11111100),
            SEG1 = ~(8'b01100000),
            SEG2 = ~(8'b11011010),
            SEG3 = ~(8'b11110010),
            SEG4 = ~(8'b01100110),
            SEG5 = ~(8'b10110110),
            SEG6 = ~(8'b10111110),
            SEG7 = ~(8'b11100000),
            SEG8 = ~(8'b11111110),
			SEG9 = ~(8'b11110110),
			SEGA = ~(8'b11101110),
			SEGb = ~(8'b00111110),
			SEGC = ~(8'b10011100),
			SEGd = ~(8'b01111010),
			SEGE = ~(8'b10011110),
			SEGF = ~(8'b10001110);

  /// Board display
  assign seg0 = segs_reg[0];
  assign seg1 = segs_reg[1];
  assign seg2 = segs_reg[2];
  assign seg3 = segs_reg[3];
  assign seg4 = segs_reg[4];
  assign seg5 = segs_reg[5];
  assign seg6 = segs_reg[6];
  assign seg7 = segs_reg[7];

  function logic [7:0] get_hex_seg(input logic [3:0] val);
    case (val)
      4'h0: return SEG0;
      4'h1: return SEG1;
      4'h2: return SEG2;
      4'h3: return SEG3;
      4'h4: return SEG4;
      4'h5: return SEG5;
      4'h6: return SEG6;
      4'h7: return SEG7;
      4'h8: return SEG8;
      4'h9: return SEG9;
      4'ha: return SEGA;
      4'hb: return SEGb;
      4'hc: return SEGC;
      4'hd: return SEGd;
      4'he: return SEGE;
      4'hf: return SEGF;
    endcase
  endfunction

  always @(*) begin
    for (int k = 0; k < 8; k++) segs_combine[k] = SEGNONE;

    if (nstate == NORMAL | nstate == HALT) begin
      /// Display PC
      for (int k = 0; k < 8; k++) begin
        segs_combine[k] = get_hex_seg(pc[k*4+:4]);
      end
    end else begin
      /// Display Error
      segs_combine[FetchError] = interrupt[FetchError] ? SEGERROR : SEGNONE;
      segs_combine[DecodeError] = interrupt[DecodeError] ? SEGERROR : SEGNONE;
      segs_combine[MemAccessError] = interrupt[MemAccessError] ? SEGERROR : SEGNONE;
      segs_combine[UnknownBrtyError] = interrupt[UnknownBrtyError] ? SEGERROR : SEGNONE;

      for (int i = Anormaly + 1; i < 8; i = i + 1) begin
        segs_combine[i] = SEGNONE;
      end
    end
  end

  always @(posedge clk_i) begin
    if (rst_i) begin
      for (int k = 0; k < 8; k++) segs_reg[k] <= SEGNONE;
    end else begin
      for (int k = 0; k < 8; k++) segs_reg[k] <= segs_combine[k];
    end

    $display("Current Pc: %h", pc);
  end

endmodule
