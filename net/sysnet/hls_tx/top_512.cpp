/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_512.hpp"

using namespace hls;

enum SYSNET_TX_STATE {
	SYSNET_TX_STATE_IDLE,
	SYSNET_TX_STATE_STREAM
};

/*
 * Taking multiple input streams and output to MAC
 * Policy of choosing streams:
 * 	- Small number ports first (Current policy)
 * 	- Round Robin (RR) (Future extension)
 */
void sysnet_tx_512(hls::stream<struct net_axis_512> input[NR_SYSNET_TX_PORTS],
		   hls::stream<struct net_axis_512> *output)
{
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output

	static enum SYSNET_TX_STATE state = SYSNET_TX_STATE_IDLE;
	static int index = 0;
	struct net_axis_512 current;

	bool stream_empty[NR_SYSNET_TX_PORTS];
#pragma HLS ARRAY_PARTITION variable=stream_empty complete

	switch (state) {
	case SYSNET_TX_STATE_IDLE:
		for (int i = 0; i < NR_SYSNET_TX_PORTS; i++)
			stream_empty[i] = input[i].empty();

		for (int i = 0; i < NR_SYSNET_TX_PORTS; i++) {
			if (!stream_empty[i]) {
				index = i;
				current = input[index].read();
				output->write(current);
				if (current.last == 0)
					state = SYSNET_TX_STATE_STREAM;
				break;
			}
		}
		break;
	case SYSNET_TX_STATE_STREAM:
		if (!input[index].empty()) {
			current = input[index].read();
			output->write(current);
			if (current.last == 1)
				state = SYSNET_TX_STATE_IDLE;
		}
		break;
	};
}
