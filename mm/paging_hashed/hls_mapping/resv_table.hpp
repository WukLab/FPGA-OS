/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/axis_mapping.h>

#include "top.hpp"
#include "hash.hpp"

#define RESV_TBL_WIDTH		(NR_HT_BUCKET_BRAM_SHIFT + 1)
#define RESV_TBL_ENTRY_SHIFT	4
#define NR_RESV_TBL_ENTRY	(1 << RESV_TBL_ENTRY_SHIFT)
#define TBL_INDEX_MASK		(NR_RESV_TBL_ENTRY - 1)

/* result code */
#define ADDR_EXIST	1
#define TABLE_FULL	2
#define RESV_SUCCESS	0

using namespace hls;

enum TABLE_OP { RESV, POP };

struct table_request {
	enum TABLE_OP				opcode;
	ap_uint<NR_HT_BUCKET_BRAM_SHIFT>	index;
};

void address_reservation_table(stream<struct table_request>	*resv_request,
			       stream<ap_uint<2> >		*resv_result,
			       stream<struct table_request>	*pop_request);
