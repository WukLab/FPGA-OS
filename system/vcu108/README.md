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
