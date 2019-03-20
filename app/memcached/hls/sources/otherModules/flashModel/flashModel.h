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
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <math.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>
#include "ap_int.h"
#include <stdint.h>
//#include "ap_cint.h"

using namespace hls;

#define noOfMemLocations 65536
#define ReadLatency 1
const uint8_t	flashMemAddressWidth		= 32;


struct flashMemCtrlWord
{
	ap_uint<flashMemAddressWidth> 	address;
	ap_uint<13>						count;
};

struct flashExtMemCtrlWord
{
	ap_uint<flashMemAddressWidth> 	address;
	ap_uint<13>						count;
	ap_uint<1>						rdOrWr;
};

void flashMemAccess(stream<flashExtMemCtrlWord> &flashAggregateMemCmd, stream<ap_uint<64> > &rdDataOut, stream<ap_uint<64> > &wrDataIn);

void flashCmdAggregator(stream<flashMemCtrlWord> &rdCmdIn, stream<flashMemCtrlWord> &wrCmdIn, stream<flashExtMemCtrlWord> &flashAggregateMemCmd);
