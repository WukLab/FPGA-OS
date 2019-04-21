#include "chunk_alloc.h"

void chunk_alloc(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		 hls::stream<sysmmu_ctrl_if>& ctrl, hls::stream<ap_uint<1> >& ctrl_ret)
{
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS DATA_PACK variable=alloc
#pragma HLS DATA_PACK variable=alloc_ret
#pragma HLS DATA_PACK variable=ctrl

#pragma HLS INTERFACE axis both port=alloc
#pragma HLS INTERFACE axis both port=alloc_ret
#pragma HLS INTERFACE axis both port=ctrl
#pragma HLS INTERFACE axis both port=ctrl_ret

	handler(alloc, alloc_ret, ctrl, ctrl_ret);
}
