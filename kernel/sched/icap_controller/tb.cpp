/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <string.h>
#include <fpga/kernel.h>
#include <uapi/compiler.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>
#include <hls_stream.h>
#include "internal.h"

using namespace hls;

void icap_controller_hls(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
			 stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
			 volatile ap_uint<1> *AVAIL_from_icap,
			 volatile ap_uint<1> *PRDONE_from_icap,
			 volatile ap_uint<1> *PRERROR_from_icap,
			 volatile ap_uint<1> *CSIB_to_icap,
			 volatile ap_uint<1> *RDWRB_to_icap);


#define NR_CYCLES 100

int main(void)
{
	int nr_cycles;
	stream<ap_uint<ICAP_DATA_WIDTH> > from_icap, to_icap;
	ap_uint<1> AVAIL, PRDONE, PRERROR;
	ap_uint<1> CSIB, RDWRB;
	ap_uint<ICAP_DATA_WIDTH> data;

	AVAIL = 0;
	PRDONE = 1;
	PRERROR = 0;

	data = 0x11;
	from_icap.write(data);

	for (nr_cycles = 0; nr_cycles < NR_CYCLES; nr_cycles++) {

		if (nr_cycles == 10)
			AVAIL = 1;

		icap_controller_hls(&from_icap, &to_icap,
				    &AVAIL, &PRDONE, &PRERROR,
				    &CSIB, &RDWRB);

		if (!to_icap.empty()) {
			data = to_icap.read();
		}

		printf("[Cycle %3d] CSIB %d RDWRB %d data %x\n",
			nr_cycles, CSIB.to_int(), RDWRB.to_int(), data.to_int());
	}
}
