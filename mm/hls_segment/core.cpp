#include "sysmmu.h"

static Sysmmu sysmmu_table = Sysmmu();

void core(axis_sysmmu_ctrl& ctrl, axis_sysmmu_data& data,
			RET_STATUS* ctrl_stat, RET_STATUS* data_stat)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE axis register both port=data
#pragma HLS INTERFACE axis register both port=ctrl
	if (!ctrl.empty())
		sysmmu_table.sysmmu_ctrl_hanlder(ctrl, ctrl_stat);
	else
		sysmmu_table.sysmmu_data_hanlder(data, data_stat);
}
