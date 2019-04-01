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
	void sysmmu_data_hanlder(sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out,
				 sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out);
	void sysmmu_ctrl_hanlder(axis_sysmmu_ctrl& ctrlpath, RET_STATUS* stat);

private:
	sysmmu_entry sysmmu_table[TABLE_SIZE];

	void sysmmu_data_read(sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out);
	void sysmmu_data_write(sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out);

	RET_STATUS insert(sysmmu_ctrl_if& ctrl);
	RET_STATUS del(sysmmu_ctrl_if& ctrl);
	RET_STATUS check_read(sysmmu_indata_if& rd_in);
	RET_STATUS check_write(sysmmu_indata_if& wr_in);
};

void mm_segment_top(axis_sysmmu_ctrl& ctrl, RET_STATUS* ctrl_stat,
		    sysmmu_indata_if& rd_in, sysmmu_outdata_if* rd_out,
		    sysmmu_indata_if& wr_in, sysmmu_outdata_if* wr_out);

#endif /* _SYSMMU_H_ */
