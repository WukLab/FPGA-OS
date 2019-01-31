/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */
#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <assert.h>
#include "segment.hpp"

using namespace hls;

#define NR_ENTRIES 2
struct segment_entry map[NR_ENTRIES];

static void __insert(struct segment_entry *entry)
{

}

static void insert_segment(ap_uint<SEGMENT_VIRTUAL_WIDTH> va_base,
			   ap_uint<SEGMENT_VIRTUAL_WIDTH> va_bound,
			   ap_uint<SEGMENT_PHYSICAL_WIDTH> pa_base,
			   ap_uint<1> permission)
{

}

static void __translate(va_t *va, pa_t *pa)
{

}

/*
 * This function will translate the virtual address sent from MMU upper layer
 * and send back the physical address.
 *
 * TODO: still need to figure out how to indicate error etc.
 * Especially if there is fault, the pipeline may have to stall.
 * This maybe relevant to how MC deal with long DRAM read. Check it maybe.
 */
void translate_segment(axis_va_t *in_va, axis_pa_t *out_pa)
{
	#pragma HLS DATA_PACK variable=in_va
	#pragma HLS DATA_PACK variable=out_pa
	#pragma HLS INTERFACE axis register both port=in_va
	#pragma HLS INTERFACE axis register both port=out_pa

	/* Block-level */
	#pragma HLS PIPELINE II=1 enable_flush

	va_t va;
	pa_t pa;

	if (in_va->empty())
		return;

	va = in_va->read();

	__translate(&va, &pa);
	pa.address = va.address;
	pa.nr_bytes = va.nr_bytes;
	pa.type = pa.type;

	out_pa->write(pa);
}
