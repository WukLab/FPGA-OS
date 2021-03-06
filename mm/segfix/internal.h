/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _ALLOCATOR_SEGFIX_INTERNAL_H_
#define _ALLOCATOR_SEGFIX_INTERNAL_H_

#include <ap_int.h>
#include <fpga/config/kernel.h>

#define NR_SEGFIX_ENTRIES_SHIFT		(CONFIG_SEGFIX_MANAGED_SIZE_SHIFT - \
					 CONFIG_SEGFIX_GRANULARITY_SHIFT)
#define NR_SEGFIX_ENTRIES 		(1 << NR_SEGFIX_ENTRIES_SHIFT)

/*
 * The segment table entry description.
 * Since this is the fixed-segment implementation,
 * each entry oversees a certain range of memory.
 */
struct segfix_entry {
	ap_uint<1>	busy;
	ap_uint<32>	ipid;
	ap_uint<2>	permission;
};

enum SYSMM_REQUEST_TYPE {
	SYSMM_REQUEST_CONTROL = 1,
	SYSMM_REQUEST_DATA_RD,
	SYSMM_REQUEST_DATA_WR,
};

/*
 * This is the internal informaton that being passed through the pipeline.
 * Its basically a combination of the data/control path data structures.
 */
struct pipeline_info {
	/* Check SYSMM_REQUEST_TYPE */
	ap_uint<2>					type;

	ap_uint<CONFIG_PID_WIDTH>			pid;

	/* Control path information */
	ap_uint<8>					cp_in_opcode;
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	cp_in_addr_len;
	ap_uint<8>					cp_ret;
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	cp_ret_addr_len;

	/* Data path information */
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	dp_in_addr;
	ap_uint<8>					dp_in_len;
	ap_uint<3>					dp_in_size;
	ap_uint<1>					dp_ret;
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	dp_ret_addr;
};

#endif /* _ALLOCATOR_SEGFIX_INTERNAL_H_ */
