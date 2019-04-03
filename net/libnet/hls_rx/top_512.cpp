/*
 * Copyright (c) 2019，Wuklab, Purdue University.
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
	SM_DROP,
};

#define SEQ_MSB	375
#define SEQ_LSB	344

#define SYN_MSB	377
#define SYN_LSB	377

/*
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App data              |
 */
void libnet_rx_512(hls::stream<struct net_axis_512> *input,
		   hls::stream<struct net_axis_512> *output,
		   unsigned int *seq)
{
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output
#pragma HLS INTERFACE ap_ovld port=seq

	static enum SM state = SM_IDLE;
	struct net_axis_512 current;
	static unsigned int seq_expected = 0;
	ap_uint<1> SYNC = 0;

	switch (state) {
	case SM_IDLE:
		if (input->empty())
			return;
		current = input->read();

		SYNC = current.data(SYN_MSB, SYN_LSB);
		if (SYNC == 1) {
			seq_expected = current.data(SEQ_MSB, SEQ_LSB);
			if (current.last == 1)
				state = SM_IDLE;
			else
				state = SM_DROP;
			break;
		}

		if (current.data(SEQ_MSB, SEQ_LSB) == seq_expected) {
			*seq = seq_expected + 1;
			seq_expected++;
			state = SM_STREAM;
		} else {
			state = SM_DROP;
		}

		break;
	case SM_STREAM:
		/* Forward data to application */
		if (input->empty())
			return;
		current = input->read();
		output->write(current);

		if (current.last == 1)
			state = SM_IDLE;
		break;
	case SM_DROP:
		/* Drop all the following units */
		if (input->empty())
			return;
		current = input->read();

		if (current.last == 1)
			state = SM_IDLE;
		break;
	};
}
