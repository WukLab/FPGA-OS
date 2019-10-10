/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <stdio.h>
#include "top_64.hpp"

using namespace hls;

#define N 10
#define NR_PACKETS 2
#define NR_DATABEATS 4

int main(void)
{
	ap_uint<64> frame[NR_PACKETS][N];
	frame[0][0] = 0xAABBDDEEDDEEDDEE; // MAC DEST =0xDDEEDDEEDDEE;
	frame[0][1] = 0xFFFF0806AABBAABB; // Ethtype = 0x0806; MAC SRC = 0xAABBAABBAABB
	frame[0][2] = 0xFFFFFFFFFFFFFFFF; // IP Header is all F for words 0 - 4
	frame[0][3] = 0xFFFFFFFFFFFFFFFF;
	frame[0][4] = 0x232323232323FFFF; // UDP header = 0x2323232323232323
	frame[0][5] = 0x9999999900002323; // Appid = 0x0000 (output0); seqnum = 0x99999999
	frame[0][6] = 0x1111111111111111; // data payload
	frame[0][7] = 0x2222222222222222;
	frame[0][8] = 0x3333333333333333;
	frame[0][9] = 0x4444444444444444;

	frame[1][0] = 0xAABB889988998899; // MAC DEST =0x889988998899;
	frame[1][1] = 0xFFFF0806AABBAABB; // Ethtype = 0x0806; MAC SRC = 0xAABBAABBAABB
	frame[1][2] = 0xFFFFFFFFFFFFFFFF; // IP Header is all F for words 0 - 4
	frame[1][3] = 0xFFFFFFFFFFFFFFFF;
	frame[1][4] = 0x232323232323FFFF; // UDP header = 0x2323232323232323
	frame[1][5] = 0x9999999911112323; // Appid = 0x1111 (output0); seqnum = 0x99999999
	frame[1][6] = 0x5555555555555555; // data payload
	frame[1][7] = 0x6666666666666666;
	frame[1][8] = 0x7777777777777777;
	frame[1][9] = 0x8888888888888888;

	stream<struct net_axis_64> input("tb_input");
	stream<struct net_axis_64> output0("tb_output0"), output1("tb_output1");
	struct net_axis_64 tmp;
	int i, packetnum;

	/* Write input data to input stream */
	for (packetnum = 0; packetnum < NR_PACKETS; packetnum++) {
		for (i = 0; i < N; i++) {
			tmp.data = frame[packetnum][i];
			//tmp.tkeep = 0xFFFF;
			if (i == (N-1))
				tmp.last = 1;
			else
				tmp.last = 0;
			//printf ("input %llx\n",(unsigned long long) tmp.data);
			input.write(tmp);
		}
	}
	/* Let it process */

	for (i = 0; i < (N - NR_DATABEATS - 1)*NR_PACKETS; i++) {
		sysnet_rx_64(&input, &output0, &output1);
	}
	printf("Processing done...\n");

	/* Get output0 data */

	for (i = 0; i < NR_DATABEATS + 1; i++) {
		sysnet_rx_64(&input,&output0,&output1);
		output0.read(tmp);
		printf ("output0 %llx\n",(unsigned long long) tmp.data);
	}

	/* Get output1 data */

	for (i = 0; i < NR_DATABEATS + 1; i++) {
		sysnet_rx_64(&input,&output0,&output1);
		output1.read(tmp);
		printf ("output1 %llx\n",(unsigned long long) tmp.data);
	}

	return 0;
}
