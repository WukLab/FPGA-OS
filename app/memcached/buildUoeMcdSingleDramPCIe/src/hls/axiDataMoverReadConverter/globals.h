#ifndef _GLOBALS_H
#define _GLOBALS_H

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <math.h>
#include <hls_stream.h>
#include "ap_int.h"
#include <stdint.h>
#include <vector>
//#include "ap_cint.h"

#define memBusWidth	512
#define noOfBins	4

using namespace hls;

/*template <uint8_t D>
struct myAxi {
	ap_uint<D>		data;
	ap_uint<D/8> 	keep;		// Shows which bytes contain valid data in this data word. Valid only when last is also asserted
	ap_uint<1>		last;		// Signals the last data word in a packet
};*/

struct axiWord {
	ap_uint<memBusWidth>	data;
	ap_uint<64>		keep;		// Shows which bytes contain valid data in this data word. Valid only when last is also asserted
	ap_uint<1>		last;		// Signals the last data word in a packet
};

struct memCtrlWord {
	ap_uint<32> 	address;
	ap_uint<8>	count;
};

struct datamoverCtrlWord {
	ap_uint<23>		btt;
	ap_uint<1>		type;
	ap_uint<6>		dsa;
	ap_uint<1>		eof;
	ap_uint<1>		drr;
	ap_uint<32>		startAddress;
	ap_uint<4>		tag;
	ap_uint<4>		rsvd;
};

void readConverter(stream<memCtrlWord> &memRdCmd, stream<ap_uint<memBusWidth> > &memRdData, stream<datamoverCtrlWord> &dmRdCmd, stream<axiWord> &dmRdData, stream<ap_uint<8> > &dmRdStatus);

#endif
