/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#ifndef _CHUNK_ALLOC_H_
#define _CHUNK_ALLOC_H_

#include <fpga/axis_sysmmu_alloc.h>

class Chunk_alloc
{
public:
	Chunk_alloc();
	~Chunk_alloc() {}

	void handler(hls::stream<sysmmu_alloc_if>& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		     hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat);

private:
	ap_uint<TABLE_SIZE> chunk_bitmap;

	void alloc(struct sysmmu_alloc_if& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		   hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat);
	void free(struct sysmmu_alloc_if& alloc, hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
		  hls::stream<struct sysmmu_ctrl_if>& ctrl, ap_uint<1>& ctrl_ret, ap_uint<1>* stat);
};


#endif /* _CHUNK_ALLOC_H_ */
