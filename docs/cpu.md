# CPU: 单周期 RV32I 处理器

## 架构概览

- **单周期微架构**：一条指令在一个时钟周期内完成取指、译码、执行、访存、写回全部五个阶段
- **Harvard 架构**：IMEM（1024 字）与 DMEM（1024 字）独立编址、独立访问
- **指令集**：RV32I 基本整数指令（除 `fence`/`ecall`/`ebreak`/`csr*`），共 37 条
- **性能计数器**：`mcycle`（周期数）、`minstret`（指令数），64 位，随 CPU 顶层输出

## 数据通路

```
PC → IMEM → Decoder ─┬→ RegFile → ALU → LSU → DMEM → WriteBack MUX → RegFile
                     └── ImmGen ───────────┘
```

所有模块纯组合逻辑（PC、RegFile 写、DMEM 写为时序），单周期内全部信号稳定。时钟周期必须覆盖最长路径（`lw`：PC→IMEM→译码→RegFile→ALU→DMEM→WB MUX→RegFile），该路径决定 `f_max`。

## 模块清单

| 模块 | 接口 | 类型 |
|---|---|---|
| pc | next_pc → pc_out | 时序 |
| imem | addr → instr（`$readmemh` 加载） | 组合 |
| decoder | instr → 8 个控制信号 + alu_ctrl（两层译码） | 组合 |
| reg_file | 双读口（组合）+ 单写口（时序），x0 硬连 0 | 混合 |
| alu | 10 种运算（含 SLT/SLTU/SRA） | 组合 |
| imm_gen | 6 种格式立即数提取 + 符号扩展 | 组合 |
| lsu | byte/half/word 读写，byte_en 生成，符号/零扩展 | 组合 |
| dmem | 组合读 + 带 byte_en 的时序写（读改写） | 混合 |
| cpu_top | 顶层连线 + 3 个 MUX + 分支判定 + 性能计数器 | 混合 |

关键 MUX：`alu_b`（rs2_data vs 立即数）、写回（ALU 结果 vs LSU 数据 vs pc+4）、`alu_a`（lui 选 0 / auipc 选 pc）。

## 性能分析

### CPI 测量

单周期 CPU 每条指令严格占用 1 个周期，因此 `mcycle ≡ minstret`，**CPI ≡ 1.0**——这是微架构定义决定的，经硬件计数器实测验证：

| 程序 | minstret | mcycle | CPI |
|---|---|---|---|
| Fibonacci | 58 | 58 | 1.0 |
| 数组求和 | 61 | 61 | 1.0 |
| 内存复制 | 47 | 47 | 1.0 |

### 指令混合

| 指令类型 | Fibonacci | 数组求和 | 内存复制 |
|---|---|---|---|
| ALU | 44 (75.9%) | 30 (49.2%) | 24 (51.1%) |
| lw | 0 (0%) | 11 (18.0%) | 6 (12.8%) |
| sw | 1 (1.7%) | 12 (19.7%) | 10 (21.3%) |
| 条件分支 | 10 (17.2%) | 5 (8.2%) | 4 (8.5%) |
| jal/jalr | 2 (3.4%) | 2 (3.3%) | 2 (4.3%) |
| lui/auipc | 1 (1.7%) | 1 (1.6%) | 1 (2.1%) |

Fibonacci 为纯计算型（零访存、分支密集），数组求和与内存复制为数据密集型（lw+sw 占 34-38%）。

### 流水线 CPI 预测（五级流水线，forwarding，predict-not-taken）

| 程序 | 预测 CPI | 主要惩罚 |
|---|---|---|
| Fibonacci | ~1.31 | 分支误预测（10 分支 × 2 拍） |
| 数组求和 | ~1.21 | load-use stall + 分支误预测 |
| 内存复制 | ~1.21 | load-use stall + 分支误预测 |

### 性能瓶颈

单周期 CPU 的瓶颈不在 CPI（≡1.0）而在**时钟频率**——周期长度由最长路径决定。流水线可将 `f_max` 提升约 5 倍，代价是 hazard 惩罚；改进分支预测器（1/2-bit 动态预测可将循环误预测率从 ~85% 降到 ~10%）、编译器调度、超标量是进一步降低 CPI 的方向。

**核心结论**：性能是可测量的——不同的微架构参数对不同程序的影响不同，不存在"一刀切"的最优设计。
