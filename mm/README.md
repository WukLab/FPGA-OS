# Memory Management

Our Memory Managment (MM) IP is combination of the traditional CPU MM
and OS Fault Handling. Please check the design document for design details.

Building Blocks:
- `axi_rab/`: AXI Remapping Address Block
	- The man in the middle
- `segfix/`: Fixed-size Segment Memory Management
	- The memory is divided into fixed-size chunks.
	- User allocation requests are rounded up.
- `segvar/`: Variable-size Segment Memory Management
- `paging/`: Paging Memory Management

We may have a lot paging implementations..

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
