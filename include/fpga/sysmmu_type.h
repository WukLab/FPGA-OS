/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * This file describes sysmmu opcode and type used by FPGA IPs.
 * This file is supposed to be used by FPGA code only.
 */

#ifndef _LEGO_FPGA_SYSMMU_TYPE_
#define _LEGO_FPGA_SYSMMU_TYPE_

typedef enum {
	SYSMMU_ALLOC = 0,
	SYSMMU_FREE = 1,
} OPCODE;

typedef enum {
	MEMREAD = 0,
	MEMWIRTE = 1,
} ACCESS_TYPE;

typedef enum {
	SUCCESS = 0,
	ERROR = 1,
} RET_STATUS;


#define PID_SHIFT			10	/* pid width */
#define PA_SHIFT			32	/* address width */
#define BLOCK_SHIFT			27	/* minimum chunk granularity */

#define SIZE(shift)			(1UL << shift)
#define IDX(addr, shift)		(addr >> shift)

#define BLOCK_SIZE			SIZE(BLOCK_SHIFT)
#define TABLE_SHIFT			(PA_SHIFT - BLOCK_SHIFT)
#define TABLE_SIZE			SIZE(TABLE_SHIFT)
#define BLOCK_IDX(addr)			IDX(addr, BLOCK_SHIFT)

/*
 * use these macros below carefully,
 * these will introduce a lot of logics,
 * only use it if INEVITABLE!!!
 * (feel free to use it in testbench)
 */
#define ALIGN_UP(addr, size)	(((addr)+((size)-1))&(~((typeof(addr))(size)-1)))
#define ALIGN_DOWN(addr, size)	((addr)&(~((typeof(addr))(size)-1)))

#endif /* _LEGO_FPGA_SYSMMU_TYPE_ */
