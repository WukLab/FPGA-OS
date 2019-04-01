/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu opcode and type used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_SYSMMU_TYPE_
#define _LEGO_FPGA_SYSMMU_TYPE_

#include <ap_int.h>
#include <hls_stream.h>
#include "mem_common.h"

typedef enum {
	SYSMMU_ALLOC = 0,
	SYSMMU_FREE = 1,
} OPCODE;

typedef enum {
	MEMREAD = 0,
	MEMWIRTE = 1,
} ACCESS_TYPE;

#define BLOCK_SIZE			SIZE(BLOCK_SHIFT)
#define TABLE_SHIFT			(PA_SHIFT - BLOCK_SHIFT)
#define TABLE_TYPE			(TABLE_SHIFT + 1)
#define TABLE_SIZE			SIZE(TABLE_SHIFT)
#define BLOCK_IDX(addr)			IDX(addr, BLOCK_SHIFT)

#endif /* _LEGO_FPGA_SYSMMU_TYPE_ */
