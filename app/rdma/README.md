# Remote Memory Access

## Packet Format

Host to FPGA Packet Format

Read Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 1) (opcode: `APP_RDMA_OPCODE_READ`)

Write Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 0)
 (64B)      |          Data         | (last = 0) (opcode: `APP_RDMA_OPCODE_WRITE`)
 (64B)      |          Data         | (last = 1) (Can be partial)

FPGA to Host Packet Format

Reply Read Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 0)
 (64B)      |          Data         | (last = 0) (opcode: `APP_RDMA_OPCODE_REPLY_READ`)
 (64B)      |          Data         | (last = 1) (Can be partial)


## Status

- Partial Read
	- HLS Simulation
- Partial Read Reply
	- HLS Simulation
- Partial Wrie
	- HLS Simulation
