#include "sysmmu.h"

static Sysmmu sysmmu_table = Sysmmu();

void mm_segment_top(axis_sysmmu_ctrl& ctrl, RET_STATUS* ctrl_stat,
		    sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out,
		    sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out)
{
#pragma HLS PIPELINE II=1

#pragma HLS INTERFACE ap_vld port=ctrl_stat
#pragma HLS INTERFACE axis register both port=ctrl

#pragma HLS INTERFACE ap_none port=rd_in
#pragma HLS INTERFACE ap_none port=rd_out
#pragma HLS INTERFACE ap_none port=wr_in
#pragma HLS INTERFACE ap_none port=wr_out

	if (!ctrl.empty())
		sysmmu_table.sysmmu_ctrl_hanlder(ctrl, ctrl_stat);
	else
		sysmmu_table.sysmmu_data_hanlder(rd_in, rd_out, wr_in, wr_out);
}
