/*
 * Copyright (c) 2019, WukLab, UCSD.
 */

#ifndef _CHUNK_ALLOC_H_
#define _CHUNK_ALLOC_H_

#include <fpga/axis_sysmmu.h>

void handler(hls::stream<sysmmu_alloc_if>& alloc,
	     hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	     hls::stream<sysmmu_ctrl_if>& ctrl,
	     hls::stream<ap_uint<1> >& ctrl_ret);

void malloc(sysmmu_alloc_if& alloc,
	    hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	    hls::stream<sysmmu_ctrl_if>& ctrl,
	    hls::stream<ap_uint<1> >& ctrl_ret);

void mfree(sysmmu_alloc_if& alloc,
	  hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	  hls::stream<sysmmu_ctrl_if>& ctrl,
	  hls::stream<ap_uint<1> >& ctrl_ret);

#endif /* _CHUNK_ALLOC_H_ */
