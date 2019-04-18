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
	stream<struct mapping_request> in_read, in_write;
	stream<struct mapping_reply> out_read, out_write;
	stream<struct dm_cmd> DRAM_rd_cmd("DRAM_rd_cmd"), DRAM_wr_cmd("DRAM_wr_cmd");
	stream<struct dm_cmd> BRAM_rd_cmd("BRAM_rd_cmd"), BRAM_wr_cmd("BRAM_wr_cmd");
	stream<struct axis_mem> DRAM_rd_data("DRAM_rd_data"), DRAM_wr_data("DRAM_wr_data");
	stream<struct axis_mem> BRAM_rd_data("BRAM_rd_data"), BRAM_wr_data("BRAM_wr_data");
	stream<ap_uint<8> > DRAM_rd_status("DRAM_rd_status"), DRAM_wr_status("DRAM_wr_status");
	int _cycle, k, j;

	struct mapping_request _in_read, _in_write;

	struct hash_bucket *ht_bram;
	struct hash_bucket *ht_dram;

	ht_bram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) * NR_HT_BUCKET_BRAM);
	ht_dram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) * NR_HT_BUCKET_DRAM);

	memset(ht_bram, 0, sizeof(struct hash_bucket) * NR_HT_BUCKET_BRAM);
	memset(ht_dram, 0, sizeof(struct hash_bucket) * NR_HT_BUCKET_DRAM);

#define NR_CYCLES_RUN	400

	for (_cycle = 0, k = 0, j = 0; _cycle < NR_CYCLES_RUN; _cycle++) {
#if 1
#define NR_SET	8
		if (_cycle % 10 == 0 && k < NR_SET) {
			_in_read.address =  0x100 * (k+1);
			_in_read.length = 0x66666660 + k;
			_in_read.opcode = MAPPING_SET;
			in_read.write(_in_read);
			k++;
			printf("Send SET at cycle %d [%#x %#x]\n", _cycle,
				_in_read.address.to_uint(),
				_in_read.length.to_uint());
		}
#endif

#if 1
		if (_cycle > 100) {
#define NR_GET	1
			if (j < NR_GET) {
				_in_read.address =  0x100 * (j+1);
				_in_read.length = 0;
				_in_read.opcode = MAPPING_REQUEST_READ;
				in_read.write(_in_read);
				j++;
			}
		}
#endif


		paging_top(&in_read, &in_write, &out_read, &out_write,
			   &DRAM_rd_cmd, &DRAM_wr_cmd,
			   &DRAM_rd_data, &DRAM_wr_data,
			   &DRAM_rd_status, &DRAM_wr_status,
			   &BRAM_rd_cmd, &BRAM_wr_cmd,
			   &BRAM_rd_data, &BRAM_wr_data);

		if (!out_read.empty()) {
			struct mapping_reply out = { 0 };
			out = out_read.read();

			dp("[Cycle %3d] Output (RD): [ouput: %#x status: %#x]\n", _cycle,
				out.address.to_uint(), out.status.to_uint());
		}

		if (!out_write.empty()) {
			struct mapping_reply out = { 0 };
			out = out_write.read();

			dp("[Cycle %3d] Output (WR): [ouput: %#x status: %#x]\n", _cycle,
				out.address.to_uint(), out.status.to_uint());
		}

		/* DRAM Read */
		if (!DRAM_rd_cmd.empty()) {
			struct dm_cmd cmd = DRAM_rd_cmd.read();
			struct axis_mem in;
			struct hash_bucket *hb;
			unsigned int index;

			index = (cmd.start_address.to_uint() - MAPPING_TABLE_ADDRESS_BASE)/NR_BYTES_MEM_BUS;
			if (index >= NR_HT_BUCKET_DRAM) {
				printf("ERROR: index=%d\n", index);
				exit(-1);
			}
			hb = &ht_dram[index];

			dp("[Cycle %3d] DRAM Read ht_index = %d\n",
				_cycle, index);
			printf("  key[0] = %x val[0] = %x %x\n",
				hb->key[0].to_uint(),
				hb->val[0].to_uint(),
				hb->bitmap.to_uint());

			memcpy(&(in.data), hb, 64);
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
			printf("  key[0] = %x val[0] = %x %x\n",
				hb->key[0].to_uint(),
				hb->val[0].to_uint(),
				hb->bitmap.to_uint());

		}

		/* DRAM Write */
		if (!DRAM_wr_cmd.empty() && !DRAM_wr_data.empty()) {
			struct dm_cmd cmd = DRAM_wr_cmd.read();
			struct axis_mem out = DRAM_wr_data.read();
			struct hash_bucket *hb;
			unsigned int index;

			index = (cmd.start_address.to_uint() - MAPPING_TABLE_ADDRESS_BASE)/NR_BYTES_MEM_BUS;
			if (index >= NR_HT_BUCKET_DRAM) {
				printf("ERROR: index=%d\n", index);
				exit(-1);
			}
			hb = &ht_dram[index];
			memcpy(hb, &(out.data), 64);

			dp("[Cycle %3d] DRAM Write ht_index = %d\n",
				_cycle, index);
			printf("  key[0] = %x val[0] = %x %x\n",
				hb->key[0].to_uint(),
				hb->val[0].to_uint(),
				hb->bitmap.to_uint());
		}
	}
}
