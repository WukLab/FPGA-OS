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
	~Chunk_alloc();

	void handler(axis_sysmmu_alloc& alloc, axis_sysmmu_alloc_ret& alloc_ret, axis_sysmmu_ctrl& ctrl,
			RET_STATUS& ctrl_ret, RET_STATUS* stat);

private:
	ap_uint<TABLE_SIZE> chunk_bitmap;

	void alloc(sysmmu_alloc_if& alloc, axis_sysmmu_alloc_ret& alloc_ret, axis_sysmmu_ctrl& ctrl,
			RET_STATUS& ctrl_ret, RET_STATUS* stat);
	void free(sysmmu_alloc_if& alloc, axis_sysmmu_alloc_ret& alloc_ret, axis_sysmmu_ctrl& ctrl,
			RET_STATUS& ctrl_ret, RET_STATUS* stat);
};



#endif /* _CHUNK_ALLOC_H_ */
