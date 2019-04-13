/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file is shared by both HLS and host side code.
 * Everything has to be generic.
 */

#ifndef _APP_RDMA_RDMA_H_
#define _APP_RDMA_RDMA_H_

#include <fpga/axis_net.h>

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

static inline void set_hdr_opcode(struct net_axis_512 *hdr, char op)
{
#pragma HLS INLINE
	hdr->data(7, 0) = op;
}

static inline void set_hdr_address(struct net_axis_512 *hdr,
				   unsigned long address)
{
#pragma HLS INLINE
	hdr->data(71, 8) = address;
}

static inline void set_hdr_length(struct net_axis_512 *hdr,
				  unsigned long length)
{
#pragma HLS INLINE
	hdr->data(135, 72) = length;
}

static inline unsigned char get_hdr_opcode(struct net_axis_512 *hdr)
{
#pragma HLS INLINE
	return hdr->data(7, 0);
}

static inline unsigned long get_hdr_address(struct net_axis_512 *hdr)
{
#pragma HLS INLINE
	return hdr->data(71, 8);
}

static inline unsigned long get_hdr_length(struct net_axis_512 *hdr)
{
#pragma HLS INLINE
	return hdr->data(135, 72);
}

#endif /* _APP_RDMA_RDMA_H_ */
