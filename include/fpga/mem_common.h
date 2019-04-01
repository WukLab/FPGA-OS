/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file defines some generic configuration of buddy and chunk relevant
 * memory configuration, in addition to some useful macros
 */

#ifndef _LEGO_FPGA_MEM_COMMON_
#define _LEGO_FPGA_MEM_COMMON_

typedef enum {
	SUCCESS = 0,
	ERROR = 1,
} RET_STATUS;

#define PID_SHIFT		8	/* pid width */
#define PA_SHIFT		32	/* address width */
#define BLOCK_SHIFT		27	/* minimum chunk granularity */
#define BUDDY_MIN_SHIFT		12	/* minimum size of buddy allocator */

#define SIZE(shift)		(1UL << shift)
#define IDX(addr, shift)	(addr >> shift)
#define ADDR(idx ,shift)	(idx << shift)

/*
 * use these macros below carefully,
 * these will introduce a lot of logics,
 * only use it if INEVITABLE!!!
 * (feel free to use it in testbench)
 */
#define ALIGN_UP(addr, size)	(((addr)+((size)-1))&(~((typeof(addr))(size)-1)))
#define ALIGN_DOWN(addr, size)	((addr)&(~((typeof(addr))(size)-1)))

#endif /* _LEGO_FPGA_MEM_COMMON_ */
