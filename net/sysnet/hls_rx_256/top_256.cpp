/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_256.hpp"

#include <fpga/axis_net.h>
#include <uapi/net_header.h>

enum SYSNET_RX_STATE {
	SYSNET_RX_IDLE,
	SYSNET_RX_STREAM,
};

void sysnet_rx_256(hls::stream<struct net_axis_256> *input,
		   hls::stream<struct net_axis_256> output[NR_OUTPUTS])
{
/* Port-level */
#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output

/* Block-level */
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum SYSNET_RX_STATE state = SYSNET_RX_IDLE;
	static char APP_ID = 0;
	struct net_axis_256 current;

	switch (state) {
	case SYSNET_RX_IDLE:
		if (input->empty())
			break;
		current = input->read();

		/*
 		 * | Eth Header | App Header | .... |
 		 * 0            112b         X      256b
		 */
		APP_ID = current.data(119, 112);
		APP_ID = APP_ID % NR_OUTPUTS;
		output[APP_ID].write(current);

		state = SYSNET_RX_STREAM;
		break;
	case SYSNET_RX_STREAM:
		if (input->empty())
			break;
		current = input->read();
		output[APP_ID].write(current);

		/* End of a frame */
		if (current.last) {
			state = SYSNET_RX_IDLE;
			APP_ID = 0;
		}
		break;
	};
}
