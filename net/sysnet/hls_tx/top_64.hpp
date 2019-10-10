/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _SYSNETTX64_H_
#define _SYSNETTX64_H_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/axis_net.h>

#define NUM_APPS    2

void sysnet_tx_64(hls::stream<struct net_axis_64> *input0,
		  hls::stream<struct net_axis_64> *input1,
		  hls::stream<struct net_axis_64> *output);

#endif /* _SYSNETTX64_H_ */
