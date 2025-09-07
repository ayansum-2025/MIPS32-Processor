# MIPS32-Processor
A repository of my Verilog codes for the implementation of a RISC-V processor with hazard detection and stalling and forwarding mechanisms to avoid the hazards.

## **Pipeline Stages**

A standard MIPS32 pipeline has 5 stages: Instruction Fetch, Instruction Decode, Execute, Memory Access and Register Write Back. 

**1. Instruction Fetch (IF)**
* Fetches instructions from memory using the Program Counter (PC)

* Handles branch instructions and pipeline flushing

**2. Instruction Decode (ID)**
* Decodes instructions and reads register values

* Detects hazards and manages stalls

* Sign-extends immediate values

**3. Execute (EX)**
* Performs arithmetic and logical operations

* Calculates memory addresses for load/store instructions

* Evaluates branch conditions

**4. Memory Access (MEM)**
* Accesses data memory for load/store operations

* Passes through results for arithmetic operations

**5. Write Back (WB)**
* Writes results back to the register file

* Handles pipeline stopping for HLT instruction

## **Instruction Set Support**
The processor supports the following MIPS32 instructions:

**1.R-Type Instructions (RR_ALU)**

* ADD - Add

* SUB - Subtract

* AND - Bitwise AND

* OR - Bitwise OR

* SLT - Set Less Than

* MUL - Multiply

**2.I-Type Instructions (RM_ALU)**

* ADDI - Add Immediate

* SUBI - Subtract Immediate

* SLTI - Set Less Than Immediate

**3.Memory Instructions**

* LW - Load Word

* SW - Store Word

**4.Control Flow Instructions**

* BNEQZ - Branch Not Equal to Zero

* BEQZ - Branch Equal to Zero

* HLT - Halt Execution

## **Hazard Handling**

**1.Hazard Detection Unit**
Detects load-use hazards that cannot be resolved by forwarding and inserts pipeline stalls (bubbles) when necessary.

**2.Branch Handling:**
Manages control hazards by:

 * Flushing instructions after taken branches

 * Handling branch conditions in the EX stage

**3.Forwarding Unit:**
The processor implements a forwarding unit that detects when results from later pipeline stages are needed by earlier instructions and forwards them to avoid stalls.

