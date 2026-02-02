# Ibex / aespim DV: Running the SystemVerilog testbenches (Verilator)

This repository includes three simple SystemVerilog testbenches under `dv/aespim/`:

- `tb_aespim_keyexpansion.sv`
- `tb_aespim_encryption.sv`
- `tb_aespim_gmul.sv`

## Prerequisites

- `verilator` available in your `PATH`
- Run commands from the repository root (so `rtl/` and `dv/` paths match)

## Build and run

Each testbench can be built into a standalone executable with `verilator --cc --binary ...` and then executed.

### 1) Key expansion testbench

```sh
verilator --cc --binary --top tb_aespim_keyexpansion --assert --timing --trace \
  rtl/aespim_pkg.sv dv/aespim/tb_aespim_keyexpansion.sv -I"./rtl"

./obj_dir/Vtb_aespim_keyexpansion
```

### 2) Encryption testbench

```sh
verilator --cc --binary --top tb_aespim_encryption --assert --timing --trace \
  rtl/aespim_pkg.sv dv/aespim/tb_aespim_encryption.sv -I"./rtl"

./obj_dir/Vtb_aespim_encryption
```

### 3) GMUL testbench

```sh
verilator --cc --binary --top tb_aespim_gmul --assert --timing --trace \
  rtl/aespim_pkg.sv dv/aespim/tb_aespim_gmul.sv -I"./rtl"

./obj_dir/Vtb_aespim_gmul
```

## Waveforms

The testbenches enable tracing (`--trace`) and attempt to dump a VCD file (commonly `*.vcd`) during simulation. After running a test, check the working directory for the generated VCD and open it with a waveform viewer (e.g., GTKWave).