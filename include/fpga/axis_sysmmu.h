/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file descirbes system mmu control interfaces used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_AXIS_SYSMMU_
#define _LEGO_FPGA_AXIS_SYSMMU_

#include <ap_int.h>
#include <hls_stream.h>
#include "mem_common.h"

enum {
	CHUNK_ALLOC = 0,
	CHUNK_FREE = 1,
};

enum {
	READ = 0,
	WRITE = 1,
};

struct sysmmu_alloc_if {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between application and sysmmu allocator, to save the bandwidth,
	 * alloc and free use the same structure, so some field maybe useless
	 * for certain opcode, see below for detail:
	 *
	 * opcode: ALLOC = 0 or FREE = 1
	 * pid: application id
	 * rw:	application rw permission for this malloc,
	 * 	if opcode is FREE, this field is useless
	 * addr: address used for free,
	 *       if opcode is ALLOC, this field is useless
	 */
	ap_uint<1>		opcode;
	ap_uint<PID_WIDTH>	pid;
	ap_uint<1>		rw;
	ap_uint<PA_WIDTH>	addr;
};

struct sysmmu_alloc_ret_if {
	/*
	 * physical memory unit memory ctrl return structure, this interface
	 * sits between application and sysmmu allocator, the return is only
	 * meaningful for ALLOC request
	 *
	 * addr: address assigned, useless when request is FREE
	 */
	ap_uint<PA_WIDTH>	addr;
};

struct sysmmu_ctrl_if {
	/*
	 * physical memory unit memory ctrl structure, this interface sits
	 * between sysmmu allocator and sysmmu unit:
	 *
	 * opcode: ALLOC=0 or FREE=1
	 * rw:	READ=0, WRITE=1
	 * pid: application id
	 * addr: address to be allocated or to be freed,
	 */
	ap_uint<1>		opcode;
	ap_uint<1>		rw;
	ap_uint<PID_WIDTH>	pid;
	ap_uint<TABLE_TYPE>	idx;
};

void chunk_alloc(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		 hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat);

void mm_segment_top(hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>* ctrl_stat,
		    struct sysmmu_indata& rd_in, struct sysmmu_outdata* rd_out,
		    struct sysmmu_indata& wr_in, struct sysmmu_outdata* wr_out);

#endif /* _LEGO_FPGA_AXIS_SYSMMU_ */
