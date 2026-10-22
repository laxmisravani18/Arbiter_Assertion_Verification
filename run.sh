#!/bin/bash
# Run the golden DUT with Verilator.   Usage: ./run.sh
set -e
verilator --binary --assert --timing --coverage -Wno-fatal --top-module tb_arbiter \
  rtl/arbiter2.sv sva/arbiter_sva.sv tb/tb_arbiter.sv
./obj_dir/Vtb_arbiter
# Questa/ModelSim alternative:
#   vlog -sv rtl/arbiter2.sv sva/arbiter_sva.sv tb/tb_arbiter.sv && vsim -c tb_arbiter -do "run -all; quit"
