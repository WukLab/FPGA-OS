# Memory Management

Our Memory Managment (MM) IP is combination of the traditional CPU MM
and OS Fault Handling. Please check the design document for design details.

- AXI Wrapper
- Paging
	- MMU Agent
	- Fault Handling Agent
- Segment
	- MMU Agent
	- Fault Handling Agent

- `sys/`: the final big MM IP
