/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _APP_RDMA_HLS_H_
#define _APP_RDMA_HLS_H_

#include <fpga/axis_net.h>

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

#endif /* _APP_RDMA_HLS_H_ */
