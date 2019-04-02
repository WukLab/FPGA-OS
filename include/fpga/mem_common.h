/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file defines some generic configuration of buddy and chunk relevant
 * memory configuration, in addition to some useful macros
 */

#ifndef _LEGO_FPGA_MEM_COMMON_
#define _LEGO_FPGA_MEM_COMMON_

/*
 * configs
 */
#define PID_SHIFT		8	/* pid width */
#define PA_SHIFT		32	/* address width */
#define BLOCK_SHIFT		29	/* minimum chunk granularity */
#define BUDDY_MIN_SHIFT		12	/* minimum size of buddy allocator */
#define BUDDY_SET_ORDER		1	/* number of buddy unit in cache per order */

#define SIZE(shift)		(1UL << shift)
#define IDX(addr, shift)	(addr >> shift)
#define ADDR(idx ,shift)	(idx << shift)

#define BLOCK_SIZE		SIZE(BLOCK_SHIFT)
#define BLOCK_IDX(addr)		ap_uint<TABLE_TYPE>(IDX(addr, BLOCK_SHIFT))

/*
 * used for system segment
 */
#define TABLE_SHIFT		(PA_SHIFT - BLOCK_SHIFT)
#define TABLE_TYPE		(TABLE_SHIFT + 1)
#define TABLE_SIZE		SIZE(TABLE_SHIFT)

/*
 * used for buddy
 */
#define ORDER_MAX		(BLOCK_SHIFT - BUDDY_MIN_SHIFT)
#define BUDDY_SET_TYPE		(BUDDY_SET_ORDER + 1)
#define BUDDY_SET_SIZE		(1 << BUDDY_SET_ORDER)

#define ORDER_PAD_BITS		((ORDER_MAX % 3) ? (3 - ORDER_MAX % 3) : 0)
#define ORDER_MAX_PAD		(ORDER_MAX + ORDER_PAD_BITS)
#define LEVEL_MAX		(ORDER_MAX_PAD / 3)
#define SMALL_ORDER_IDX(order)	((ORDER_MAX - order - 9) / 3)
#define LENGTH_TO_ORDER(len)	(len >> BUDDY_MIN_SHIFT)

/*
 * define only for simulation use
 */
#define SIM_DRAM_SIZE		(1UL << ORDER_MAX_PAD)

/*
 * use these macros below carefully,
 * these will introduce a lot of logics,
 * only use it if INEVITABLE!!!
 * (feel free to use it in testbench)
 */
#define ALIGN_UP(addr, size)	(((addr)+((size)-1))&(~((typeof(addr))(size)-1)))
#define ALIGN_DOWN(addr, size)	((addr)&(~((typeof(addr))(size)-1)))

#endif /* _LEGO_FPGA_MEM_COMMON_ */
