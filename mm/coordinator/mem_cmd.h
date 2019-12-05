/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _MEM_CMD_H_
#define _MEM_CMD_H_

/**
 * this is the command for all memory related call such
 * as alloc, free and init. For these calls, we cook them
 * into this command and pass them to coordinator to handle
 */

#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/config/memory.h>
#include <fpga/mem_common.h>

enum mem_cmd_opcode {
	MEM_CMD_INIT,
	MEM_CMD_ALLOC,
	MEM_CMD_FREE
};

enum mem_cmd_retcode {
	MEM_CMD_SUCCESS,
	MEM_CMD_FAILED
};

struct mem_cmd_in {
	mem_cmd_opcode					opcode;
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	addr_len;
};

struct mem_cmd_out {
	ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH>	addr_len;
	mem_cmd_retcode					ret;
};

#endif
