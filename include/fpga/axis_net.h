/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file descirbes network interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_NET_
#define _LEGO_FPGA_AXIS_NET_

#include <ap_axi_sdata.h>
#include <hls_stream.h>

struct net_axis_64 {
	ap_uint<64>		data;
	ap_uint<1>		last;
	ap_uint<1>		tuser;
	ap_uint<8> 		tkeep;
};

struct net_axis_512 {
	ap_uint<512>		data;
	ap_uint<1>		last;
};

#endif /* _LEGO_FPGA_AXIS_NET_ */
