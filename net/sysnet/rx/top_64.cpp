/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_64.hpp"

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

void sysnet_rx_64(stream<struct my_axis<FIFO_WIDTH> > *input,
		  stream<struct my_axis<FIFO_WIDTH> > *output0,
		  stream<struct my_axis<FIFO_WIDTH> > *output1)
{
/* Port-level */
#pragma HLS INTERFACE axis both port=input
#pragma HLS INTERFACE axis both port=output0
#pragma HLS INTERFACE axis both port=output1

/* Block-level */
#pragma HLS PIPELINE II=1 enable_flush
#pragma HLS INTERFACE ap_ctrl_none port=return

	static int state = PARSER_ETH0;
	my_axis<FIFO_WIDTH> current;

	eth_header_t eth_header;
	ip_header_t ip_header;
	ap_uint<64> udp_header;
	lego_header_t lego_header;

	switch(state) {

	case(PARSER_ETH0):
			current = input->read();
			eth_header.mac_dest = current.data(47,0);
			eth_header.mac_src(15,0) = current.data(63,48);
			state = PARSER_ETH1;
			break;

	case(PARSER_ETH1):
			current = input->read();
			eth_header.mac_src(47,16) = current.data(31,0);
			eth_header.mac_type = current.data(47,32);
			ip_header.word0(15,0) = current.data(63,48);
			state = PARSER_IP0;
			break;

	case(PARSER_IP0):
			current = input->read();
			ip_header.word0(31,16) = current.data(15,0);
			ip_header.word1 = current.data(47,16);
			ip_header.word2(15,0) = current.data(63,48);
			state = PARSER_IP1;
			break;

	case(PARSER_IP1):
			current = input->read();
			ip_header.word2(31,16) = current.data (15,0);
			ip_header.word3 = current.data(47,16);
			ip_header.word4(15,0) = current.data(63,48);
			state = PARSER_UDP;
			break;

	case(PARSER_UDP):
			current = input->read();
			ip_header.word4(31,16) = current.data(15,0);
			udp_header(47,0) = current.data(63,16);
			state = PARSER_LEGO;
			break;

	case(PARSER_LEGO):
			current = input->read();
			udp_header(63,48) = current.data(15,0);
			lego_header.appid = current.data(31,16);
			lego_header.seqnum = current.data(63,32);
			if ((unsigned char) lego_header.appid ==  0){
				output0->write(current);
			}
			else {
				output1->write(current);
			}
			if (current.last) {
				state = PARSER_ETH0;
			}
			state = PARSER_SM_STREAM;
			break;

	case(PARSER_SM_STREAM):
			current = input->read();
			if ((unsigned char) lego_header.appid ==  0){
				output0->write(current);
			}
			else {
				output1->write(current);
			}
			if (current.last) {
				state = PARSER_ETH0;
			}
			break;
	}
}
