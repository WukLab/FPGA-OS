/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <stdio.h>
#include <stdlib.h>
#include "../include/rdma.h"
#include "../include/hls.h"

using namespace hls;

void app_rdma_test(hls::stream<struct net_axis_512> *from_net,
		   hls::stream<struct net_axis_512> *to_net,
		   unsigned long *dram, volatile unsigned long *tsc,
		   volatile struct app_rdma_stats *stats,
		   volatile unsigned int *test_state);

/*
 * Packet
 * 	64B | Eth | IP | UDP | Lego |
 * 	64B | App header |    pad   |
 * 	64B |          Data         | (if write)
 * 	...
 * 	N B |          Data         |
 */
#define NR_TOP_RUN	(10)
int main(void)
{
	unsigned long *dram;
	int i, j, k, nr_req;
	struct net_axis_512 tmp;
	stream<struct net_axis_512> input, output;
	volatile unsigned long tsc = 0;
	bool app_hdr, eth_hdr;
	struct app_rdma_stats stats;
	unsigned int test_state;

	dram = (unsigned long *)malloc(10000);

#define NR_PRE_INPUT	(100)
	for (i = 0; i < NR_PRE_INPUT; i++) {
		if (i % 4  == 0)
			tmp.last = 1;
		else
			tmp.last = 0;
		input.write(tmp);
	}

	j = 0;
	app_rdma_test(&input, &output, dram, &tsc, &stats, &test_state);

	printf("DRAM Contents:\n");
	for (i = 0; i < 32; i++)
		printf("dram[%d] %llu\n", i, dram[i]);

	/*
	 * Verilog results
	 * - Write: Check buf content
	 * - Read: check output stream content
	 */
#define NR_BYTES_PER_LINE	(32)
	printf("Network output Content: \n");

	eth_hdr = true;
	app_hdr = false;
	nr_req = i = j = k = 0;

	while (!output.empty()) {
		char opcode;
		unsigned long address, length;

		tmp = output.read();

		if (eth_hdr) {
			eth_hdr = false;
			app_hdr = true;
		} else if (app_hdr) {
			opcode = get_hdr_opcode(&tmp);
			address = get_hdr_address(&tmp);
			length = get_hdr_length(&tmp);

			printf("Request %d Opcode: %s Address: %llx Length: %llx\n",
				nr_req++, app_rdma_opcode_to_string(opcode),
				address, length);
			app_hdr = false;
		}

		/* End of a request, reset states */
		if (tmp.last.to_uint() == 1) {
			eth_hdr = true;
			app_hdr = false;
		}

		printf("    Unit[%d] last=%d keep=%#llx\n", k, tmp.last.to_uint(), tmp.keep.to_ulong());
		for (j = 0; j < NR_BYTES_AXIS_512; j++) {
			int start, end;
			unsigned char c;

			start = j * 8;
			end = (j + 1) * 8 - 1;
			c = tmp.data(end, start).to_uint();

			if (i % NR_BYTES_PER_LINE == 0)
				printf("\t[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
			printf("%02x ", c);
			if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
				printf("\n");
			i++;
		}
		k++;
	}
}
