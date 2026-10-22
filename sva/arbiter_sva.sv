// Assertion module for arbiter2. Bound onto the DUT from the testbench.
// Sampling note: grants seen at a clock tick came from the PREVIOUS edge's requests.
module arbiter_sva (
  input logic clk, rst_n, req0, req1, gnt0, gnt1
);
  default clocking cb @(posedge clk); endclocking

  // A1: mutual exclusion (checked always, even during reset).
  // === ignores the X values that exist before the first reset edge.
  A1_mutex: assert property (!(gnt0 === 1'b1 && gnt1 === 1'b1))
    else $error("A1 FAIL: both grants high");

  // A2: no spurious grant - a grant needs its request one cycle earlier
  A2_no_spur0: assert property (disable iff (!rst_n) gnt0 |-> $past(req0))
    else $error("A2 FAIL: gnt0 without req0");
  A2_no_spur1: assert property (disable iff (!rst_n) gnt1 |-> $past(req1))
    else $error("A2 FAIL: gnt1 without req1");

  // A3: grant response - a lone request is granted next cycle
  A3_resp0: assert property (disable iff (!rst_n) (req0 && !req1) |=> gnt0)
    else $error("A3 FAIL: lone req0 not granted");
  A3_resp1: assert property (disable iff (!rst_n) (req1 && !req0) |=> gnt1)
    else $error("A3 FAIL: lone req1 not granted");

  // A4: fairness - on a continued tie, the grant flips
  A4_fair0: assert property (disable iff (!rst_n) (gnt0 && req0 && req1) |=> gnt1)
    else $error("A4 FAIL: gnt0 repeated on tie");
  A4_fair1: assert property (disable iff (!rst_n) (gnt1 && req0 && req1) |=> gnt0)
    else $error("A4 FAIL: gnt1 repeated on tie");

  // A5: reset clears grants on the next cycle
  A5_reset: assert property (!rst_n |=> (!gnt0 && !gnt1))
    else $error("A5 FAIL: grant during/after reset");

  // Coverage: did the tests actually reach these scenarios?
  C_gnt0      : cover property (disable iff (!rst_n) gnt0);
  C_gnt1      : cover property (disable iff (!rst_n) gnt1);
  C_tie       : cover property (disable iff (!rst_n) req0 && req1);
  C_tie_alt01 : cover property (disable iff (!rst_n) gnt1 && $past(gnt0));
  C_tie_alt10 : cover property (disable iff (!rst_n) gnt0 && $past(gnt1));
  C_idle      : cover property (disable iff (!rst_n) !req0 && !req1);
  C_reset_mid : cover property ($fell(rst_n));
endmodule
