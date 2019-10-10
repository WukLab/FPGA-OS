/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>

#include <fpga/axis_net.h>
#include <uapi/net_header.h>

enum SM {
	SM_IDLE,
	SM_STREAM,
};

void libnet_rx_256(hls::stream<struct net_axis_256> *input,
		   hls::stream<struct net_axis_256> *data_out,
		   hls::stream<struct net_axis_256> *ack_out)
{
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=data_output
#pragma HLS INTERFACE axis both port=ack_output

	static enum SM state = SM_IDLE;
	struct net_axis_256 current;
	static struct net_axis_256 tmp_ack;
	static int i = 1;

	switch (state) {
	case SM_IDLE:
		if (input->empty())
			break;
		current = input->read();
		data_out->write(current);

		tmp_ack.data(31, 0) = i++;
		tmp_ack.keep = 0xFFFFFFFF;
		tmp_ack.last = 1;
		ack_out->write(tmp_ack);

		state = SM_STREAM;
		break;
	case SM_STREAM:
		if (input->empty())
			break;
		current = input->read();
		data_out->write(current);

		if (current.last == 1)
			state = SM_IDLE;
		break;
	};
}
