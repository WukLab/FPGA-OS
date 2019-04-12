/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "sysmmu.h"

void
mm_segment_top(hls::stream<sysmmu_ctrl_if>& ctrl, hls::stream<ap_uint<1> >& ctrl_stat,
	       hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out,
	       hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out)
{
#pragma HLS PIPELINE II=1
#pragma HLS INLINE RECURSIVE

#pragma HLS DATA_PACK variable=ctrl
#pragma HLS DATA_PACK variable=rd_in
#pragma HLS DATA_PACK variable=rd_out
#pragma HLS DATA_PACK variable=wr_in
#pragma HLS DATA_PACK variable=wr_out

#pragma HLS INTERFACE axis off port=ctrl
#pragma HLS INTERFACE axis off port=ctrl_stat
#pragma HLS INTERFACE axis off port=rd_in
#pragma HLS INTERFACE axis off port=rd_out
#pragma HLS INTERFACE axis off port=wr_in
#pragma HLS INTERFACE axis off port=wr_out

	if (!ctrl.empty())
		sysmmu_ctrl_hanlder(ctrl, ctrl_stat);
	else
		sysmmu_data_hanlder(rd_in, rd_out, wr_in, wr_out);

}
