/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "top.hpp"

using namespace hls;

#define N 20
#define NR_PACKETS 3

int main(void)
{
	stream<struct net_axis<NET_DATA_WIDTH> > input("tb_input"), output("tb_output");
	struct net_axis<NET_DATA_WIDTH> tmp = {0, 0};
	int i, nr_packets;

	/* Write input data to input stream */
	for (nr_packets = 0; nr_packets < NR_PACKETS; nr_packets++) {
		for (i = 0; i < N; i++) {
			tmp.data = i + 1;

			if (i == (N-1))
				tmp.last = 1;
			else
				tmp.last = 0;

			input.write(tmp);
		}
	}
	printf("Input done...\n");

	/* Let it process */
	for (i = 0; i < (N * NR_PACKETS*2); i++) {
		sysnet_tx(&input, &output);
	}
	printf("Processing done...\n");

	/* Get output data */
	i = 0;
	while (!output.empty()) {
		tmp = output.read();

		printf("[%2d] data: %d last: %d\n",
			i++, tmp.data.to_int(), tmp.last.to_int());
	}

	return 0;
}

