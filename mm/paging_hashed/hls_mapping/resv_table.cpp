/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "resv_table.hpp"

void address_reservation_table(stream<struct table_request> *resv_request,
			       stream<ap_uint<2> > *resv_result,
			       stream<struct table_request> *pop_request)
{
#pragma HLS PIPELINE
#pragma HLS INLINE off
#pragma HLS INTERFACE ap_ctrl_none port = return

	static ap_uint<RESV_TBL_WIDTH> addr_resv_table[NR_RESV_TBL_ENTRY] = { 0 };
#pragma HLS ARRAY_PARTITION variable = addr_resv_table

	static unsigned int head = 0;
	static unsigned int rear = 0;

	if (!pop_request->empty()) {
		pop_request->read();
		addr_resv_table[head] = 0;
		head = (head + 1) & TBL_INDEX_MASK;
	}

	if (!resv_request->empty()) {
		table_request req = resv_request->read();
		enum TABLE_OP tbl_op = req.opcode;
		ap_uint<NR_HT_BUCKET_BRAM_SHIFT> index = req.index;

		if (((rear + 1) & TBL_INDEX_MASK) == head) {
			ap_uint<2> res = TABLE_FULL;
			resv_result->write(res);
		} else {
			unsigned int i;
			bool is_exist = false;
			for (i = 0; i < NR_RESV_TBL_ENTRY; i++) {
				if (addr_resv_table[i][RESV_TBL_WIDTH - 1] &&
				    addr_resv_table[i](NR_HT_BUCKET_BRAM_SHIFT - 1, 0) == index) {
					is_exist = true;
					break;
				}
			}

			if (is_exist) {
				ap_uint<2> res = ADDR_EXIST;
				resv_result->write(res);
			} else {
				ap_uint<RESV_TBL_WIDTH> entry;
				entry[RESV_TBL_WIDTH - 1] = 1;
				entry(NR_HT_BUCKET_BRAM_SHIFT - 1, 0) = index;
				addr_resv_table[rear] = entry;
				rear = (rear + 1) & TBL_INDEX_MASK;
				ap_uint<2> res = RESV_SUCCESS;
				resv_result->write(res);
			}
		}
	}
}
