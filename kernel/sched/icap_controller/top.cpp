/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <string.h>
#include <fpga/kernel.h>
#include <uapi/compiler.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>
#include <hls_stream.h>

#define ICAP_DATA_WIDTH	32

using namespace hls;

void icap_controller_hls(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
			 stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
			 volatile ap_uint<1> *AVAIL_from_icap,
			 volatile ap_uint<1> *PRDONE_from_icap,
			 volatile ap_uint<1> *PRERROR_from_icap,
			 volatile ap_uint<1> *CSIB_to_icap,
			 volatile ap_uint<1> *RDWRB_to_icap)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=from_icap
#pragma HLS INTERFACE axis both port=to_icap
#pragma HLS INTERFACE ap_none port=AVAIL_from_icap
#pragma HLS INTERFACE ap_none port=PRDONE_from_icap
#pragma HLS INTERFACE ap_none port=PRERROR_from_icap
#pragma HLS INTERFACE ap_ovld port=CSIB_to_icap
#pragma HLS INTERFACE ap_ovld port=RDWRB_to_icap

	ap_uint<32> in;
	ap_uint<1> dummy;

	if (from_icap->empty())
		in = from_icap->read();

	to_icap->write(in);

	dummy = *AVAIL_from_icap;
	dummy = *PRDONE_from_icap;
	dummy = *PRERROR_from_icap;
	*CSIB_to_icap = 1;
	*RDWRB_to_icap = 0;
}
