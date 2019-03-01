/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu data interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_DATA_
#define _LEGO_FPGA_AXIS_SYSMMU_DATA_

#include <ap_axi_sdata.h>
#include <hls_stream.h>
#include "sysmmu_type.h"

template <int PID_WIDTH, int ADDR_WIDTH>
struct sysmmu_data {
	/*
	 * physical memory datapath interface, only for permission check
	 *
	 * pid: application id
	 * rw:	application rw request
	 * addr:application memory access address
	 * size:application memory access size (in terms of bytes)
	 */
	ap_uint<PID_WIDTH>	pid;
	ACCESS_TYPE		rw;
	ap_uint<ADDR_WIDTH>	addr;
	ap_uint<ADDR_WIDTH>	size;
};

typedef struct sysmmu_data<PID_SHIFT, PA_SHIFT>	sysmmu_data_if;
typedef hls::stream<sysmmu_data_if>		axis_sysmmu_data;

#endif /* _LEGO_FPGA_AXIS_SYSMMU_DATA_ */
