#ifndef _SYSNETRX64_H_
#define _SYSNETRX64_H_

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

#include <fpga/axis_net.h>

typedef struct eth_header_t {
	ap_uint<48> 			mac_dest;
	ap_uint<48> 			mac_src;
	ap_uint<16> 			mac_type;
} eth_header_t;

typedef struct ip_header_t {
	ap_uint<32>				word0;
	ap_uint<32>				word1;
	ap_uint<32>				word2;
	ap_uint<32>				word3;
	ap_uint<32>				word4;
} ip_header_t;

typedef struct lego_header_t {
	ap_uint<8>				appid;
	ap_uint<48>				seqnum;
} lego_header_t;

void sysnet_rx_64(hls::stream<struct net_axis_64> *input,
		  hls::stream<struct net_axis_64> *output0,
		  hls::stream<struct net_axis_64> *output1);

#endif /* _SYSNETRX64_H_ */
