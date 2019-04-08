/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "../hls_mapping/hash.hpp"
#include "../hls_mapping/dm.hpp"

using namespace hls;

#define DEBUG

#ifndef DEBUG
# define dp(fmt, ...)	do { } while (0)
#else
# define dp(fmt, ...)	printf("[%s:%d] "fmt, __func__, __LINE__, ##__VA_ARGS__)
#endif

void bram_hashtable(hls::stream<struct dm_cmd>		*BRAM_rd_cmd,
		    hls::stream<struct dm_cmd>		*BRAM_wr_cmd,
		    hls::stream<struct axis_mem>	*BRAM_rd_data,
		    hls::stream<struct axis_mem>	*BRAM_wr_data,
		    hls::stream<ap_uint<8> >		*BRAM_rd_status,
		    hls::stream<ap_uint<8> >		*BRAM_wr_status);

int main(void)
{
	stream<struct dm_cmd> rd_cmd, wr_cmd;
	stream<struct axis_mem> rd_data, wr_data;
	struct dm_cmd cmd;
	struct axis_mem data;
	stream<ap_uint<8> > rd_status, wr_status;

	cmd.start_address = 1;

	rd_cmd.write(cmd);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data, &rd_status, &wr_status);
	if (!rd_data.empty()) {
		struct axis_mem d = rd_data.read();
		printf("RD data: %#x\n", d.data.to_uint());
	}

	data.data = 0x100;
	wr_cmd.write(cmd);
	wr_data.write(data);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data, &rd_status, &wr_status);

	rd_cmd.write(cmd);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data, &rd_status, &wr_status);
	if (!rd_data.empty()) {
		struct axis_mem d = rd_data.read();
		printf("RD data: %#x\n", d.data.to_uint());
	}
}
