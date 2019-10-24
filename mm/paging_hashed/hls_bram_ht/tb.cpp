/*
 * Copyright (c) 2019, WukLab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/axis_mapping.h>
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
		    hls::stream<struct axis_mem>	*BRAM_wr_data);

int main(void)
{
	stream<struct dm_cmd> rd_cmd, wr_cmd;
	stream<struct axis_mem> rd_data, wr_data;
	struct dm_cmd cmd = {0};
	struct axis_mem data = {0};

	cmd.start_address = 1;

	rd_cmd.write(cmd);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data);
	if (!rd_data.empty()) {
		struct axis_mem d = rd_data.read();
		printf("RD data: %#x\n", d.data.to_uint());
	}

	data.data(0,0) = 1;
	data.data(256,256) = 1;
	data.data(511,510) = 0x3;
	wr_cmd.write(cmd);
	wr_data.write(data);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data);

	rd_cmd.write(cmd);
	bram_hashtable(&rd_cmd, &wr_cmd, &rd_data, &wr_data);
	if (!rd_data.empty()) {
		struct axis_mem d = rd_data.read();
		printf("RD data: %#x\n", d.data.to_uint());
	}
}
