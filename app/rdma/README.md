# Remote Memory Access

Last Updated: Sep 12, 2019

## Packet Format

Host to FPGA Packet Format

Alloc Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 1) (opcode: `APP_RDMA_OPCODE_ALLOC`)

Read Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 1) (opcode: `APP_RDMA_OPCODE_READ`)

Write Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 0)
 (64B)      |          Data         | (last = 0) (opcode: `APP_RDMA_OPCODE_WRITE`)
 (64B)      |          Data         | (last = 1)

FPGA to Host Packet Format

Reply Read Packet (Succeed):
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 0) (opcode: `APP_RDMA_OPCODE_REPLY_READ`)
 (64B)      |          Data         | (last = 0)
 (64B)      |          Data         | (last = 1)

Reply Read Packet (Failed):
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 1) (opcode: `APP_RDMA_OPCODE_REPLY_READ_ERROR`)

Reply Alloc Packet:
 (64B)      | Eth | IP | UDP | Lego | (last = 0)
 (64B)      | App header |    pad   | (last = 1) (opcode: `APP_RDMA_OPCODE_REPLY_ALLOC`)

struct header for alloc is:
	u8	opcode
	u64	va
	u64	pa

## Reply

Write does not have reply for now.
Read and Alloc will have reply.


## About the source code

TODO: Better documentation and rename folders.

FPGA Side:

- `fpga/`: our first version of RDM. The performance is limited.
- `rdm_mapping/`: our second version of RDM. This implementation will do address translation via a mappint table, thus `rdm_mapping`. The translation is done by another IP.
    - The mapping translation IP is `mm/mapping`.
- `rdm_segment/`: our second version of RDM. The only difference with `rdm_mapping` is that this IP use a simple segment table to do address translation. Check `map()` function.
- `fpga_test/`: An on-chip test IP, used to test `fpga/`.

Host Side:

- `host/`: a test program runs on CPU
