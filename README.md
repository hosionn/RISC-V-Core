# 处理器内核仿真与开发环境

这是一个用于处理器内核开发的环境，可以通过 Makefile 脚本进行硬件编译、软件编译、仿真与查看波形。项目中已经包含一个实现了 RV64I 基础指令集的处理器，再次基础上可以进行后续的功能扩展和验证。处理器采用 **IF、ID、EX、MEM、WB 经典五级流水线**。

本项目使用 git 来进行版本维护。修改代码前，请先创建新的分支，在此分支上修改、提交后，再将该分支推送到远程仓库。提交信息使用固定的格式：方括号中写出这次修改的主要模块类别，后面跟一句话的详细描述。例如：
```
[IFU] Add branch predictor, including BHT, BHB, RAS.
```
本项目的 verilog 代码需要在文件头中标明作者和版本信息，格式如下：
```verilog
//===================================================================== 
/// Description: 
// This module is ......
// Designer : xxx@sjtu.edu.cn
// Revision History
// V0 date:2025/11/28 Initial version, xxx@sjtu.edu.cn
// ==================================================================== 
```

## 在 Linux 上运行

+ 需要 `make`、GNU `od` 和 Synopsys VCS；`make wave` 另需 Verdi。
+ 软件编译需要 Nuclei 官方的 Linux 裸机工具链，主要使用了`riscv64-unknown-elf-{as,ld,objcopy,objdump}`。

可通过 `RISCV_PREFIX`、`VCS`、`VERDI` 覆盖程序路径。推荐先进入 `vsim/` 再执行下列命令；也可以从项目根目录运行相同命令，根 Makefile 会转发到 `vsim/`：

```sh
make install                       # 检查工具并准备 vsim/install/、run/、build/
make compile                       # 在 vsim/run/ 编译，生成 ./simv 等产物
make run_test TESTCASE=arith        # 汇编、链接并运行指定测试
make run_test TESTCASE=branch
make run_test TESTCASE=loadstore
make run_test TESTCASE=hazard
make run_test TESTCASE=pipeline      # 专门覆盖前递、load-use 和冲刷
make wave TESTCASE=arith            # 仅打开现有 VCD，不重新仿真
make regress                       # 依次运行全部五个测试
make disasm TESTCASE=arith          # 核对实际机器码与反汇编
```

参考 E603 的仿真脚本，`compile` 会在 `vsim/run/` 中调用 VCS，生成 `build_file.vf`（绝对路径文件列表）、`simv`、`compile.log` 和工具中间文件；`run_test` 也在该目录执行 `./simv`。镜像通过 `../build/<测试名>.hex` 加载；仿真日志和波形分别写入 `vsim/run/<测试名>/sim.log` 与 `wave.vcd`。结束时终端直接打印 `PASS arith` 或 `FAIL arith`，失败则返回非零状态；testbench 同时输出 `TEST_PASS` 或 `TEST_FAIL` 及原因。`make wave TESTCASE=...` 从 `vsim/run/` 启动 Verdi，**只打开已有波形**，不会重新仿真。`make clean` 删除整个 `vsim/run/` 及 `vsim/build/`、`vsim/install/`。设置 `DUMPWAVE=0` 可关闭生成波形，`TRACE=1` 可打印每条执行指令的 PC 与机器码，例如 `make run_test TESTCASE=arith TRACE=1 DUMPWAVE=0`。

`make all` 默认运行 `arith`；`make tests` 只构建全部测试镜像；`make clean` 删除本项目构建产物。可用 `MAX_CYCLES=20000` 修改超时门限。若工具链安装在非标准位置，例如：

```sh
make run_test TESTCASE=arith RISCV_PREFIX=/opt/riscv/bin/riscv64-unknown-elf-
```

