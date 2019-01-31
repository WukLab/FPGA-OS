# Low-level Segmented MMU

## API

- `translate(va, pa)`
- `insert(va_base, va_bound, pa_base, permission)`
- `delete(va_base, va_bound)`
- `debug interfaces`

## TODO

- Where to store the table
	- Small ones in on-board BRAM, distributed RAM, or registers
	- Big ones have to swap through DRAM
- Do we need CAM, or TLB?
	- In general related to where the table is.
- Synchornization
	- among lookup, insert, delete. One way is to use token-based sync.
	- any other ways?
- Deal with fault
	- First, need to back pressure source, let it stall or something
	- Second, need to send request to fault handling part
- Have performance numbers all along
	- goal is II=1
	- small latency
