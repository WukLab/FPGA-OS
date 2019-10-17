#include "chunk_alloc.h"

static ap_uint<TABLE_SIZE> chunk_bitmap = 0;

void handler(hls::stream<sysmmu_alloc_if>& alloc,
	     hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	     hls::stream<sysmmu_ctrl_if>& ctrl,
	     hls::stream<ap_uint<1> >& ctrl_ret)
{
#pragma HLS INLINE

	if (alloc.empty())
		return;

	sysmmu_alloc_if req;
	alloc.read(req);
	switch (req.opcode) {
	case CHUNK_ALLOC:
		malloc(req, alloc_ret, ctrl, ctrl_ret);
		break;
	case CHUNK_FREE:
		mfree(req, alloc_ret, ctrl, ctrl_ret);
		break;
	}
}

void malloc(sysmmu_alloc_if& alloc,
	    hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	    hls::stream<sysmmu_ctrl_if>& ctrl,
	    hls::stream<ap_uint<1> >& ctrl_ret)
{
	sysmmu_ctrl_if req;
	sysmmu_alloc_ret_if ret = {0, 1};
	ap_uint<1> ctrl_stat;
	ap_uint<PA_WIDTH> i;
	for (i = 0; i < TABLE_SIZE; i++) {
		if (!chunk_bitmap.get_bit(i)) {
			chunk_bitmap.set_bit(i, 1);
			req.opcode = CHUNK_ALLOC;
			req.idx = i;
			req.pid = alloc.pid;
			req.rw = alloc.rw;
			ctrl.write(req);
			break;
		}
	}

	/* waiting for response */
	while (i < TABLE_SIZE && ctrl_ret.empty());
	if (i < TABLE_SIZE) {
		ctrl_stat = ctrl_ret.read();
		if (ctrl_stat == 0) {
			ret.addr = ADDR(i, CHUNK_SHIFT);
			ret.stat = 0;
		}
	}

	/* write response whatever */
	alloc_ret.write(ret);
}

void mfree(sysmmu_alloc_if& alloc,
	  hls::stream<sysmmu_alloc_ret_if>& alloc_ret,
	  hls::stream<sysmmu_ctrl_if>& ctrl,
	  hls::stream<ap_uint<1> >& ctrl_ret)
{
	sysmmu_ctrl_if req;
	sysmmu_alloc_ret_if ret = {0, 0};
	ap_uint<1> ctrl_stat;
	ap_uint<TABLE_TYPE> idx = CHUNK_IDX(alloc.addr);

	if (chunk_bitmap.get_bit(idx)) {
		req.opcode = CHUNK_FREE;
		req.idx = CHUNK_IDX(alloc.addr);
		req.pid = alloc.pid;
		req.rw = alloc.rw;
		ctrl.write(req);

		/* waiting for response */
		while (ctrl_ret.empty());

		ctrl_stat = ctrl_ret.read();
		if (ctrl_stat == 0) {
			chunk_bitmap.set_bit(idx, 0);
			ret.stat = 0;
		} else {
			ret.stat = 1;
		}
	} else {
		ret.stat = 1;
	}

	/* write response whatever */
	alloc_ret.write(ret);
}
