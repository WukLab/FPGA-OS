/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

/*
 * This file defines some common macros used by
 * both FPGA and Host side code. Everything here must be general.
 *
 * All header size macros are in BYTES.
 */

#ifndef _UAPI_NET_HEADER_H_
#define _UAPI_NET_HEADER_H_

struct ethernet_header {
	char	mac_dst[6];
	char	mac_src[6];
	char	ethtype[2];
} __attribute__((packed));

struct ip_header {
	char	word0[4];
	char	word1[4];
	char	word2[4];
	char	word3[4];
	char	word4[4];
} __attribute__((packed));

struct udp_header {
	char	port_src[2];
	char	port_dst[2];
	char	length[2];
	char	checksum[2];
} __attribute__((packed));

struct lego_header {
	char	app_id;
} __attribute__((packed));

#define ETHERNET_HEADER_SIZE	(14)
#define IP_HEADER_SIZE		(20)
#define UDP_HEADER_SIZE		(8)
#define LEGO_HEADER_SIZE	(sizeof(struct lego_header))

#define LEGO_HEADER_OFFSET \
	(ETHERNET_HEADER_SIZE + IP_HEADER_SIZE + UDP_HEADER_SIZE)

#define APP_HEADER_OFFSET	(64)

/*
 * Assume we have 14+20+8=42 bytes ahead
 * So the start bit is 42*8 = 336.
 * And end bit is 336 + 7 = 343.
 *
 * These are used by HLS code to write or read APP_ID.
 */
#define LEGO_HEADER_APP_ID_BITS_START	(336)
#define LEGO_HEADER_APP_ID_BITS_END	(343)

#endif /* _UAPI_NET_HEADER_H_ */
