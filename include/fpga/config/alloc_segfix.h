/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _INCLUDE_FPGA_CONFIG_ALLOC_SEGFIX_H_
#define _INCLUDE_FPGA_CONFIG_ALLOC_SEGFIX_H_

#include <fpga/config/memory.h>

/*
 * The granularity of the fixed-size segment allocator.
 * The size is (1<<CONFIG_SEGFIX_SIZE_SHIFT) in bytes.
 */
#define CONFIG_SEGFIX_GRANULARITY_SHIFT	(20)
#define CONFIG_SEGFIX_GRANULARITY_SIZE	(1<<CONFIG_SEGFIX_GRANULARITY_SHIFT)

/*
 * The total managed DRAM size in bytes.
 * The default is the whole on-board DRAM space.
 * Users can customize
 */
#ifndef CONFIG_SEGFIX_MANAGED_SIZE_SHIFT
# define CONFIG_SEGFIX_MANAGED_SIZE_SHIFT	(CONFIG_DRAM_SIZE_SHIFT)
#endif
#define CONFIG_SEGFIX_MANAGED_SIZE		(1<<CONFIG_SEGFIX_MANAGED_SIZE_SHIFT)

#endif /* _INCLUDE_FPGA_CONFIG_ALLOC_SEGFIX_H_ */
