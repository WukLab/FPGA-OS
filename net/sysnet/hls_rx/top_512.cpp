/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_512.hpp"

#include <fpga/axis_net.h>
#include <uapi/net_header.h>

enum SYSNET_RX_STATE {
	SYSNET_RX_IDLE,
	SYSNET_RX_STREAM,
};

/*
 * FIXME
 * Need better error handling, sth like output_err
 */
#define RX_DISPATCH(current, APP_ID)			\
	do {						\
		switch (APP_ID) {			\
		case 0:					\
			output_0->write(current);	\
			break;				\
		case 1:					\
			output_1->write(current);	\
			break;				\
		default:				\
			output_0->write(current);	\
			break;				\
		};					\
	} while (0)

/*
 * We could get 64B at each cycle. We are able to inspect
 * Ethernet/IP/UDP/Lego headers at once and once for all.
 */
void sysnet_rx_512(hls::stream<struct net_axis_512> *input,
		   hls::stream<struct net_axis_512> *output_0,
		   hls::stream<struct net_axis_512> *output_1)
{
/* Port-level */
#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output_0
#pragma HLS INTERFACE axis both port=output_1

/* Block-level */
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum SYSNET_RX_STATE state = SYSNET_RX_IDLE;
	static char APP_ID = 0;
	struct net_axis_512 current;

	switch (state) {
	case SYSNET_RX_IDLE:
		if (input->empty())
			break;
		current = input->read();

		APP_ID = current.data(LEGO_HEADER_APP_ID_BITS_END,
				      LEGO_HEADER_APP_ID_BITS_START);
		RX_DISPATCH(current, APP_ID);

		/*
		 * Assume the packet is at least larger than 64B for now.
		 * This is based on another assumption: ETH/IP/UDP/Lego
		 * headers combined all together is equal or larger than 64B.
		 */
		state = SYSNET_RX_STREAM;
		break;
	case SYSNET_RX_STREAM:
		if (input->empty())
			break;
		current = input->read();
		RX_DISPATCH(current, APP_ID);

		/* End of a frame */
		if (current.last) {
			state = SYSNET_RX_IDLE;
			APP_ID = 0;
		}
		break;
	};
}
