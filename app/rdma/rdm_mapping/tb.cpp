/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <fpga/axis_net.h>
#include <fpga/axis_buddy.h>
#include <uapi/net_header.h>
#include <uapi/compiler.h>

#include <stdio.h>
#include <stdlib.h>

#include "top.hpp"
#include "../include/rdma.h"

using namespace hls;

void rdm_mapping(stream<struct net_axis_512> *from_net,
	         stream<struct net_axis_512> *to_net,
	         ap_uint<512> *dram,
		 stream<struct buddy_alloc_if> *alloc_req,
		 stream<struct buddy_alloc_ret_if> *alloc_ret,
		 stream<struct mapping_request> *map_req,
		 stream<struct mapping_reply> *map_ret);

#define NR_UNITS_PER_PKT	(2)
#define NR_PACKETS		(3)
#define BUF_SIZE		(1024)

int main(void)
{
	int i, j, k;
	struct net_axis_512 tmp;
	stream<struct net_axis_512> input, output;
	char *dram;

	stream<struct mapping_request> map_req;
	stream<struct mapping_reply> map_ret;
	stream<struct buddy_alloc_if> alloc_req;
	stream<struct buddy_alloc_ret_if> alloc_ret;

	dram = (char *)malloc(BUF_SIZE);
	if (!dram) {
		printf("Unable to malloc\n");
		return -1;
	}
	memset(dram, 0x0, BUF_SIZE);

	if ((NR_UNITS_PER_PKT * NR_BYTES_AXIS_512) > BUF_SIZE) {
		printf("Message size larger than buffer size, write may overflow\n");
		exit(-1);
	}
	if (NR_UNITS_PER_PKT < 2) {
		printf("Must have at least 2 units\n");
		exit(-1);
	}

	/*
	 * Packet
	 * 	64B | Eth | IP | UDP | Lego |
	 * 	64B | App header |    pad   |
	 * 	64B |          Data         | (if write)
	 * 	...
	 * 	N B |          Data         |
	 */
	for (i = 0; i < NR_PACKETS; i++) {
next_pkt:
		for (j = 0; j < NR_UNITS_PER_PKT; j++) {
			tmp.last = 0;
			tmp.data = 0;
			tmp.keep = 0;

			for (k = 0; k < NR_BYTES_AXIS_512; k++) {
				int start, end;

				start = k * NR_BITS_PER_BYTE;
				end = (k + 1) * NR_BITS_PER_BYTE - 1;

				tmp.data(end, start) = k + 1;
				tmp.keep(k, k) = 1;
			}

			/* The first packet: WRITE */
			if (i == 10000) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				}
				/* The second unit is app header */
				if (j == 1) {
					tmp.data(7, 0) = APP_RDMA_OPCODE_WRITE;
					tmp.data(71, 8) = 0x0;	// addr
					tmp.data(135, 72) = 64; // len
				}
			}

			/* The second packet: READ */
			if (i == 1 || i == 0) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				} else if (j == 1) {
				/* The second unit is app header */
					tmp.data(7, 0) = APP_RDMA_OPCODE_READ;
					tmp.data(71, 8) = 0;	//addr
					tmp.data(135, 72) = 64; //len

					/* Read should only have two units */
					tmp.last = 1;
					input.write(tmp);
					break;
				} else
					exit(-1);
			}

			/* The second packet: READ */
			if (i == 2) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				} else if (j == 1) {
				/* The second unit is app header */
					tmp.data(7, 0) = APP_RDMA_OPCODE_ALLOC;
					tmp.data(71, 8) = 0; //unused
					tmp.data(135, 72) = 64; //len in bytes

					/* alloc should only have two units */
					tmp.last = 1;
					input.write(tmp);
					break;
				} else
					exit(-1);
			}

			/* Last unit of the pkt */
			if (j == (NR_UNITS_PER_PKT - 1))
				tmp.last = 1;
			else
				tmp.last = 0;
			input.write(tmp);
		}
	}

	for (i = 0; i < NR_PACKETS * NR_UNITS_PER_PKT * 100; i++) {
		rdm_mapping(&input, &output, (ap_uint<512> *)dram,
			&alloc_req, &alloc_ret, &map_req, &map_ret);
	
		if (!alloc_req.empty()) {
			struct buddy_alloc_if req;
			struct buddy_alloc_ret_if ret;

			req = alloc_req.read();
			printf("Alloc Request: opcode: %d addr: %x order %d\n",
				req.opcode.to_uint(), req.addr.to_uint(),
				req.order.to_uint());

			ret.stat = 0;
			ret.addr = 0x101;
			alloc_ret.write(ret);
		}

		if (!map_req.empty()) {
			struct mapping_request req;
			struct mapping_reply ret;

			req = map_req.read();
			printf("Map Request: opcode: %d addr(key): %#x length(val) %#x\n",
				req.opcode.to_uint(), req.address.to_uint(),
				req.length.to_uint());

			ret.status = 0;
			ret.address = 0x200;
			map_ret.write(ret);
		}
	}


	/*
	 * Verilog results
	 * - Write: Check buf content
	 * - Read: check output stream content
	 */

#define NR_BYTES_PER_LINE	(64)
	printf("DRAM Content:\n");
	for (i = 0; i < BUF_SIZE; i++) {
		if (i % NR_BYTES_PER_LINE == 0)
			printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
		printf("%02x ", dram[i]);
		if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
			printf("\n");
	}

	printf("Read Content: \n");

	i = j = 0;
	while (!output.empty()) {
		tmp = output.read();
		printf("unit[%d] last=%d keep=%#llx\n", i, tmp.last.to_uint(), tmp.keep.to_ulong());
		for (j = 0; j < NR_BYTES_AXIS_512; j++) {
			int start, end;
			unsigned char c;

			start = j * NR_BITS_PER_BYTE;
			end = (j + 1) * NR_BITS_PER_BYTE - 1;
			c = tmp.data(end, start).to_uint();

			if (i % NR_BYTES_PER_LINE == 0)
				printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
			printf("%02x ", c);
			if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
				printf("\n");
			i++;
		}
	}
}
