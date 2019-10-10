/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _SYSNET_RX_TOP_512_H_
#define _SYSNET_RX_TOP_512_H_

#include <fpga/axis_net.h>

void sysnet_rx_512(hls::stream<struct net_axis_512> *input,
		   hls::stream<struct net_axis_512> *output_0,
		   hls::stream<struct net_axis_512> *output_1);

#endif /* _SYSNET_RX_TOP_512_H_ */
