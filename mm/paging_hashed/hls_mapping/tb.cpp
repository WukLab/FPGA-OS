/*
 * Copyright (c) 2019, WukLab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "top.hpp"
#include "dm.hpp"

using namespace hls;

#define NR_MAX_BUCKET_ALLOC 50

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
	stream<struct buddy_alloc_if> alloc("alloc_request");
	stream<struct buddy_alloc_ret_if> alloc_ret("alloc_response");
	stream<ap_uint<PA_WIDTH> > base_addr("init address");
	int _cycle, k, j, l;

	struct mapping_request _in_read, _in_write;

	struct hash_bucket *ht_bram;
	struct hash_bucket *ht_dram;

	ht_bram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) * NR_HT_BUCKET_BRAM);
	ht_dram = (struct hash_bucket *)malloc(sizeof(struct hash_bucket) *
					       (NR_HT_BUCKET_DRAM + NR_MAX_BUCKET_ALLOC));

	memset(ht_bram, 0, sizeof(struct hash_bucket) * NR_HT_BUCKET_BRAM);
	memset(ht_dram, 0, sizeof(struct hash_bucket) * NR_HT_BUCKET_DRAM);

#define NR_CYCLES_RUN	400

	for (_cycle = 0, k = 0, j = 0, l = 0; _cycle < NR_CYCLES_RUN; _cycle++) {
		if (_cycle == 0) {
			base_addr.write(MAPPING_TABLE_ADDRESS_BASE);
		}
#if 1
#define NR_SET	12
		if (_cycle % 1 == 0 && k < NR_SET && _cycle > 2) {
			_in_read.address =  0x400 * (k+1);
			_in_read.length = 0x66666660 + k;
			_in_read.opcode = MAPPING_SET | MAPPING_PERMISSION_R;
			in_read.write(_in_read);
			k++;
			printf("Send SET at cycle %d [%#x %#x]\n", _cycle,
				_in_read.address.to_uint(),
				_in_read.length.to_uint());
		}
#endif

#if 1
		if (_cycle > 15) {
#define NR_GET	12
			if (j < NR_GET) {
				_in_read.address =  0x400 * (j+1);
				_in_read.length = 0;
				if (j%2)
					_in_read.opcode = MAPPING_REQUEST_READ;
				else
					_in_read.opcode = MAPPING_REQUEST_WRITE;
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
			   &BRAM_rd_data, &BRAM_wr_data,
			   &alloc, &alloc_ret, &base_addr);

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
			if (index >= NR_HT_BUCKET_DRAM + NR_MAX_BUCKET_ALLOC) {
				printf("ERROR: index=%d\n", index);
				exit(-1);
			}
			hb = &ht_dram[index];

			memcpy(&(in.data), hb, 64);

			dp("[Cycle %3d] DRAM Read ht_index = %d\n",
				_cycle, index);
			printf("DRAM[%x]  key[0] = %x val[0] = %x %x\n",
				index,
				hb->key[0].to_uint(),
				hb->val[0].to_uint(),
			       	in.data(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
				       NR_BITS_BITMAP_OFF)
				       .to_uint());

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
			/*
			 * If the width in ap_int<> is not a multiple of 8,
			 * the size of ap_int<> will be round to whole bytes.
			 * Luckly, 512 is a multiple of 8, so ap_uint<512> just
			 * take 64 bytes and there will be no information lost in
			 * copying 64 bytes from struct hash_bucket to ap_uint<512>,
			 * but the converse will result in broken information in
			 * struct hash_bucket, only key and val is correctly
			 * represented.
			 */
			memcpy(hb, &(out.data), 64);
			dp("[Cycle %3d] BRAM Write ht_index = %d\n",
				_cycle, index);
			printf("BRAM[%x]  key[0] = %x val[0] = %x %x\n",
				index,
				hb->key[0].to_uint(),
				hb->val[0].to_uint(),
			       	out.data(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
					NR_BITS_BITMAP_OFF)
				       .to_uint());
		}

		/* DRAM Write */
		if (!DRAM_wr_cmd.empty() && !DRAM_wr_data.empty()) {
			struct dm_cmd cmd = DRAM_wr_cmd.read();
			struct axis_mem out = DRAM_wr_data.read();
			struct hash_bucket *hb;
			unsigned int index;

			index = (cmd.start_address.to_uint() - MAPPING_TABLE_ADDRESS_BASE)/NR_BYTES_MEM_BUS;
			if (index >= NR_HT_BUCKET_DRAM + NR_MAX_BUCKET_ALLOC) {
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
			       	out.data(NR_BITS_BITMAP_OFF + NR_SLOTS_PER_BUCKET - 1,
					NR_BITS_BITMAP_OFF)
				       .to_uint());
		}

		/* dummy allocator */
		if (!alloc.empty()) {
			struct buddy_alloc_if req = alloc.read();
			struct buddy_alloc_ret_if resp = { 0 };
			if (l < NR_MAX_BUCKET_ALLOC) {
				resp.addr = (NR_HT_BUCKET_DRAM + l) * NR_BYTES_MEM_BUS +
					MAPPING_TABLE_ADDRESS_BASE;
				resp.stat = BUDDY_SUCCESS;
				l++;
			} else {
				resp.addr = 0;
				resp.stat = BUDDY_FAILED;
			}
			alloc_ret.write(resp);
		}
	}
}
