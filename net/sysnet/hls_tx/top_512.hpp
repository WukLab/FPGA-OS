/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _SYSNETTX512_H_
#define _SYSNETTX512_H_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/axis_net.h>

#define NR_SYSNET_TX_PORTS	(2)

void sysnet_tx_512(hls::stream<struct net_axis_512> input[NR_SYSNET_TX_PORTS],
		   hls::stream<struct net_axis_512> *output);

#endif /* _SYSNETTX512_H_ */
