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
#include <uapi/net_header.h>

#define NR_BYTES_AXIS_64	(8)
#define NR_BYTES_AXIS_256	(32)
#define NR_BYTES_AXIS_512	(64)

struct net_axis_64 {
	ap_uint<64>			data;
	ap_uint<1>			last;
	ap_uint<NR_BYTES_AXIS_64>	keep;
	ap_uint<NR_BYTES_AXIS_64>	user;
};

/*
 * For 256b version, we will have this header format:
 * | Eth Header | App Header |
 * 0            112
 * There will not be other headers.
 */
struct net_axis_256 {
	ap_uint<256>			data;
	ap_uint<1>			last;
	ap_uint<NR_BYTES_AXIS_256>	keep;
	ap_uint<NR_BYTES_AXIS_256>	user;
};

struct net_axis_512 {
	ap_uint<512>			data;
	ap_uint<1>			last;
	ap_uint<NR_BYTES_AXIS_512>	keep;
	ap_uint<NR_BYTES_AXIS_512>	user;
};

static inline void set_app_id(struct net_axis_512 *net_axis, int app_id)
{
#pragma HLS INLINE
	net_axis->data(LEGO_HEADER_APP_ID_BITS_END,
		       LEGO_HEADER_APP_ID_BITS_START) = app_id;
}

static inline int get_app_id(struct net_axis_512 *net_axis)
{
#pragma HLS INLINE
	int app_id;
	app_id = net_axis->data(LEGO_HEADER_APP_ID_BITS_END,
				LEGO_HEADER_APP_ID_BITS_START);
	return app_id;
}

#endif /* _LEGO_FPGA_AXIS_NET_ */
