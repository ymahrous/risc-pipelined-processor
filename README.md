# RISC Pipelined Processor (6-Stage CPU in VHDL)

A 6-stage pipelined RISC-based processor implemented in VHDL as part of a computer architecture project.  
The design demonstrates instruction-level parallelism, hazard handling, and the core concepts behind modern CPU microarchitecture.

---

## ⚙️ Architecture Overview

This processor follows the classic **6-stage RISC pipeline**:

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute1 (EX1)
4. Execute2 (EX2)
5. Memory Access (MEM)
6. Write Back (WB)

The pipeline allows multiple instructions to be processed simultaneously, improving throughput compared to a single-cycle design.

---

## 🧠 Pipeline Diagram

<img src="https://github.com/ymahrous/risc-pipelined-processor/blob/main/schema.jpg"/>

The pipeline allows multiple instructions to be processed simultaneously, improving throughput compared to a single-cycle design.

---

## 🧠 Key Features

- 5-stage pipelined datapath
- Instruction memory + data memory separation
- Control unit for instruction decoding
- Basic hazard handling (pipeline coordination)
- Register file implementation
- ALU supporting arithmetic and logical operations
- Modular VHDL design for CPU components

---

## 📂 Project Structure

- `datapath/` → Core pipeline stages (IF, ID, EX1, EX2, MEM, WB)
- `control/` → Control unit and signal generation
- `memory/` → Instruction and data memory modules
- `registers/` → Register file implementation
- `testbench/` → Simulation testbenches
- `top/` → Top-level CPU integration module

---

## 🚀 Getting Started

### Simulation
This project can be simulated using standard VHDL simulators such as:
- ModelSim
- GHDL
- QuestaSim

### Steps
1. Compile all VHDL source files
2. Run the top-level testbench
3. Observe waveform output for pipeline execution behavior

---

## 📊 What This Project Demonstrates

This CPU design demonstrates understanding of:

- Computer architecture fundamentals
- Pipeline execution and instruction flow
- Hardware design using HDL (VHDL)
- Tradeoffs in performance vs complexity
- Modular digital system design

---

## 🧩 Limitations / Future Work

- No advanced hazard prediction (e.g., branch prediction)
- Limited instruction set implementation
- No cache or memory hierarchy
- No FPGA deployment integration yet

Future improvements:
- Forwarding unit optimization
- Branch prediction
- FPGA synthesis and real hardware testing
- Expanded instruction set support

---

## 🎯 Why This Project Matters

This project reflects foundational understanding of how modern CPUs work internally.  
It is representative of real-world concepts used in:

- Embedded systems
- Processor design
- FPGA-based computing
- High-performance architecture research
