
#include <ap_int.h>
#include <hls_stream.h>


#include "../../include/fpga/axis_mapping.h"
#include "mergesort.h"

using namespace hls;

enum APP_STATE {
	MAP_REQ,
	MAP_REPLY,
	LOAD_SCRATCH,
	MERGE_SORT,
	RESULT_TO_DRAM
};

void mergesort (ap_uint<512> *dram,
		   stream<struct mapping_request> *map_req,
		   stream<struct mapping_reply> *map_ret)
{
	#pragma HLS INTERFACE axis both port=map_req
	#pragma HLS INTERFACE axis both port=map_ret
	#pragma HLS INTERFACE m_axi depth=64 port=dram  offset=off
	#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum APP_STATE state = MAP_REQ;
	static ap_uint<32> scratch_arr[SCRATCH_ARRAY_SIZE];
	struct mapping_request req = { 0 };
	struct mapping_reply ret = { 0 };
	static ap_uint<32> pa_arr_ptr;


	switch (state) {

	/* Call AddrMap to get PA of array to be sorted */
	case MAP_REQ:
		req.address = va_arr_ptr;
		req.length = 0;
		req.opcode = MAPPING_REQUEST_READ;
		map_req->write(req);
		state = MAP_REPLY;
		break;

	case MAP_REPLY:
		if (map_ret->empty())
			break;
		ret = map_ret->read();
		if (ret.status == 0) {
			pa_arr_ptr = ret.address;
			state = LOAD_SCRATCH;
		} else {
			state = MAP_REPLY;
		}
		break;

	/* Load in scratch array from DRAM */
	case LOAD_SCRATCH:
		for (int i = 0; i < SCRATCH_ARRAY_SIZE; i += 2) {
			#pragma HLS_PIPELINE
			*(scratch_arr + i) = dram[pa_arr_ptr + i*32]; //loads 64 bytes per transaction
		}
		state = MERGE_SORT;
		break;

	/* Perform iterations where sublists are <= scratchpad */
	case MERGE_SORT:
		for (int subsize = 1; subsize < SCRATCH_ARRAY_SIZE; subsize = subsize*2)
		{
			#pragma HLS_PIPELINE
			for (int l = 0; l < SCRATCH_ARRAY_SIZE-1; l = l+2*subsize)
			{
				#pragma HLS_UNROLL factor = 2
				#pragma HLS_PIPELINE
				int mid = l+subsize-1;
				int r = l+2*subsize-1;
				merge(scratch_arr, l, mid, r);
			}
		}
		state = RESULT_TO_DRAM;
		break;
	/* TODO: Perform iterations where sublists are > scratchpad */


	/* Write result to DRAM */
	case RESULT_TO_DRAM:
		for (int i = 0; i < SCRATCH_ARRAY_SIZE; i += 2) {
			#pragma HLS_PIPELINE
			dram[pa_arr_ptr + i*32] = *(scratch_arr + i); //writes 64 bytes per transaction
		}
		break;
	}
}

/* Merges two sorted sub arrays into one */
void merge (ap_uint<32> scratch_arr[], int l, int m, int r)
{
	static ap_uint<32> left_list[SCRATCH_ARRAY_SIZE/2];
	static ap_uint<32> right_list[SCRATCH_ARRAY_SIZE/2];

	/* Fill left and right lists */
	int sub_arr_size = m - l + 1;
		for (int i = 0; i < sub_arr_size; i++)
		{
			#pragma HLS_PIPELINE
			left_list[i] = scratch_arr[l+i];
			right_list[i] = scratch_arr[m+1+i];
		}

	/* Merge sub arrays into scratch array */
	int l_ind = 0;
	int r_ind = 0;
	int arr_ind = 0;

	while (l_ind < sub_arr_size && r_ind < sub_arr_size) {
		if (left_list[l_ind] <= right_list[r_ind]) {
			scratch_arr[l + arr_ind] = left_list[l_ind];
			l_ind ++;
		} else {
			scratch_arr[l + arr_ind] = right_list[r_ind];
			r_ind ++;
		}
		arr_ind ++;
	}
	while (l_ind < sub_arr_size) {
		#pragma HLS_PIPELINE
		scratch_arr[l + arr_ind] = left_list[l_ind];
		l_ind ++;
		arr_ind ++;
	}
	while (r_ind < sub_arr_size) {
		#pragma HLS_PIPELINE
		scratch_arr[l + arr_ind] = right_list[r_ind];
		r_ind ++;
		arr_ind++;
	}
}
