/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _MAPPING_HASH_H_
#define _MAPPING_HASH_H_

/*
 * The width of the compuated hash value
 */
#define NR_BITS_HASH		32

#define NR_HT_BUCKET_BRAM_SHIFT	4
#define NR_HT_BUCKET_DRAM_SHIFT	10
#define NR_HT_BUCKET_BRAM	(1 << NR_HT_BUCKET_BRAM_SHIFT)
#define NR_HT_BUCKET_DRAM	(1 << NR_HT_BUCKET_DRAM_SHIFT)

#define NR_BITS_KEY		32
#define NR_BITS_VAL		32
#define NR_SLOTS_PER_BUCKET	7

/*
 * Assume 32bits address space and chained
 * bucket is 64B aligned. Thus 32-6=26.
 */
#define NR_BITS_CHAIN_ADDR	26
#define NR_BITS_CHAIN_FLAG	1
#define NR_BITS_BUCKET		512
#define NR_BITS_RESERVED						\
	(NR_BITS_BUCKET - NR_BITS_CHAIN_ADDR - NR_BITS_CHAIN_FLAG -	\
	 (NR_SLOTS_PER_BUCKET * (NR_BITS_KEY + NR_BITS_VAL)))

#define NR_BITS_KEY_OFF		(0)
#define NR_BITS_VAL_OFF		(NR_BITS_KEY * NR_SLOTS_PER_BUCKET)

struct hash_bucket {
	ap_uint<NR_BITS_KEY>			key[NR_SLOTS_PER_BUCKET];
	ap_uint<NR_BITS_VAL>			val[NR_SLOTS_PER_BUCKET];
	ap_uint<NR_BITS_RESERVED>		_reserved;
	ap_uint<NR_BITS_CHAIN_ADDR>		chain_addr;
	ap_uint<NR_BITS_CHAIN_FLAG>		chained;
};

#endif /* _MAPPING_HASH_H_ */
