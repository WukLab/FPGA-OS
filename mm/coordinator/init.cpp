/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include "internal.hpp"

using namespace hls;

enum INIT_STATUS {
	INIT_ALLOC_SEG,
	INIT_ALLOC_SEG_RET,
	INIT_ALLOC_TABEL_RET,
	INIT_ALLOC_META_RET
};

int init(stream<struct buddy_alloc_if>	*buddy_alloc_req,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret,
		     stream<struct alloc_seg_in>	*seg_alloc_req,
		     stream<struct alloc_seg_out>	*seg_alloc_ret,
		     stream<unsigned long>		*init_buddy_addr,
		     stream<ap_uint<PA_WIDTH> >		*init_tbl_addr,
		     stream<unsigned long>		*init_heap_addr)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	static INIT_STATUS state = INIT_ALLOC_SEG;
	static ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH> buddy_start;
	static ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH> table_base_addr;
	static ap_uint<CONFIG_DRAM_PHYSICAL_ADDR_WIDTH> heap_meta_start;

	struct alloc_seg_in sys_mm_req;
	struct alloc_seg_out sys_mm_ret;
	struct buddy_alloc_if lib_mm_req;
	struct buddy_alloc_ret_if lib_mm_ret;

	switch (state) {
	case INIT_ALLOC_SEG:
		sys_mm_req.opcode = SEG_ALLOC;
		sys_mm_req.addr_len = BUDDY_MANAGED_SIZE; // buddy allocator can manage 1GB most
		seg_alloc_req->write(sys_mm_req);
		state = INIT_ALLOC_SEG_RET;
		break;
	case INIT_ALLOC_SEG_RET:
		if (seg_alloc_ret->empty())
			break;
		sys_mm_ret = seg_alloc_ret->read();
		if (sys_mm_ret.ret == SEG_FAILED) {
			PR("[init]: sysmm failed to alloc chunk\n");
			state = INIT_ALLOC_SEG;
			return FUNC_FAILED;
		}
		buddy_start = sys_mm_ret.addr_len;
		PR("[init]: buddy allocator base address: %#x\n", buddy_start.to_uint64());
		init_buddy_addr->write(buddy_start.to_uint64());
		/* alloc 2^10 * 512 bit for BRAM mapping table */
		lib_mm_req.opcode = BUDDY_ALLOC;
		lib_mm_req.order = NR_HT_BUCKET_DRAM_SHIFT + MEM_BUS_SHIFT - 3 - BUDDY_MIN_SHIFT;
		buddy_alloc_req->write(lib_mm_req);
		state = INIT_ALLOC_TABEL_RET;
		break;
	case INIT_ALLOC_TABEL_RET:
		if (buddy_alloc_ret->empty())
			break;
		lib_mm_ret = buddy_alloc_ret->read();
		if (lib_mm_ret.stat == BUDDY_FAILED) {
			PR("[init]: buddy allocator failed to alloc mapping table\n");
			state = INIT_ALLOC_SEG;
			return FUNC_FAILED;
		}
		table_base_addr = lib_mm_ret.addr;
		init_tbl_addr->write(table_base_addr);
		/* alloc meta data for heap allocator */
		lib_mm_req.opcode = BUDDY_ALLOC;
		lib_mm_req.order = 22 - BUDDY_MIN_SHIFT;  // this value is calculated manully from BUDDY_META_SIZE
		buddy_alloc_req->write(lib_mm_req);
		state = INIT_ALLOC_META_RET;
		break;
	case INIT_ALLOC_META_RET:
		if (buddy_alloc_ret->empty())
			break;
		lib_mm_ret = buddy_alloc_ret->read();
		if (lib_mm_ret.stat == BUDDY_FAILED) {
			PR("[init]: buddy allocator failed to alloc metadata space for heap allocator");
			state = INIT_ALLOC_SEG;
			return FUNC_FAILED;
		}
		heap_meta_start = lib_mm_ret.addr;
		PR("[init]: heap allocator base address: %#x\n", heap_meta_start.to_uint64());
		init_heap_addr->write(heap_meta_start.to_uint64());
		state = INIT_ALLOC_SEG;
		return FUNC_DOWN;
	}
	return FUNC_WIP;
}
