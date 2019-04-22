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
#include "../include/hls.h"

using namespace hls;

void rdm_segment(stream<struct net_axis_512> *from_net,
	         stream<struct net_axis_512> *to_net,
		 stream<struct buddy_alloc_if> *alloc_req,
		 stream<struct buddy_alloc_ret_if> *alloc_ret,
		 stream<struct dm_cmd> *DRAM_rd_cmd,
		 stream<struct dm_cmd> *DRAM_wr_cmd,
		 stream<struct axis_mem> *DRAM_rd_data,
		 stream<struct axis_mem> *DRAM_wr_data,
		 stream<ap_uint<8> > *DRAM_rd_status,
		 stream<ap_uint<8> > *DRAM_wr_status);

#define NR_UNITS_PER_PKT	(6)
#define NR_PACKETS		(4)
#define BUF_SIZE		(1024)

int main(void)
{
	int i, j, k;
	struct net_axis_512 tmp;
	stream<struct net_axis_512> input, output;
	char *dram;

	stream<struct buddy_alloc_if> alloc_req;
	stream<struct buddy_alloc_ret_if> alloc_ret;

	stream<struct dm_cmd> DRAM_rd_cmd, DRAM_wr_cmd;
	stream<ap_uint<8> > DRAM_rd_status, DRAM_wr_status;
	stream<struct axis_mem> DRAM_rd_data, DRAM_wr_data;

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
			if (i == 3) {
				/* The first unit is eth/ip/udp/lego header */
				if (j == 0) {
					tmp.data(47, 0) = 0xAABBCCDDEEFF;
				}
				/* The second unit is app header */
				if (j == 1) {
					tmp.data(7, 0) = APP_RDMA_OPCODE_WRITE;
					tmp.data(71, 8) = 0x0;	// addr
					tmp.data(135, 72) = 256; // len
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
					tmp.data(135, 72) = 62; //len

					/* Read should only have two units */
					tmp.last = 1;
					input.write(tmp);
					break;
				} else
					exit(-1);
			}

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

	for (i = 0; i < 500; i++) {
		rdm_segment(&input, &output,
			&alloc_req, &alloc_ret,
			&DRAM_rd_cmd, &DRAM_wr_cmd,
			&DRAM_rd_data, &DRAM_wr_data,
			&DRAM_rd_status, &DRAM_wr_status);
	
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

		if (!DRAM_rd_cmd.empty()) {
			struct dm_cmd cmd = DRAM_rd_cmd.read();
			unsigned int length, address;
			unsigned int nr_units;

			address = cmd.start_address.to_uint();
			length = cmd.btt.to_uint();
			nr_units = length/NR_BYTES_AXIS_512;
			printf("DRAM rd cmd: address: %x length %x nr_Units: %d\n",
				address, length, nr_units);

#if 1
			for (int k = 0; k < nr_units; k++) {
				struct axis_mem in;
				printf("asd\n");
				in.data = k+1;
				DRAM_rd_data.write(in);
			}
#endif
		}

		if (!DRAM_wr_cmd.empty()) {
			struct dm_cmd cmd = DRAM_wr_cmd.read();
			unsigned int length, address;

			address = cmd.start_address.to_uint();
			length = cmd.btt.to_uint();
			printf("DRAM wr cmd: address: %x length %x\n",
				address, length);
		}

		if (!DRAM_wr_data.empty()) {
			DRAM_wr_data.read();
			printf("DRAM wr data: got it\n");
		}
	}

	/*
	 * Verilog results
	 * - Write: Check buf content
	 * - Read: check output stream content
	 */
#define NR_BYTES_PER_LINE	(64)
#if 1
	printf("DRAM Content:\n");
	for (i = 0; i < BUF_SIZE; i++) {
		if (i % NR_BYTES_PER_LINE == 0)
			printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
		printf("%02x ", dram[i]);
		if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
			printf("\n");
	}
#endif
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
