/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file describes generic configuration options
 * that affect the whole FPGA design.
 */

#ifndef _INCLUDE_FPGA_CONFIG_MEMORY_H_
#define _INCLUDE_FPGA_CONFIG_MEMORY_H_

/*
 * This config defines the on-board DRAM size in bytes.
 * It would be nice if we could determine this after boot.
 */
#define CONFIG_DRAM_SIZE_SHIFT			(32)
#define CONFIG_DRAM_SIZE			(1<<CONFIG_DRAM_SIZE_SHIFT)

/*
 * This config defines the physical address width in bits.
 * This config must be larger CONFIG_DRAM_SIZE_SHIFT.
 */
#define CONFIG_DRAM_PHYSICAL_ADDR_WIDTH		(32)

#endif /* _INCLUDE_FPGA_CONFIG_MEMORY_H_ */
