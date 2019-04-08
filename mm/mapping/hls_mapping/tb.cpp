/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "top.hpp"
#include "dm.hpp"

using namespace hls;

#define DEBUG

#ifndef DEBUG
# define dp(fmt, ...)	do { } while (0)
#else
# define dp(fmt, ...)	printf(fmt, ##__VA_ARGS__)
#endif

int main(void)
{
	stream<struct paging_request> in_read, in_write;
	stream<struct paging_reply> out_read, out_write;
	stream<struct dm_cmd> DRAM_rd_cmd("DRAM_rd_cmd"), DRAM_wr_cmd("DRAM_wr_cmd");
	stream<struct dm_cmd> BRAM_rd_cmd("BRAM_rd_cmd"), BRAM_wr_cmd("BRAM_wr_cmd");
	stream<struct axis_mem> DRAM_rd_data("DRAM_rd_data"), DRAM_wr_data("DRAM_wr_data");
	stream<struct axis_mem> BRAM_rd_data("BRAM_rd_data"), BRAM_wr_data("BRAM_wr_data");
	stream<ap_uint<8> > DRAM_rd_status("DRAM_rd_status"), DRAM_wr_status("DRAM_wr_status");
	stream<ap_uint<8> > BRAM_rd_status("BRAM_rd_status"), BRAM_wr_status("BRAM_wr_status");
	int _cycle;

	struct paging_request _in_read, _in_write;

	_in_read.address = 0x0;
	_in_read.length = 64;
	_in_read.opcode = MAPPING_REQUEST_READ;

#define NR_REQUESTS	4
	for (int i = 0; i < NR_REQUESTS; i++) {
		in_read.write(_in_read);
	}

	struct hash_bucket *ht_bram;
	struct hash_bucket *ht_dram;

	ht_bram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) * NR_HT_BUCKET_BRAM);
	ht_dram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) * NR_HT_BUCKET_DRAM);

#define NR_CYCLES_RUN	100
	for (_cycle = 0; _cycle < NR_CYCLES_RUN; _cycle++) {
		paging_top(&in_read, &in_write, &out_read, &out_write,
			   &DRAM_rd_cmd, &DRAM_wr_cmd,
			   &DRAM_rd_data, &DRAM_wr_data,
			   &DRAM_rd_status, &DRAM_wr_status,
			   &BRAM_rd_cmd, &BRAM_wr_cmd,
			   &BRAM_rd_data, &BRAM_wr_data,
			   &BRAM_rd_status, &BRAM_wr_status);

		if (!out_read.empty()) {
			struct paging_reply out = { 0 };
			out = out_read.read();

			dp("[Cycle %3d] Output (RD): [ouput: %#x status: %#x]\n", _cycle,
				out.address.to_uint(), out.status.to_uint());
		}

		if (!out_write.empty()) {
			struct paging_reply out = { 0 };
			out = out_write.read();

			dp("[Cycle %3d] Output (WR): [ouput: %#x status: %#x]\n", _cycle,
				out.address.to_uint(), out.status.to_uint());
		}

		/* DRAM Read */
		if (!DRAM_rd_cmd.empty()) {
			struct dm_cmd cmd = DRAM_rd_cmd.read();
			struct axis_mem in;

			struct hash_bucket hb = {
				{0x100, 0x200, 0x300, 0x400, 0x500, 0x600, 0x700},
				{0x1100, 0x2200, 0x3300, 0x4400, 0x5500, 0x6600, 0x7700},
				0,
				0,
				0
			};

			dp("[Cycle %3d] DRAM Read\n", _cycle);

			memcpy(&(in.data), &hb, 64);
			in.last = 1;
			DRAM_rd_data.write(in);
		}

		/* BRAM Read */
		if (!BRAM_rd_cmd.empty()) {
			struct dm_cmd cmd = BRAM_rd_cmd.read();
			struct axis_mem in;
			struct hash_bucket *hb;
			unsigned int index;

			index = cmd.start_address.to_uint();
			if (index >= NR_HT_BUCKET_BRAM) {
				printf("ERROR: index=%d\n", index);
				exit(-1);
			}
			hb = &ht_bram[index];

			dp("[Cycle %3d] BRAM Read ht_index = %d\n",
				_cycle, index);

			memcpy(&(in.data), hb, 64);
			in.last = 1;
			BRAM_rd_data.write(in);
		}

		/* BRAM Write */
		if (!BRAM_wr_cmd.empty() && !BRAM_wr_data.empty()) {
			struct dm_cmd cmd = BRAM_wr_cmd.read();
			struct axis_mem out = BRAM_wr_data.read();
			struct hash_bucket *hb;
			unsigned int index;

			index = cmd.start_address.to_uint();
			if (index >= NR_HT_BUCKET_BRAM) {
				printf("ERROR: index=%d\n", index);
				exit(-1);
			}
			hb = &ht_bram[index];
			memcpy(hb, &(out.data), 64);

			dp("[Cycle %3d] BRAM Write ht_index = %d\n",
				_cycle, index);
		}

		/* DRAM Write */
		if (!DRAM_wr_cmd.empty() && !DRAM_wr_data.empty()) {
			struct dm_cmd cmd = DRAM_wr_cmd.read();
			struct axis_mem out = DRAM_wr_data.read();
			struct hash_bucket *hb;
			unsigned int index;

			printf("DRAM Write TODO\n");
			exit(-1);
		}
	}
}
