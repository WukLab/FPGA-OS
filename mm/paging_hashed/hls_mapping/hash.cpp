/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "top.hpp"
#include "dm.hpp"
#include "hash.hpp"

using namespace hls;

/*
 * This function should compute the hash value
 * of the input key and fill into pipeline_info.
 */
void compute_hash(stream<struct pipeline_info> *in,
		  stream<struct pipeline_info> *out)
{
#pragma HLS INLINE off
#pragma HLS PIPELINE

	if (!in->empty()) {
		struct pipeline_info pi;
		pi = in->read();

		pi.hash = pi.input;
		out->write(pi);
	}
}
