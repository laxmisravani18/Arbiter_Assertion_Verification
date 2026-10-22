`timescale 1ns/1ps
module tb_arbiter;
  logic clk = 0, rst_n = 0, req0 = 0, req1 = 0;
  logic gnt0, gnt1;

  arbiter2 dut (.*);
  bind arbiter2 arbiter_sva sva_i (.*);            // attach assertions to the DUT

  always #5 clk = ~clk;

  // Reference model: independent check on top of the assertions
  logic exp0, exp1, m_last;
  always_ff @(posedge clk) begin
    if (!rst_n) begin exp0 <= 0; exp1 <= 0; m_last <= 1; end
    else begin
      exp0 <= 0; exp1 <= 0;
      if (req0 && req1) begin
        if (m_last) begin exp0 <= 1; m_last <= 0; end
        else        begin exp1 <= 1; m_last <= 1; end
      end else if (req0) begin exp0 <= 1; m_last <= 0; end
      else if (req1)     begin exp1 <= 1; m_last <= 1; end
    end
  end

  int errors = 0;
  // Compare on the falling edge (outputs are stable by then)
  always @(negedge clk)
    if ({gnt0, gnt1} !== {exp0, exp1}) begin
      errors++;
      $display("t=%0t SCOREBOARD MISMATCH gnt=%b%b exp=%b%b", $time, gnt0, gnt1, exp0, exp1);
    end

  task automatic drive(input logic r0, input logic r1, input int n = 1);
    repeat (n) begin @(posedge clk); #1 req0 = r0; req1 = r1; end
  endtask

  task automatic do_reset(input int n = 2);
    @(posedge clk); #1 rst_n = 0; req0 = 0; req1 = 0;
    repeat (n) @(posedge clk);
    #1 rst_n = 1;
  endtask

  initial begin
    // --- Directed tests ---
    do_reset();
    drive(1,0,2);             // only req0
    drive(0,1,2);             // only req1
    drive(0,0,2);             // idle
    do_reset();
    drive(1,1,3);             // spec example: tie x3 -> gnt0, gnt1, gnt0
    drive(0,0,2);
    drive(1,1,1); drive(0,1,1); drive(1,1,1);    // tie after a req1-only win
    drive(0,0,2);
    do_reset();
    drive(1,1,4);             // tie right after reset: req0 first
    // reset in the middle of a tie
    @(posedge clk); #1 rst_n = 0;
    drive(1,1,2);
    #1 rst_n = 1;
    drive(1,1,3);
    drive(0,0,2);

    // --- Constrained-random ---
    repeat (2000) begin
      @(posedge clk); #1;
      req0 = $urandom_range(0,1);
      req1 = $urandom_range(0,1);
      rst_n = ($urandom_range(0,49) != 0);           // ~2% chance of reset
    end
    rst_n = 1; drive(0,0,3);

    if (errors == 0) $display("PASS: no mismatches");
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule
