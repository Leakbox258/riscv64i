module Display #(
    DISPLAY_WIDTH = 32
) (
    input clk_i,
    input rst_i,
    input [DISPLAY_WIDTH-1:0] display_i,

    output reg [7:0] segs_reg[7:0]
);
  reg [7:0] segs_combine[8];


  /// NVBorad
  //   parameter   
  //             SEGNONE = ~(8'b00000000),
  //             SEGERROR = ~(8'b10010010),
  //             SEG0 = ~(8'b11111100),
  //             SEG1 = ~(8'b01100000),
  //             SEG2 = ~(8'b11011010),
  //             SEG3 = ~(8'b11110010),
  //             SEG4 = ~(8'b01100110),
  //             SEG5 = ~(8'b10110110),
  //             SEG6 = ~(8'b10111110),
  //             SEG7 = ~(8'b11100000),
  //             SEG8 = ~(8'b11111110),
  // 			SEG9 = ~(8'b11110110),
  // 			SEGA = ~(8'b11101110),
  // 			SEGb = ~(8'b00111110),
  // 			SEGC = ~(8'b10011100),
  // 			SEGd = ~(8'b01111010),
  // 			SEGE = ~(8'b10011110),
  // 			SEGF = ~(8'b10001110);

  /// DE2-115
  parameter	SEGNONE = ~(8'b00000000),  
			SEGERROR = ~(8'b01001001),  
			SEG0 = ~(8'b00111111),  
			SEG1 = ~(8'b00000110),  
			SEG2 = ~(8'b01011011),  
			SEG3 = ~(8'b01001111),  
			SEG4 = ~(8'b01100110),
			SEG5 = ~(8'b01101101),  
			SEG6 = ~(8'b01111101),  
			SEG7 = ~(8'b00000111),  
			SEG8 = ~(8'b01111111),  
			SEG9 = ~(8'b01101111),  
			SEGA = ~(8'b01110111),  
			SEGb = ~(8'b01111100),  
			SEGC = ~(8'b00111001),  
			SEGd = ~(8'b01011110),  
			SEGE = ~(8'b01111001),  
			SEGF = ~(8'b01110001);


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

  always_comb begin
    for (int k = 0; k < 8; k++) segs_combine[k] = SEGNONE;

    /// Display 
    for (int k = 0; k < 8; k++) begin
      segs_combine[k] = get_hex_seg(display_i[k*4+:4]);
    end

  end

  logic [28:0] cycle;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      for (int k = 0; k < 8; k++) segs_reg[k] <= SEGNONE;
      cycle <= 0;
    end else begin
      cycle <= cycle + 1;

      if (cycle[25]) for (int k = 0; k < 8; k++) segs_reg[k] <= segs_combine[k];
    end
  end

endmodule
