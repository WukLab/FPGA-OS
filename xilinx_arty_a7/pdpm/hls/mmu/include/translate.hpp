/*
 * This header file defines generic structures
 * used by all low-level translation services (e.g., segment, paging).
 */

#ifndef _MMU_TRANSLATE_H_
#define _MMU_TRANSLATE_H_

#include <ap_int.h>
#include <hls_stream.h>

/* mmu_trans_data->type */
#define	MMU_TRANS_READ	0
#define MMU_TRANS_WRITE	1

/*
 * This structure describes the AXI-S interface between upper layer MMU
 * lower level translation service (e.g., segment, paging).
 *
 * This is template so you can customize the address width and restrict
 * the maximum access length.
 */
template <int ADDR_WIDTH, int NR_BYTES_ORDER>
struct mmu_trans_data {
	ap_uint<ADDR_WIDTH>	address;
	ap_uint<NR_BYTES_ORDER>	nr_bytes;
	ap_uint<1>		type;
};

#endif /* _MMU_TRANSLATE_H_ */
