/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _NET_HPP_
#define _NET_HPP_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#define NET_DATA_WIDTH	(64)

template <int N>
struct net_axis {
	ap_uint<N>	data;
	ap_uint<1>	last;
};

#endif /* _NET_HPP_ */
