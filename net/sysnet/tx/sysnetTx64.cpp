#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "sysnetTx64.hpp"

using namespace hls;


enum parser_state {
	PARSER_ETH0 = 0,
	PARSER_ETH1,
	PARSER_IP0,
	PARSER_IP1,
	PARSER_UDP,
	PARSER_LEGO,
	PARSER_SM_STREAM,
};

void tx_func(hls::stream<struct my_axis<FIFO_WIDTH> > *input0,
	      hls::stream<struct my_axis<FIFO_WIDTH> > *input1,
		  hls::stream<struct my_axis<FIFO_WIDTH> > *output) {


	#pragma HLS INTERFACE axis both port=input0
	#pragma HLS INTERFACE axis both port=input1
	#pragma HLS INTERFACE axis both port=output
	#pragma HLS INTERFACE ap_ctrl_none port=return

	enum arbiter_state {
		APP0 = 0,
		APP1,
	};

	#pragma HLS PIPELINE II=1 enable_flush
	static unsigned long count = 0;
	my_axis<FIFO_WIDTH> current;

	switch (count) {
	case APP0:
		if (input0->empty()) {
			count = (count+1) % NUM_APPS;
			break;
		}
		current = input0->read();
		output->write(current);
		if (current.last == 1) {
			count = (count+1) % NUM_APPS;
		}
		break;

	case APP1:
		if (input1->empty()) {
			count = (count+1) % NUM_APPS;
			break;
		}
		current = input1->read();
		output->write(current);
		if (current.last == 1) {
			count = (count+1) % NUM_APPS;
		}
		break;
	}
}
