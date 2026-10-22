# Assertion-Based Verification of a Two-Requester Round-Robin Arbiter

SystemVerilog RTL, SystemVerilog Assertions (SVA), a self-checking testbench and cover properties, simulated with Verilator.

## Overview
A two-requester round-robin arbiter (`arbiter2`) with registered grants and a synchronous active-low reset. It is verified with 8 bound SVA assertions (5 groups), 7 cover properties, directed tests, 2000 cycles of constrained-random stimulus and an independent reference-model scoreboard. Three deliberately buggy DUTs show that the assertions catch real faults.

## Arbiter behaviour
| rst_n | req0 | req1 | next gnt0 | next gnt1 | next last |
|---|---|---|---|---|---|
| 0 | x | x | 0 | 0 | 1 |
| 1 | 0 | 0 | 0 | 0 | unchanged |
| 1 | 1 | 0 | 1 | 0 | 0 |
| 1 | 0 | 1 | 0 | 1 | 1 |
| 1 | 1 | 1 | 1 if last=1 else 0 | 0 if last=1 else 1 | flips to the winner |

`last = 1` means requester 1 won most recently, so requester 0 wins the next tie. Grants are registered (one-cycle latency).

## Assertions
| ID | Rule |
|---|---|
| A1 | Mutual exclusion: `gnt0` and `gnt1` are never both 1 |
| A2 | No spurious grant: a grant needs its request one cycle earlier |
| A3 | Grant response: a lone request is granted on the next cycle |
| A4 | Fairness: on a continued tie the grant flips |
| A5 | Reset clears both grants on the next cycle |

Cover properties: `C_gnt0`, `C_gnt1`, `C_tie`, `C_tie_alt01`, `C_tie_alt10`, `C_idle`, `C_reset_mid`.
Assertions are attached to the DUT with `bind`, so the RTL stays clean.

## Repository structure
```
rtl/arbiter2.sv       DUT
sva/arbiter_sva.sv    assertions and cover properties
tb/tb_arbiter.sv      testbench, reference model, scoreboard
bugs/bug1-3.sv        faulty DUTs for bug-injection
run.sh                run the correct DUT
run_bugs.sh           run all three faulty DUTs
results/              logs from run_bugs.sh
```

## How to run (Ubuntu)
```bash
sudo apt update && sudo apt install -y verilator
./run.sh          # expect: PASS: no mismatches
./run_bugs.sh     # each bug should print an assertion FAIL
```

## Bug injection
| File | Injected bug | Checker expected to fire |
|---|---|---|
| bug1.sv | req0 always wins ties | A4 (fairness) |
| bug2.sv | gnt1 asserted with no request | A2 (no spurious grant) |
| bug3.sv | reset leaves gnt0 set | A5 (reset) |

Verilator stops at the first failed assertion, so each run shows one failure. Logs are in `results/`.

## Limitations
Simulation only; two requesters; single clock; no formal verification or UVM.

## Future work
Covergroups, N requesters, formal proofs of A1-A5, UVM environment.