构建过程为 `.s → .o → .elf → .bin → .hex`。`ld` 将代码放在地址 `0x0`；`objcopy` 生成原始字节镜像，`od` 将每个字节转为 `$readmemh` 可读的十六进制文本。`imem` 在仿真时从 `+HEX=...` 加载镜像，`dmem` 独立初始化为零；`tb_top` 不包含或初始化存储器。取指地址均为字节地址，RAM 小端存放。`make disasm` 是修改测试后值得首先运行的一步，便于发现伪指令展开或意外的扩展指令。

`make wave TESTCASE=...` 使用 Verdi 打开 VCD；未依赖 FSDB 转储配置。如果本地 Verdi 版本无法直接通过 `-ssf` 打开 VCD，可以在 Verdi GUI 中手动导入同一文件。

## 目录

```text
riscv_project/
├─ rtl/
│  ├─ soc/soc.v                 # 系统顶层：core + imem + dmem
│  ├─ core/
│  │  ├─ core.v                # 内核顶层：ifu + exu
│  │  ├─ ifu/ifu.v             # IF 逻辑和 IF/ID 寄存器
│  │  └─ exu/
│  │     ├─ exu.v              # ID、EX、MEM、WB 与级间寄存器
│  │     └─ units/            # decoder、regfile、alu、branch、lsu、前递/冒险单元
│  ├─ memory/{imem,dmem}.v     # 独立的外部指令/数据 RAM
│  └─ common/gnrl_dff.v       # 通用寄存器模块
├─ software/tests/            # RV64I 定向汇编测试及宏
├─ tb/tb_top.v                # testbench；不包含存储器
├─ vsim/
│  ├─ Makefile                # 软件构建、VCS 编译、测试运行及波形入口
│  ├─ filelist.f              # RTL 与 testbench 文件列表
│  ├─ install/                # make install 生成；仿真文件列表
│  ├─ build/                  # 汇编、ELF、机器码等软件构建产物
│  └─ run/                    # VCS/Verdi 中间文件、simv、日志与波形
└─ Makefile                   # 兼容入口，转发到 vsim/Makefile
```

`install/`、`build/`、`run/` 在首次运行命令时创建，均位于 `vsim/` 下。RTL 按 `soc → core → ifu/exu → EXU 功能单元` 的例化关系分层。


## 添加一个汇编测试

将 `software/tests/arith.s` 复制为新的 `software/tests/<name>.s`，保留 `.include "test_macros.inc"`、`.globl _start`、入口 `_start:`，在通过路径执行 `PASS`，错误路径执行 `FAIL`。随后运行 `make run_test TESTCASE=<name>`。测试用 `-march=rv64i -mabi=lp64 -mno-relax` 汇编，链接时也关闭松弛；本阶段不要使用 CSR、乘除法、压缩指令或依赖标准库的伪系统调用。新增测试不必加入 `TESTS` 列表即可单独运行，但要加入列表才会被 `make tests` 批量构建。

## 当前未覆盖的验证

附带五个测试覆盖主要运算、跳转、带符号与无符号加载、各宽度存储以及前递/停顿/冲刷。其中 `pipeline` 测试还要求仿真观察到多级同时有效、两级前递、load-use 停顿和控制流重定向；**这些测试不是完整的 ISA 合规性测试**。后续应增加边界值、全部合法/非法编码、总线错误、未对齐访问和随机指令流测试，并用独立参考模型比对。当前 Windows 工作区没有 VCS 和 RISC-V GNU 工具链，因此这些脚本和 RTL 尚未在本机实际编译或仿真；请在 Linux 环境运行上述命令并根据第一轮日志迭代。


## 已实现的指令及边界

- 整数计算：`LUI`、`AUIPC`、RV64I 的立即数和寄存器 ALU 指令，以及 `ADDIW/SLLIW/SRLIW/SRAIW/ADDW/SUBW/SLLW/SRLW/SRAW`。`*W` 结果按规范符号扩展为 64 位。
- 控制流：`JAL`、`JALR`、六种条件分支。跳转目标必须 4 字节对齐；`JALR` 会清除目标地址 bit 0。
- 访存：`LB/LH/LW/LD/LBU/LHU/LWU` 和 `SB/SH/SW/SD`，按小端字节序读写。
- `FENCE`：由于访存按序完成，且没有缓存或写缓冲，本版按空操作处理。`FENCE.I` 属于独立扩展，本版本不支持。
- 无特权架构、CSR、异常入口、中断、MMU、Cache、M/A/C 扩展。未实现的编码会使内核停止并给出调试原因。`ECALL`、`EBREAK` 分别产生专用停止原因，但不进入异常处理程序。非对齐访存会停止，不做拆分访问。

