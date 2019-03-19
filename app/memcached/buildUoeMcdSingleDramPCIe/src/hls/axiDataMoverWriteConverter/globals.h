/************************************************
Copyright (c) 2016, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors 
may be used to endorse or promote products derived from this software 
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.// Copyright (c) 2015 Xilinx, Inc.
************************************************/
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

#define memBusWidth 512
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
	ap_uint<64> 	keep;		// Shows which bytes contain valid data in this data word. Valid only when last is also asserted
	ap_uint<1>		last;		// Signals the last data word in a packet
};

struct memCtrlWord {
	ap_uint<32> 	address;
	ap_uint<8>		count;
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

void writeConverter(stream<memCtrlWord> &memWrCmd, stream<ap_uint<memBusWidth> > &memWrData, stream<datamoverCtrlWord> &dmWrCmd, stream<axiWord> &dmWrData, stream<ap_uint<8> > &dmWrStatus);

#endif
