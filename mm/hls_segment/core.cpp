/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include "sysmmu.h"

void mm_segment_top(hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>* ctrl_stat,
		    struct sysmmu_indata& rd_in, struct sysmmu_outdata* rd_out,
		    struct sysmmu_indata& wr_in, struct sysmmu_outdata* wr_out)

{
#pragma HLS PIPELINE II=1

#pragma HLS DATA_PACK variable=ctrl
#pragma HLS INTERFACE axis port=ctrl
#pragma HLS INTERFACE ap_ovld port=ctrl_stat

#pragma HLS DATA_PACK variable=rd_in
#pragma HLS DATA_PACK variable=rd_out
#pragma HLS DATA_PACK variable=wr_in
#pragma HLS DATA_PACK variable=wr_out
#pragma HLS INTERFACE ap_vld port=rd_in
#pragma HLS INTERFACE ap_ovld port=rd_out
#pragma HLS INTERFACE ap_vld port=wr_in
#pragma HLS INTERFACE ap_ovld port=wr_out

	if (!ctrl.empty())
		sysmmu_ctrl_hanlder(ctrl, ctrl_stat);
	else
		sysmmu_data_hanlder(rd_in, rd_out, wr_in, wr_out);
}
