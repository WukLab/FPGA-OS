/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/* System-level headers */

#include <string.h>

void global_timestamp(unsigned long *tsc)
{
#pragma HLS INTERFACE ap_ctrl_none port=return

	static unsigned long _tsc = 0;

	*tsc = _tsc++;
}
