/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file is shared by both HLS and host side code.
 * Everything has to be generic.
 */

#ifndef _APP_RDMA_RDMA_H_
#define _APP_RDMA_RDMA_H_

enum APP_RDMA_OPCODE {
	/* Parsed by FPGA side */
	APP_RDMA_OPCODE_READ,
	APP_RDMA_OPCODE_WRITE,
	APP_RDMA_OPCODE_WRITE_PERSISTENT,

	/* Parsed by Host side */
	APP_RDMA_OPCODE_REPLY_READ,
};

struct app_rdma_header {
	char opcode;
	unsigned long address;
	unsigned long length;
} __attribute__((packed));

/*
 * The first two 64B units are for headers
 * All packets' data start from the third unit, thus 128
 */
#define APP_RDMA_DATA_OFFSET	(128)

#endif /* _APP_RDMA_RDMA_H_ */
