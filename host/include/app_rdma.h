/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _APP_RDMA_H_
#define _APP_RDMA_H_

/*
 * header definition is directly copied from
 * ../../FPGA/app/rdma/include/rdma.h
 *
 * !!! KEEP this file and original file sync
 */

enum APP_RDMA_OPCODE {
	/* Parsed by FPGA side */
	APP_RDMA_OPCODE_READ,
	APP_RDMA_OPCODE_WRITE,
	APP_RDMA_OPCODE_WRITE_PERSISTENT,
	APP_RDMA_OPCODE_ALLOC,

	/* Parsed by Host side */
	APP_RDMA_OPCODE_REPLY_ALLOC,
	APP_RDMA_OPCODE_REPLY_ALLOC_ERROR,

	APP_RDMA_OPCODE_REPLY_READ,
	APP_RDMA_OPCODE_REPLY_READ_ERROR,
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

#endif /* _APP_RDMA_H_ */