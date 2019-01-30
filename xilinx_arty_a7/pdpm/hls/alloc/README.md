# Dynamic Physical Memory Allocation

This folder should have code related to dynamic physical memory allocation.

We probably only need a buddy allocator. We don't need something like
slob allocator for objects. But this really depends on FPGA applications.
For our shell, we only need fixed allocation from MMU side.
Network shell side probably can use some fixed DRAM resource for packet loss handling.

Potential APIs
- unsigned int alloc(unsigned int size);
- unsigned int alloc(unsigned int start, unsigned int size);
	- Return physical address or some ID?
	- User may want to enforce starting physical address
- free(unsigned int addr)
	- Depends on what we return on alloc

For implementation, a HW version buddy should be good enough.
You have to have your own metadata.

To get started, try to understand how buddy is implemented in software,
especially what kind of metadata you need to maintain. After that,
think about how this can be implemented in HW. There are some reference
papers on this topic:
- A High-Performance Memory Allocator for Object-Oriented Systems, IEEE'96
- SysAlloc: A hardware manager for dynamic memory allocation in heterogeneous systems, 2015.

Read the first paper first, because it describes the foundamental algorithm.
The SysAlloc is an extension to that.
