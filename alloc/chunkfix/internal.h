/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _ALLOCATOR_SEGFIX_INTERNAL_H_
#define _ALLOCATOR_SEGFIX_INTERNAL_H_

#include <ap_int.h>

#define NR_SEGFIX_ENTRIES_SHIFT		(CONFIG_SEGFIX_MANAGED_SIZE_SHIFT - \
					 CONFIG_SEGFIX_GRANULARITY_SHIFT)
#define NR_SEGFIX_ENTRIES 		(1 << NR_SEGFIX_ENTRIES_SHIFT)

struct segfix_entry {
	ap_uint<1>	busy;
};

#endif /* _ALLOCATOR_SEGFIX_INTERNAL_H_ */
