/*
 * Copyright (c) 2019，Wuklab, UCSD.
 *
 * Xilinx ICAPE3 Helpers. Reference: UG570.
 * Please acknowledge us if you use this code.
 */
#ifndef _FPGA_HEADER_ICAP_H_
#define _FPGA_HEADER_ICAP_H_

/*
 * This is for Ultrascale+ family.
 * Other series might be different.
 */
#define ICAP_DATA_WIDTH		(32)

/* Active-Low ICAP input Enable */
#define ICAP_CSIB_ENABLE	(0)
#define ICAP_CSIB_DISABLE	(1)

/* Read active high, Write active low */
#define ICAP_RDWRB_WRITE	(0)
#define ICAP_RDWRB_READ		(1)

/*
 * Bits layout:
 *        3         2         14         2          11
 *   |  31-29   |  28-27 |  26-13   |  12-11   |  10-00  |
 *     hdr_type   opcode   reg_addr   reserved   wd_count
 *
 * Header type is always 001
 * Opcode:
 *	00 NOOP
 *	01 Read
 *	10 Write
 *	11 Reserved
 *
 * For register addresses, check UG570 Chapter 9 Table 9-19.
 * Note that only 5b out of 14b are used. From 00000 to 11111.
 */
struct icap_header_t1 {
	ap_uint<11>	word_count;	/* LSB */
	ap_uint<2>	reserved;
	ap_uint<14>	reg_addr;
	ap_uint<2>	opcode;
	ap_uint<3>	header_type;	/* MSB */
};

/* These are based on the above table */
#define ICAP_T1_REGADDR_SHIFT	(13)
#define ICAP_T1_REGADDR_MASK	(0x07FFE000)

enum icap_register_nr {
	ICAP_REG_CRC,
	ICAP_REG_FAR,
	ICAP_REG_FDRI,
	ICAP_REG_FDRO,
	ICAP_REG_CMD,
	ICAP_REG_CTL0,
	ICAP_REG_MASK,
	ICAP_REG_STAT,
	ICAP_REG_LOUT,
	ICAP_REG_COR0,
	ICAP_REG_MFWR,
	ICAP_REG_CBC,
	ICAP_REG_IDCODE,
	ICAP_REG_AXSS,
	ICAP_REG_COR1,
	ICAP_REG_WBSTAR,
	ICAP_REG_TIMER,
	ICAP_REG_BOOTSTS,
	ICAP_REG_CTL1,
	ICAP_REG_BSP1,

	NR_ICAP_REG,
};

enum icap_register_permission {
	ICAP_REG_PERMISSION_R,
	ICAP_REG_PERMISSION_W,
	ICAP_REG_PERMISSION_RW,
};

struct icap_register_entry {
	ap_uint<14>	addr;
	ap_uint<2>	rw;
};

#endif /* _FPGA_HEADER_ICAP_H_ */
