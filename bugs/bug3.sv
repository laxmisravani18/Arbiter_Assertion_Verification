// bug3: reset leaves gnt0 set
// Two-requester round-robin arbiter (DUT)
// Registered grants, synchronous active-low reset.
// last = 1 -> requester 1 won most recently, so requester 0 wins the next tie.
module arbiter2 (
  input  logic clk,
  input  logic rst_n,
  input  logic req0,
  input  logic req1,
  output logic gnt0,
  output logic gnt1
);
  logic last;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      gnt0 <= 1'b1;               // BUG: grant not cleared by reset
      gnt1 <= 1'b0;
      last <= 1'b1;                // req0 wins the first tie
    end else begin
      gnt0 <= 1'b0;
      gnt1 <= 1'b0;
      if (req0 && req1) begin      // tie: round-robin
        if (last) begin gnt0 <= 1'b1; last <= 1'b0; end
        else      begin gnt1 <= 1'b1; last <= 1'b1; end
      end else if (req0) begin
        gnt0 <= 1'b1; last <= 1'b0;
      end else if (req1) begin
        gnt1 <= 1'b1; last <= 1'b1;
      end
    end
  end
endmodule
