/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */
#ifndef _SEGMENT_SEGMENT_HPP_
#define _SEGMENT_SEGMENT_HPP_

#include "../include/translate.hpp"

#define SEGMENT_VIRTUAL_WIDTH		32
#define SEGMENT_PHYSICAL_WIDTH		32

/*
 * Sure, templates are yummy, but typedef is alwasy EVIL.
 * This is C++, just live with it.
 */
typedef struct mmu_trans_data<SEGMENT_VIRTUAL_WIDTH, 8>		va_t;
typedef struct mmu_trans_data<SEGMENT_PHYSICAL_WIDTH, 8>	pa_t;

typedef hls::stream<va_t>	axis_va_t;
typedef hls::stream<pa_t>	axis_pa_t;

struct segment_entry {
	ap_uint<1>			state;
	ap_uint<SEGMENT_VIRTUAL_WIDTH>	va_base;
	ap_uint<SEGMENT_VIRTUAL_WIDTH>	va_bound;
	ap_uint<SEGMENT_PHYSICAL_WIDTH>	pa_base;
	ap_uint<1>			permission;
};

#endif /* _SEGMENT_SEGMENT_HPP_ */
