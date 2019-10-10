/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/* System-level headers */

#include <string.h>

void global_timestamp(unsigned long *tsc)
{
#pragma HLS INTERFACE ap_none port=tsc
#pragma HLS PROTOCOL fixed
#pragma HLS LATENCY min=0 max=0
#pragma HLS INTERFACE ap_ctrl_none port=return

	static unsigned long _tsc = 0;
#pragma HLS RESET variable=_tsc off

	*tsc = _tsc++;
}