寄存器 `x0` 恒为零；复位后其余寄存器清零，仅为方便早期验证。软件仍不应依赖通用寄存器的复位值。

## 执行与存储器时序

例化层次为 `soc → core + imem + dmem`，其中 `core → ifu + exu`，`exu → decoder + regfile + alu + branch + lsu + forward_unit + hazard_unit`。各级边界和寄存器堆使用 `gnrl_dff*` 模块。RAM 不属于处理器内核，日后可用真实 SRAM 或总线接口替换，但接口时序也必须相应调整。

| 流水级 | 当前实现 |
| --- | --- |
| IF | 寄存的 `pc` 直接访问组合读的指令 RAM；当拍指令在时钟边沿进入 IF/ID。`next_pc` 由顺序 PC 或 EX 重定向组合选出，没有分支预测。 |
| ID | 译码并读取寄存器；控制信息和源操作数进入 ID/EX 寄存器。 |
| EX | ALU、分支判断和访存有效地址计算；结果、store 数据及控制信息进入 EX/MEM 寄存器。 |
| MEM | LSU 用 EX/MEM 中的地址和数据向数据 RAM 发出请求；读数据当拍组合返回，完成符号/零扩展后进入 MEM/WB 寄存器。写入在本拍末的时钟边沿发生。 |
| WB | 将 ALU、跳转链接地址或加载结果写回寄存器堆。 |

普通 RAW 冒险优先使用 **EX/MEM → EX** 前递，其次使用 **MEM/WB → EX** 前递；写回与译码同一时钟沿访问同一寄存器时还使用 WB→ID 旁路。紧跟 load 的使用者无法从 EX/MEM 得到数据，因此 hazard_unit 保持 PC/IF/ID、向 ID/EX 插入一个气泡；随后从 MEM/WB 前递加载结果。前递同样用于分支比较、JALR 目标、访存地址和 store 数据。分支在 EX 判定，取中时冲刷 IF/ID 和 ID/EX 中较年轻的指令。取指和访存访问不同 RAM，避免结构冲突。

两个 RAM 的**读都是组合逻辑**，地址在当前周期变化，数据和错误也在当前周期给出；没有独立的返回有效通道。PC、EX/MEM、MEM/WB 都只在时钟边沿更新。IF 停顿时保持 PC 和 IF/ID，不需要丢弃或重发读取结果。数据 RAM 的写请求由 MEM 发出，按字节使能在该周期末时钟边沿写入；本版不支持可变时延或带 `ready` 的存储器。数据端口每次传输对齐的 64 位字，指令端口每次读取一个 32 位字。组合读 RAM 在 FPGA 上未必能推断为块 RAM，迁移到同步 SRAM 时需要重新增加等待/返回时序。

复位 PC 为 `0x0`；两个 RAM 各自覆盖 `0x0000`～`0xffff`。程序只加载到指令 RAM，测试数据位于数据 RAM 的 `0x2000` 附近；数据 RAM 的 `0xf000` 是仿真约定的 `tohost`：向该地址执行 64 位存储，值为 `1` 表示通过，其他值表示失败。这里没有使用 `ECALL` 或任何软件运行库。

停止原因 `halt_reason`：`1` 非法/未支持指令，`2` 取指总线错误，`3` 数据总线错误，`4` 跳转目标未按 4 字节对齐，`5` 访存地址未对齐，`6` ECALL，`7` EBREAK。`halt_pc` 是对应指令的 PC。这些是调试状态码，**不是 RISC-V 特权架构中的异常原因码**。
