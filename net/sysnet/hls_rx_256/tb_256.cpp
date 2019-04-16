/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include <fpga/axis_net.h>
#include "top_256.hpp"

using namespace hls;

void sysnet_rx_256(hls::stream<struct net_axis_256> *input,
		   hls::stream<struct net_axis_256> output[NR_OUTPUTS]);

int main(void)
{
	stream<struct net_axis_256> input;
	stream<struct net_axis_256> output[NR_OUTPUTS];
	struct net_axis_256 tmp;
	char c;
	int i, j, k, nr_packets, nr_units_per_packet;
	int BYTES;

	nr_packets = 2;
	nr_units_per_packet = 2;

	for (i = 0; i < nr_packets; i++) {
		for (j = 0; j < nr_units_per_packet; j++) {
			tmp.last = 0;
			tmp.data = 0;
			tmp.keep = 0;

			/*
			 * Make the unit packet special
			 * So to test tlast
			 */
			if (j == (nr_units_per_packet - 1))
				BYTES = 5;
			else
				BYTES = 32;

			for (k = 0; k < BYTES; k++) {
				int start, end;

				start = k * 8;
				end = (k + 1) * 8 - 1;

				tmp.data(end, start) = k + 1;
			}

			/* the first unit has lego header */
			if (j == 0) {
				tmp.data(119, 112) = i;
			}

			/* Last unit */
			if (j == (nr_units_per_packet - 1))
				tmp.last = 1;

			input.write(tmp);
		}
	}

	for (i = 0; i < nr_packets * nr_units_per_packet; i++) {
		sysnet_rx_256(&input, output);
		for (j = 0; j < NR_OUTPUTS; j++) {
			if (output[j].empty()) {
				printf(" Output[%d] Empty\n", j);
			} else {
				output[j].read();
				printf(" Output[%d] D\n", j);
			};
		}
	}
}
