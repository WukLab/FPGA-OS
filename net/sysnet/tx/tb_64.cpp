/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include <stdio.h>
#include "top_64.hpp"

using namespace hls;

#define N 10
#define NR_PACKETS 7

int main(void)
{
	ap_uint<64> frame[NR_PACKETS][N];
	stream<struct net_axis_64 > input0("tb_input0"), input1("tb_input1"), output("tb_output");
	struct net_axis_64 tmp;
	int i, packetnum;

	/* Fill frames with data */
	for (packetnum = 0; packetnum < NR_PACKETS; packetnum++) {
		for (i = 0; i < N; i++) {
			frame[packetnum][i] = (i*2) << packetnum;
		}
	}

	/* Write input data to input stream */
	for (packetnum = 0; packetnum < NR_PACKETS; packetnum++) {
		for (i = 0; i < N; i++) {
			tmp.data = frame[packetnum][i];
			tmp.tkeep = 0xFFFF;
			if (i == (N-1))
				tmp.last = 1;
			else
				tmp.last = 0;
			if (packetnum % NUM_APPS == 0) {
				printf ("input0 %llx\n",(unsigned long long) tmp.data);
				input0.write(tmp);
			}
			else {
				printf ("input1 %llx\n",(unsigned long long) tmp.data);
				input1.write(tmp);
			}
		}
	}
	/* Process and read output data */
	for (packetnum = 0; packetnum < NR_PACKETS; packetnum++) {
		printf("PACKET %d:\n",packetnum);
		for (i = 0; i < N; i++) {
			sysnet_tx_64(&input0, &input1, &output);
			tmp = output.read();
			printf("%llx\n",(unsigned long long) tmp.data);
		}
		printf("\n");
	}
}
