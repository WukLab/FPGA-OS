/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#ifndef _SYSMMU_H_
#define _SYSMMU_H_

#include <fpga/axis_sysmmu_ctrl.h>
#include <fpga/axis_sysmmu_data.h>

typedef struct {
	ap_uint<1>		valid;
	ACCESS_TYPE		rw;
	ap_uint<PID_SHIFT>	pid;
} sysmmu_entry;

class Sysmmu
{
public:
	Sysmmu();
	~Sysmmu();
	void sysmmu_data_hanlder(axis_sysmmu_data& datapath, RET_STATUS* stat);
	void sysmmu_ctrl_hanlder(axis_sysmmu_ctrl& ctrlpath, RET_STATUS* stat);

private:
	sysmmu_entry sysmmu_table[TABLE_SIZE];

	RET_STATUS insert(sysmmu_ctrl_if& ctrl);
	RET_STATUS del(sysmmu_ctrl_if& ctrl);
	RET_STATUS check(sysmmu_data_if& data);
};

void mm_segment_top(axis_sysmmu_ctrl& ctrl, axis_sysmmu_data& data,
		    RET_STATUS* ctrl_stat, RET_STATUS* data_stat);

#endif /* _SYSMMU_H_ */
