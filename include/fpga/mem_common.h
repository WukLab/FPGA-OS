/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file defines some generic configuration of buddy and chunk relevant
 * memory configuration, in addition to some useful macros
 */

#ifndef _LEGO_FPGA_MEM_COMMON_
#define _LEGO_FPGA_MEM_COMMON_

/*
 * Some Defines you may care:
 *
 * @PID_WIDTH:          pid data width
 * @PA_WIDTH:           physical address data width
 * @CHUNK_SHIFT:        log 2 of chunk granularity
 * @BUDDY_MAX_SHIFT:    log 2 of maximum address space managed by buddy
 * @BUDDY_MIN_SHIFT:    log 2 of minimum size allocated by buddy
 * @BUDDY_SET_ORDER:    log 2 of buddy BRAM cache associativity
 * @BUDDY_META_OFF:     buddy address space metadata address offset
 * @BUDDY_USER_OFF:     buddy address space user address offset
 * @BUDDY_START:        base address of buddy allocator
 * @BUDDY_END:          top address of buddy allocator (exclusive)
 *
 * buddy address space layout:
 *
 * ------------------   <- BUDDY_END
 * |                |
 * |                |
 * |    Userdata    |
 * |                |
 * |                |
 * ------------------   <- BUDDY_USER_OFF
 * |                |
 * |    Metadata    |
 * |                |
 * ------------------   <- BUDDY_START
 *
 */

/*
 * configs
 */
#define PID_WIDTH		8
#define PA_WIDTH		32
#define CHUNK_SHIFT		29
#define BUDDY_SET_ORDER		1
#define BUDDY_MIN_SHIFT		8

#define BUDDY_MAX_SHIFT		30
#define BUDDY_START             0x10000000
#define BUDDY_MANAGED_SIZE	(1<<BUDDY_MAX_SHIFT)
#define BUDDY_END               (BUDDY_START + BUDDY_MANAGED_SIZE)

#define BUDDY_META_OFF          (BUDDY_START)

#define SIZE(shift)		(1UL << shift)
#define IDX(addr, shift)	(addr >> shift)
#define ADDR(idx ,shift)	(idx << shift)

/*
 * used for system segment
 */
#define TABLE_SHIFT		(PA_WIDTH - CHUNK_SHIFT)
#define TABLE_TYPE		(TABLE_SHIFT + 1)
#define TABLE_SIZE		SIZE(TABLE_SHIFT)
#define CHUNK_SIZE		SIZE(CHUNK_SHIFT)
#define CHUNK_IDX(addr)		ap_uint<TABLE_TYPE>(IDX(addr, CHUNK_SHIFT))

/*
 * used for buddy
 */
#define ORDER_MAX		(BUDDY_MAX_SHIFT - BUDDY_MIN_SHIFT)
#define BUDDY_SET_TYPE		(BUDDY_SET_ORDER + 1)
#define BUDDY_SET_SIZE		(1 << BUDDY_SET_ORDER)

#define ORDER_PAD_BITS		((ORDER_MAX % 3) ? (3 - ORDER_MAX % 3) : 0)
#define ORDER_MAX_PAD		(ORDER_MAX + ORDER_PAD_BITS)
#define LEVEL_MAX		(ORDER_MAX_PAD / 3)
#define SMALL_ORDER_IDX(order)	((ORDER_MAX - order - 9) / 3)
#define LENGTH_TO_ORDER(len)	(len >> BUDDY_MIN_SHIFT)

#define BUDDY_META_SIZE         ((1 << (3 * LEVEL_MAX)) / 7)
#define BUDDY_USER_OFF          (BUDDY_META_OFF + BUDDY_META_SIZE)

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
