/*
 * For more configure options, please check mm/mapping/hls_mapping.
 */
#ifndef _LEGOFPGA_AXIS_MAPPING_H_
#define _LEGOFPGA_AXIS_MAPPING_H_

#define MAPPING_VIRTUAL_WIDTH	32
#define MAPPING_PHYSICAL_WIDTH	32

#define MAPPING_REQUEST_READ	(0)
#define MAPPING_REQUEST_WRITE	(1)
#define MAPPING_SET		(2)
#define MAPPING_PERMISSION_R	(0x00)  // 0000 0000
#define MAPPING_PERMISSION_RW	(0x80)  // 1000 0000

/*
 * The width of a single hash bucket
 */
#define NR_BITS_BUCKET			512
#define NR_BYTE_BUCKET			(NR_BITS_BUCKET / 8)

/*
 * Number of BRAM hashtable buckets.
 */
#define NR_HT_BUCKET_BRAM_SHIFT		6
#define NR_HT_BUCKET_BRAM		(1 << NR_HT_BUCKET_BRAM_SHIFT)

/*
 * Number of DRAM hashtable buckets.
 */
#define NR_HT_BUCKET_DRAM_SHIFT		10
#define NR_HT_BUCKET_DRAM		(1 << NR_HT_BUCKET_DRAM_SHIFT)

/*
 * The base physical address of the mapping table
 */
#define MAPPING_TABLE_ADDRESS_BASE	(0x100000)
#define MAPPING_TABLE_SIZE		(NR_HT_BUCKET_DRAM * NR_BYTES_BUCKET)
#define MAPPING_TABLE_END		(MAPPING_TABLE_ADDRESS_BASE + MAPPING_TABLE_SIZE)

/*
 * @address is the key
 * @length is the value
 */
struct mapping_request {
	ap_uint<MAPPING_VIRTUAL_WIDTH>	address;
	ap_uint<MAPPING_VIRTUAL_WIDTH>	length;
	/*
	 * opcode bits def:
	 * 0:1	-> operation code: READ(0)/WRITE(1)/SET(2)
	 * 2:6	-> reserved
	 *   7	-> permission: R(0)/RW(1) (only used when operation is SET)
	 */
	ap_uint<8>			opcode;
};

/*
 * @address is the value
 * @status: 0 is success, 1 is failure.
 */
struct mapping_reply {
	ap_uint<1>			status;
	ap_uint<MAPPING_PHYSICAL_WIDTH>	address;

	/*
	 * The pipeline state
	 * PI_STATE_HIT_BRAM	(0x0001)
	 * PI_STATE_HIT_DRAM	(0x0010)
	 * PI_STATE_MISS_BRAM	(0x0100)
	 * PI_STATE_MISS_DRAM	(0x1000)
	 */
	unsigned char			__internal_status;
};

#endif /* _LEGOFPGA_AXIS_MAPPING_H_ */
