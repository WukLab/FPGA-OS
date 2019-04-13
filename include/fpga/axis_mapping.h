/*
 * For mm/mapping IP
 */
#ifndef _LEGOFPGA_AXIS_MAPPING_H_
#define _LEGOFPGA_AXIS_MAPPING_H_

#define MAPPING_VIRTUAL_WIDTH	32
#define MAPPING_PHYSICAL_WIDTH	32

#define MAPPING_REQUEST_READ		(0)
#define MAPPING_REQUEST_WRITE		(1)
#define MAPPING_SET			(2)

/*
 * @address is the key
 * @length is the value
 */
struct mapping_request {
	ap_uint<MAPPING_VIRTUAL_WIDTH>	address;
	ap_uint<MAPPING_VIRTUAL_WIDTH>	length;
	ap_uint<8>			opcode;
};

/*
 * @address is the value
 * @status: 0 is success, 1 is failure.
 */
struct mapping_reply {
	ap_uint<MAPPING_PHYSICAL_WIDTH>	address;
	ap_uint<1>			status;
};

#endif /* _LEGOFPGA_AXIS_MAPPING_H_ */
