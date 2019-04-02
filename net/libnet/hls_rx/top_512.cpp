/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_512.hpp"

#include <fpga/axis_net.h>
#include <uapi/net_header.h>

void libnet_rx_512(hls::stream<struct net_axis_512> *input,
		   hls::stream<struct net_axis_512> *output)
{
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output


}
