/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file is shared by both HLS and host side code.
 * Everything has to be generic.
 */

#ifndef _APP_RDMA_RDMA_H_
#define _APP_RDMA_RDMA_H_

/*
 * This config affects both RDM and RDM_test.
 * If this option is enabled, DRAM access will be disabled.
 * This is useful if there is no DRAM tb.
 */
#if 0
# define DISABLE_DRAM_ACCESS
#endif

enum APP_RDMA_OPCODE {
	/* Parsed by FPGA side */
	APP_RDMA_OPCODE_READ = 0,
	APP_RDMA_OPCODE_WRITE = 1,
	APP_RDMA_OPCODE_WRITE_PERSISTENT = 2,
	APP_RDMA_OPCODE_ALLOC = 3,

	/* Parsed by Host side */
	APP_RDMA_OPCODE_REPLY_WRITE = 4,
	APP_RDMA_OPCODE_REPLY_ALLOC = 5,
	APP_RDMA_OPCODE_REPLY_ALLOC_ERROR = 6,

	APP_RDMA_OPCODE_REPLY_READ = 7,
	APP_RDMA_OPCODE_REPLY_READ_ERROR = 8,
};

struct app_rdma_header {
	char opcode;
	unsigned long address;
	unsigned long length;
} __attribute__((packed));

struct app_rdma_stats {
	unsigned long nr_read;
	unsigned long nr_write;

	unsigned long nr_read_units;
	unsigned long nr_write_units;
} __attribute__ ((packed));

static inline char *app_rdma_opcode_to_string(char opcode)
{
	switch (opcode) {
	case APP_RDMA_OPCODE_READ:		return (char *)"READ";
	case APP_RDMA_OPCODE_WRITE:		return (char *)"WRITE";
	case APP_RDMA_OPCODE_ALLOC:		return (char *)"ALLOC";
	case APP_RDMA_OPCODE_REPLY_ALLOC:	return (char *)"ALLOC REPLY";
	case APP_RDMA_OPCODE_REPLY_ALLOC_ERROR:	return (char *)"ALLOC REPLY ERROR";
	case APP_RDMA_OPCODE_REPLY_READ:	return (char *)"READ REPLY";
	case APP_RDMA_OPCODE_REPLY_READ_ERROR:	return (char *)"READ REPLY ERROR";
	default:				return (char *)"Unknown";
	}
	return (char *)"BUG";
}

/*
 * The first two 64B units are for headers
 * All packets' data start from the third unit, thus 128
 */
#define APP_RDMA_DATA_OFFSET	(128)

#endif /* _APP_RDMA_RDMA_H_ */
