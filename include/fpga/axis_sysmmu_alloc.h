/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file descirbes system mmu control interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_ALLOC_
#define _LEGO_FPGA_AXIS_SYSMMU_ALLOC_

#include <ap_axi_sdata.h>
#include <hls_stream.h>
#include "../shared/sysmmu_op.h"
#include "axis_sysmmu_config.h"

template <int PID_WIDTH, int ADDR_WIDTH>
struct sysmmu_alloc {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between application and sysmmu allocator, to save the bandwidth,
	 * alloc and free use the same structure, so some field maybe useless
	 * for certain opcode, see below for detail:
	 *
	 * opcode: ALLOC or FREE
	 * pid: application id
	 * rw:	application rw permission for this malloc, 
	 * 	if opcode is FREE, this field is useless
	 * addr: address used for free, 
	 *       if opcode is ALLOC, this field is useless
	 */
	OPCODE			opcode;
	ap_uint<PID_WIDTH>	pid;
	ACCESS_TYPE		rw;
	ap_uint<ADDR_WIDTH>	addr;
};

template <int ADDR_WIDTH>
struct sysmmu_alloc_ret {
	/*
	 * physical memory unit memory ctrl return structure, this interface 
	 * sits between application and sysmmu allocator, the return is only
	 * meaningful for ALLOC request
	 *
	 * addr: address assigned, useless when request is FREE
	 */
	ap_uint<ADDR_WIDTH>	addr;
};

typedef struct sysmmu_alloc<PID_SHIFT, PA_SHIFT>	sysmmu_alloc_if;
typedef struct sysmmu_alloc_ret<PA_SHIFT>		sysmmu_alloc_ret_if;

typedef hls::stream<sysmmu_alloc_if>			axis_sysmmu_alloc;
typedef hls::stream<sysmmu_alloc_ret_if>		axis_sysmmu_alloc_ret;

#endif /* _LEGO_FPGA_AXIS_SYSMMU_ALLOC_ */
