/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu control interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_CTRL_
#define _LEGO_FPGA_AXIS_SYSMMU_CTRL_

#include "sysmmu_type.h"

template <int PID_WIDTH, int IDX_WIDTH>
struct sysmmu_ctrl {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between sysmmu allocator and sysmmu unit:
	 *
	 * opcode: ALLOC or FREE
	 * pid: application id
	 * rw:	application rw permission for this request, 
	 * addr: address to be allocated or to be freed, 
	 */
	OPCODE			opcode;
	ap_uint<PID_WIDTH>	pid;
	ACCESS_TYPE		rw;
	ap_uint<IDX_WIDTH>	idx;
};

typedef struct sysmmu_ctrl<PID_SHIFT, TABLE_SHIFT>	sysmmu_ctrl_if;
typedef hls::stream<sysmmu_ctrl_if>		axis_sysmmu_ctrl;

#endif /* _LEGO_FPGA_AXIS_SYSMMU_CTRL_ */
