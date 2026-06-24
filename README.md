# RISC Pipelined Processor

A 6-stage pipelined RISC-based processor implemented in VHDL as part of a computer architecture project.  
The design demonstrates instruction-level parallelism, hazard handling, and the core concepts behind modern CPU microarchitecture.

---

## Architecture Overview

This processor follows the classic **6-stage RISC pipeline**:

1. Instruction Fetch  (IF)
2. Instruction Decode (ID)
3. Execute1           (EX1)
4. Execute2           (EX2)
5. Memory Access      (MEM)
6. Write Back         (WB)

The pipeline allows multiple instructions to be processed simultaneously, improving throughput compared to a single-cycle design.

---

## Pipeline Diagram

<img src="https://github.com/ymahrous/risc-pipelined-processor/blob/main/schema.jpg"/>

The pipeline allows multiple instructions to be processed simultaneously, improving throughput compared to a single-cycle design.

---

## Key Features

- 6-stage pipelined datapath
- Instruction memory + data memory separation
- Control unit for instruction decoding
- Basic hazard handling (pipeline coordination)
- Register file implementation
- ALU supporting arithmetic and logical operations
- Modular VHDL design for CPU components

---

## Project Structure

```
risc-pipelined-processor/
├── src/
│   ├── assembler/              # Assembly language toolchain
│   │   └── assembler.py        # Assembler for converting assembly code to machine code
│   └── rtl/                    # VHDL source files
│       ├── stages/             # Pipeline stages
│       │   ├── 1-fetch/        # Fetch stage
│       │   ├── 2-decode/       # Decode stage
│       │   ├── 3-execute1/     # Execute1 stage
│       │   ├── 4-execute2/     # Execute2 stage
│       │   ├── 5-memory/       # Memory stage
│       │   └── 6-writeback/    # Write-back stage
│       ├── processor.vhd       # Top-level processor integration
│       └── ...                 # Supporting components
├── testcases/                  # Assembly test programs
│   ├── Branch.asm              # Branch instruction tests
│   ├── Memory.asm              # Memory operation tests
│   ├── OneOperand.asm          # One-operand instruction tests
│   └── TwoOperand.asm          # Two-operand instruction tests
└── build/                      # Build artifacts and simulation files
```

---

## Getting Started

### Simulation
- ModelSim, Vivado, or any VHDL-compatible simulator
- Python 3.x (for the assembler)

### Steps
1. **Assemble Test Programs**
   ```bash
   python src/assembler/assembler.py testcases/OneOperand.asm
   ```

2. **Simulate in ModelSim**
   - Open your VHDL simulator
   - Add all VHDL files from `src/rtl/` to your project
   - Set `processor.vhd` as the top-level entity
   - Load the assembled machine code into memory
   - Run the simulation

3. **Run Test Cases**
   - Each test case in `testcases/` validates specific processor functionality
   - Monitor register values and memory contents during simulation
   - Verify CCR flags and pipeline behavior

---

## Pipeline Stages

1. **Fetch Stage**:      Retrieves instructions from memory using the Program Counter (PC)
2. **Decode Stage**:     Decodes instructions, reads register file, and handles hazard detection
3. **Execute1 Stage**:   Performs ALU operations
4. **Execute2 Stage**:   Calculates branch targets
5. **Memory Stage**:     Handles memory reads/writes and stack operations
6. **Write-back Stage**: Writes results back to the register file

---

## Hazard Handling

- **Data Hazards**: Resolved through forwarding paths and pipeline stalling
- **Control Hazards**: Managed with branch prediction and pipeline flushing
- **Structural Hazards**: Eliminated through separate instruction and data memory

---

## Interrupt Handling

The processor supports external hardware interrupts with the following mechanism:
- Interrupt signal (`int`) triggers interrupt handling
- Current PC and CCR are saved to the stack
- PC is loaded from interrupt vector (memory location M[1])
- `RTI` instruction restores PC and CCR from the stack

---

## Test Cases

The `testcases/` directory contains comprehensive assembly programs to validate processor functionality:

- **TwoOperand.asm**: Tests arithmetic and logical operations (ADD, SUB, AND, OR, etc.)
- **OneOperand.asm**: Tests unary operations (INC, DEC, NOT, NEG, etc.)
- **Memory.asm**: Tests LOAD, STORE, PUSH, and POP instructions
- **Branch.asm**: Tests conditional and unconditional branch instructions\

---

## Technical Specifications

- **Data Width**: 32 bits
- **Address Width**: 32 bits (256 KB addressable space)
- **Register File**: 8x32-bit general-purpose registers
- **Pipeline Depth**: 6 stages
- **Instruction Format**: Variable (1-word and 2-word instructions)
- **Clock**: Single-phase synchronous design**

---

## Why This Project Matters

This project reflects foundational understanding of how modern processors work internally.  
It is representative of real-world concepts used in:

- Embedded systems
- Processor design
- FPGA-based computing
- High-performance architecture research

---

## Team

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/ymahrous">
        <img src="https://github.com/ymahrous.png" width="100px;" alt=""/>
        <br />
        <sub><b>Yousef Mahrous</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com">
        <img src="https://github.com" width="100px;" alt=" "/>
        <br />
        <sub><b>Ahmed</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com">
        <img src="https://github.com" width="100px;" alt=" "/>
        <br />
        <sub><b>Yassin</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com">
        <img src="https://github.com" width="100px;" alt=" "/>
        <br />
        <sub><b>Bassel Ahmed</b></sub>
      </a>
    </td>
  </tr>
</table>
