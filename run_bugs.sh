#!/bin/bash
# Run each faulty DUT; every run should FAIL an assertion. Logs go to results/.
mkdir -p results
for b in bug1 bug2 bug3; do
  echo "=== $b ==="
  rm -rf obj_dir
  verilator --binary --assert --timing -Wno-fatal --top-module tb_arbiter \
    bugs/$b.sv sva/arbiter_sva.sv tb/tb_arbiter.sv > results/${b}_build.log 2>&1
  ./obj_dir/Vtb_arbiter > results/${b}.log 2>&1 || true
  grep -m3 -E "FAIL|MISMATCH" results/${b}.log || echo "NOT CAUGHT - check results/${b}.log"
done
