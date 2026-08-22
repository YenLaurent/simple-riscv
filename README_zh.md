# simple-riscv

一个动手实践型的 RISC-V 学习项目：**单周期 RV32I CPU** + **memory-mapped 脉动阵列协处理器**，全部 RTL 从零手写，用 Icarus Verilog 仿真验证。

[English](README.md)

## 特性

- **单周期 RV32I CPU**——完整基础整数指令集（37 条指令，除 `fence`/`ecall`/`ebreak`/`csr*`），Harvard 架构，两层译码器，从 ISA 手册逐条实现
- **性能计数器**——硬件 `mcycle`/`minstret`，配套定量 CPI 分析报告
- **2×2 脉动阵列协处理器**——output-stationary 数据流，寄存式 PE，硬件自动输入偏斜（skewing）
- **任意内积维**——2×K × K×2 矩阵乘法，K ≤ 16，计数器化馈入 FSM
- **64 位结果输出**——32 位总线上 lo/hi 寄存器对
- **Memory-mapped 接口**——CPU 用普通 `sw`/`lw` 控制加速器（写数据 → start → 轮询 → 读结果）
- **裸机 C 工具链**——GCC → ELF → `.mem` → `$readmemh`，自检式基准程序

## 架构

```
PC → IMEM → Decoder ─┬→ RegFile → ALU → LSU → DMEM → WriteBack MUX → RegFile
                     └── ImmGen ───────────┘

CPU (sw/lw) ⇄ accelerator_top（A/B 缓冲 + 计数 FSM + 快照）⇄ 2×2 PE 阵列
```

## 目录结构

```
rtl/             CPU 各模块 + 加速器（pe、systolic_2x2、accelerator_top）
testbench/       每个模块的自检测试台
software/        链接脚本、crt0 启动代码、汇编测试、C 基准程序
scripts/         elf_to_mem.py（ELF → hex）
docs/            cpu.md、systolic_array.md、学习笔记
build/           仿真产物（不入库）
```

## 快速开始

环境要求：WSL2 + `iverilog`（v10+）+ `gtkwave`；C 程序需要 `riscv64-unknown-elf-gcc`。

- **仿真单个模块**：RTL 与对应 testbench 一起编译后运行，如 `iverilog -g2012 -o build/sim/tb_alu.vvp rtl/alu.sv testbench/alu_tb.sv && vvp build/sim/tb_alu.vvp`
- **跑基准程序**：用裸机工具链编译 C 程序（`crt0.S` + `link.ld`），经 `scripts/elf_to_mem.py` 转成 `.mem`（IMEM 自动加载 `build/sw/test_prog.mem`），再连同全部 RTL 与 `testbench/cpu_top_tb.sv` 编译仿真
- **看波形**：用 `gtkwave` 打开生成的 `.vcd`
```

## 性能数据

| 指标 | 结果 |
|---|---|
| CPU CPI | ≡ 1.0（mcycle == minstret，实测） |
| 加速器，2×K×K×2（K=8） | 每轮 ~310 周期 vs 软件 ~1490 周期 → **加速比 ~4.8×** |
| 纯计算 | 阵列 12 拍 vs 软件乘法 ~1200 拍 → **~125×** |

## 文档

- [docs/cpu.md](docs/cpu.md) — CPU 架构与性能分析
- [docs/systolic_array.md](docs/systolic_array.md) — 协处理器设计、接口与测试结果
- [docs/notes/Learning Notebook.md](docs/notes/Learning%20Notebook.md) — 逐日学习笔记
