# VCU108

The board only use one type of memory controller, but it has two MACs
- AXI Ethernet Subsystem
- QSPF

Our system, essentially is `LegoFPGA.bd`. We put everything within
the BD design, which is easy to generate and easy to build.

The `LegoFPGA.bd` essentially has three major interfaces
- AXI-Stream from MAC
- AXI-Stream to MAC
- DDR to DRAM

Keep in mind.


## Issues

Having AXI Ethernet Subsystem within the example design, the whole thing can NOT be
exported a Block Diagram IP, which is annoying.

One possible way to do it is extract the SM/clock as a standlone RTL IP, and
then merge it with a MAC IP in a BD design. Doable. Later.


## Cheatsheet

Convert generated bitstream into flash-format bitstream:
```
vivado -mode tcl -source convert_bit_mcs.tcl -tclargs ./generated_vivado_project/generated_vivado_project.runs/impl_1/XXX.bit ./XXX.mcs
```

```
vivado -mode tcl -source program_bpi.tcl -tclargs ./top_pcie_RDM.mcs
```
