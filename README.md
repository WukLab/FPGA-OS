# FPGA

Codebase Organization Principles:
- Make each subfolder be an IP on its own. This means it should have its own
  scripts, rtl or hls code, and testbench.
- Hierarchy IPs will have dependency. We need to express the order explicitly
  in corresponding building scripts.
- Final large project should be expressed in a diagram or static RTL code
  that ultilizing small IP cores.
- Overall, this project will consist many small IPs, and they will be used
  internally to build large ones. Our goal is to be able to reuse IPs as much as
  possible, and be able to construct new IPs easily.

- `alloc/`: memory allocator
- `mm/`: memory management
- `tools/`: various helpers
- `scripts/`: template script files
- `samples`: some sample projects
- Generated
	- `generated_ip/`: all generated IPs sleep here
	- `generated_hls_project/`: Vivado HLS project

Coding Format:
- General
	- Make your readable for others.
	- Remove ending spaces and tabs.
- Vivado HLS
	- All Vivado HLS script use `run_hls.tcl` name.
	- C++: try to use Linux kernel coding style.
- Verilog

References
- [UG1118 Vivado Creating and Packaging Custom IP](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_2/ug1118-vivado-creating-packaging-custom-ip.pdf)
