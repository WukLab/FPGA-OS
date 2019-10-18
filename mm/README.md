# Memory Management

Our Memory Managment (MM) IP is combination of the traditional CPU MM
and OS Fault Handling. Please check the design document for design details.

Building Blocks:
- `axi_rab/`: AXI Remapping Address Block
- `segfix/`: Fixed-size Segment Memory Management
- `segvar/`: Variable-size Segment Memory Management
- `paging/`: Paging Memory Management

High-Level:
- `ip_sysmm_segfix`
	- `axi_rab/`
	- `segfix/`
- `ip_sysmm_segvar`
	- `axi_rab/`
	- `segvar/`
- `ip_libmm_segfix`
	- `axi_rab/`
	- `segfix/`
- `ip_libmm_segvar`
	- `axi_rab/`
	- `segvar/`
- `ip_libmm_paging`
	- `axi_rab/`
	- `paging`
