#include <hls_stream.h>
#include <fpga/axis_buddy.h>
#include <fpga/axis_mapping.h>
#include "../hls_mapping/top.hpp"

using namespace hls;

#define NR_MAX_BUCKET_ALLOC 50

void dummy_allocator(stream<struct buddy_alloc_if>      &alloc,
		     stream<struct buddy_alloc_ret_if>  &alloc_ret)
{
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=alloc
#pragma HLS INTERFACE axis both port=alloc_ret

#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret

	static int l = 0;

	if (!alloc.empty()) {
                struct buddy_alloc_if req = alloc.read();
		struct buddy_alloc_ret_if resp = { 0 };
                if (l < NR_MAX_BUCKET_ALLOC) {
			resp.addr = (NR_HT_BUCKET_DRAM + l) * NR_BYTES_MEM_BUS +
				    MAPPING_TABLE_ADDRESS_BASE;
			resp.stat = 1;
			l++;
		} else {
                        resp.addr = 0;
			resp.stat = 0;
		}
		alloc_ret.write(resp);
	}
}
