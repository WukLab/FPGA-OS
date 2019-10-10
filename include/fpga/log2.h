/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#ifndef _LOG2_H_
#define _LOG2_H_

#include <ap_int.h>
#include <cassert>

static inline bool is_power_of_2(unsigned long n)
{
	return (n != 0 && ((n & (n - 1)) == 0));
}

/* assume WIDTH is power of 2 */
template<unsigned long WIDTH>
static inline ap_uint<WIDTH> log2(ap_uint<WIDTH> word)
{
	assert(is_power_of_2(WIDTH));
	ap_uint<WIDTH> num = WIDTH - 1;
	ap_uint<WIDTH> shift = WIDTH >> 1;

	while (shift) {
		if (!(word & (ap_uint<WIDTH>(-1) << (WIDTH - shift)))) {
			num -= shift;
			word <<= shift;
		}
		shift >>= 1;
	}
	return num;
}

template<int WIDTH>
static inline ap_uint<WIDTH> order_base_2(ap_uint<WIDTH> n)
{
	if (n > 1)
		return log2<WIDTH>(n - 1) + 1;
	else
		return 0;
}

#endif /* _LOG2_H_ */

