# simple-riscv

A hands-on RISC-V learning project: a **single-cycle RV32I CPU** with a **memory-mapped systolic array coprocessor**, built from scratch in SystemVerilog and verified with Icarus Verilog.

[中文版](README_zh.md)

## Features

- **Single-cycle RV32I CPU** — full base integer instruction set (37 instructions, except `fence`/`ecall`/`ebreak`/`csr*`), Harvard architecture, two-layer decoder, hand-written from the ISA spec up
- **Performance counters** — `mcycle`/`minstret` in hardware, with a quantitative CPI analysis
- **2×2 systolic array coprocessor** — output-stationary dataflow, registered PEs, automatic input skewing
- **Arbitrary inner-product dimension** — 2×K × K×2 matrix multiplication, K ≤ 16, via a counter-based feed FSM
- **64-bit results** — lo/hi register pairs behind a 32-bit bus
- **Memory-mapped interface** — the CPU controls the accelerator with plain `sw`/`lw` (write → start → poll → read)
- **Bare-metal C toolchain** — GCC → ELF → `.mem` → `$readmemh`, self-checking benchmarks

## Architecture

```
PC → IMEM → Decoder ─┬→ RegFile → ALU → LSU → DMEM → WriteBack MUX → RegFile
                     └── ImmGen ───────────┘

CPU (sw/lw) ⇄ accelerator_top (A/B buffers + count FSM + snapshot) ⇄ 2×2 PE array
```

## Directory Structure

```
rtl/             CPU modules + accelerator (pe, systolic_2x2, accelerator_top)
testbench/       self-checking testbenches for every module
software/        linker script, crt0 startup, assembly tests, C benchmarks
scripts/         elf_to_mem.py (ELF → hex)
docs/            cpu.md, systolic_array.md, notes/
build/           simulation artifacts (untracked)
```

## Quick Start

Prerequisites: WSL2 with `iverilog` (v10+) and `gtkwave`; `riscv64-unknown-elf-gcc` for C programs.

- **Simulate one module**: compile the RTL with its testbench, then run — e.g. `iverilog -g2012 -o build/sim/tb_alu.vvp rtl/alu.sv testbench/alu_tb.sv && vvp build/sim/tb_alu.vvp`
- **Run a benchmark**: build the C program with the bare-metal toolchain (`crt0.S` + `link.ld`), convert via `scripts/elf_to_mem.py` (IMEM auto-loads `build/sw/test_prog.mem`), then compile the RTL together with `testbench/cpu_top_tb.sv` and run
- **View waveforms**: open the generated `.vcd` with `gtkwave`

## Performance Highlights

| | Result |
|---|---|
| CPU CPI | ≡ 1.0 (mcycle == minstret, measured) |
| Accelerator, 2×K×K×2 (K=8) | ~310 cycles/run vs ~1490 cycles/run in software → **~4.8× speedup** |
| Pure compute | array 12 cycles vs software MACs ~1200 cycles → ~125× |

## Documentation

- [docs/cpu.md](docs/cpu.md) — CPU architecture and performance analysis
- [docs/systolic_array.md](docs/systolic_array.md) — coprocessor design, interface, results
- [docs/notes/Learning Notebook.md](docs/notes/Learning%20Notebook.md) — day-by-day learning notes

## License

MIT
