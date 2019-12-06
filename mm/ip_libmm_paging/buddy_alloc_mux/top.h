#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/axis_buddy.h>

using namespace hls;

/**
 * @buddy_alloc_req_1: buddy request with high priority
 * @buddy_alloc_ret_1: buddy return with high priority
 * @buddy_alloc_req_2: buddy request with low priority
 * @buddy_alloc_ret_2: buddy return with low priority
 * @fwd_buddy_alloc_req: forward buddy request to buddy allocator
 * @fwd_buddy_alloc_ret: forward buddy return from buddy allocator
 */
void buddy_alloc_mux(stream<struct buddy_alloc_if>	*buddy_alloc_req_1,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret_1,
		     stream<struct buddy_alloc_if>	*buddy_alloc_req_2,
		     stream<struct buddy_alloc_ret_if>	*buddy_alloc_ret_2,
		     
		     stream<struct buddy_alloc_if>	*fwd_buddy_alloc_req,
		     stream<struct buddy_alloc_ret_if>	*fwd_buddy_alloc_ret);