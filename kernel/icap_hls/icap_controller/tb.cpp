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
			 volatile ap_uint<1> *RDWRB_to_icap,
			 volatile ap_uint<1> *start_test);

void dump_all_COMMAND_regs_1(void)
{
	int i;
	unsigned int cmd;
	struct icap_register_entry entry;

	for (i = 0; i < NR_ICAP_REG; i++) {
		cmd = cook_cmd(i);
		entry = icap_register_table[i];

		printf("[%2d] addr %#14lx. CMD: %#32lx\n",
			i, entry.addr.to_uint(), cmd);
	}
}

#define NR_CYCLES 100

int main(void)
{
	int nr_cycles;
	stream<ap_uint<ICAP_DATA_WIDTH> > from_icap, to_icap;
	ap_uint<1> AVAIL, PRDONE, PRERROR;
	ap_uint<1> CSIB, RDWRB;
	ap_uint<1> start_test;
	ap_uint<ICAP_DATA_WIDTH> data = 0;

	AVAIL = 0;
	PRDONE = 1;
	PRERROR = 0;

	start_test = 0;

	dump_all_COMMAND_regs_1();

	printf("%#lx\n",
		0x28018001 & ~ICAP_T1_REGADDR_MASK);

	for (nr_cycles = 0; nr_cycles < NR_CYCLES; nr_cycles++) {

		if (nr_cycles == 10)
			AVAIL = 1;
		if (nr_cycles == 15)
			start_test = 1;

		icap_controller_hls(&from_icap, &to_icap,
				    &AVAIL, &PRDONE, &PRERROR,
				    &CSIB, &RDWRB,
				    &start_test);

		if (RDWRB == ICAP_RDWRB_READ && CSIB == ICAP_CSIB_ENABLE) {
			data = 0x11;
			from_icap.write(data);
		}

		if (!to_icap.empty()) {
			data = to_icap.read();
		}

		printf("[Cycle %3d] CSIB %d RDWRB %d data %x %s\n",
			nr_cycles, CSIB.to_int(), RDWRB.to_int(), data.to_int(),
			((RDWRB == ICAP_RDWRB_WRITE) & (CSIB == ICAP_CSIB_ENABLE))? "[Valid write data]" : "[no write]");
	}
}
