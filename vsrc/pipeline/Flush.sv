`include "pipeline_pkg.sv"

module Flush
  import pipeline_pkg::*;
#(
    FetchError = 0,
    DecodeError = 1,
    MemAccessError = 2
) (
    input [7:0] exception,
    input [DATA_WIDTH-1:0] pc,
    input [DATA_WIDTH-1:0] pcn,
    input enable,

    output logic prediction_failed,
    output logic flush_id,
    output logic flush_if
);
  always_comb begin
    flush_if = 1'b0;
    flush_id = 1'b0;
    prediction_failed = 1'b0;

    if (enable) begin
      /// Exceptions
      if (exception[FetchError]) begin
        flush_if = 1'b1;
      end

      if (exception[DecodeError]) begin
        flush_if = 1'b1;
        flush_id = 1'b1;
      end

      /// Wrong control flow prediction
      if (pc + 4 != pcn) begin
        prediction_failed = 1'b1;
        flush_if = 1'b1;
        flush_id = 1'b1;
      end
    end

    // if (enable2 ...)
    //   if (exception[MemAccessError]) begin
    //     flush_if = 1'b1;
    //     flush_id = 1'b1;
    //     /// TODO: flush ex mem...
    //   end
  end

endmodule
