/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes buddy allocator opcode and type used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_SYSMMU_TYPE_
#define _LEGO_FPGA_SYSMMU_TYPE_

#include "mem_common.h"

typedef enum {
	BUDDY_ALLOC = 0,
	BUDDY_FREE = 1,
} OPCODE;

#define BUDDY_SET_ORDER			1
#define BUDDY_SET_TYPE			(BUDDY_SET_ORDER + 1)
#define BUDDY_SET_SIZE			(1 << BUDDY_SET_ORDER)

#define ORDER_MAX			(BLOCK_SHIFT - BUDDY_MIN_SHIFT)
#define ORDER_PAD_BITS			((ORDER_MAX % 3) ? (3 - ORDER_MAX % 3) : 0)
#define ORDER_MAX_PAD			(ORDER_MAX + ORDER_PAD_BITS)
#define LEVEL_MAX			(ORDER_MAX_PAD / 3)
#define SMALL_ORDER_IDX(order)		((ORDER_MAX - order - 9) / 3)
#define LENGTH_TO_ORDER(len)		(len >> BUDDY_MIN_SHIFT)

/*
 * some define for simulation use
 */
#define SIM_DRAM_SIZE			1UL << ORDER_MAX_PAD

#endif /* _LEGO_FPGA_SYSMMU_TYPE_ */
