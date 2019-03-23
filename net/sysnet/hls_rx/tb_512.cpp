/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "top_512.hpp"

using namespace hls;

int main(void)
{
	stream<struct net_axis_512> input;
	stream<struct net_axis_512> output_0, output_1;
	struct net_axis_512 tmp;
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
			 * Make the 64B unit packet special
			 * So to test tlast
			 */
			if (j == (nr_units_per_packet - 1))
				BYTES = 5;
			else
				BYTES = 64;

			for (k = 0; k < BYTES; k++) {
				int start, end;

				start = k * 8;
				end = (k + 1) * 8 - 1;

				tmp.data(end, start) = k + 1;
			}

			/* Last 64B unit */
			if (j == (nr_units_per_packet - 1))
				tmp.last = 1;

			input.write(tmp);
		}
	}

	for (i = 0; i < nr_packets * nr_units_per_packet; i++) {
		sysnet_rx_512(&input, &output_0, &output_1);
	}

	/* Get output and print packets */
	for (i = 0; i < nr_packets * nr_units_per_packet; i++) {
		tmp = output_0.read();

		printf("last=%u\n", tmp.last.to_uint());

		for (k = 0; k < 64; k++) {
			int start, end;

			start = k * 8;
			end = (k + 1) * 8 - 1;
			c = tmp.data(end, start);
			printf("[%x] ", c);
		}
		printf("\n");
	}
}
