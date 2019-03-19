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
#include <ap_int.h>
#include <stdint.h>
#include <ap_shift_reg.h>

using namespace hls;

const uint16_t MaxDatagramSize = 32768; // Maximum size of an IP datagram in bytes
const uint16_t ARP 		= 0x0806;
const uint16_t IPv4 	= 0x0800;
const uint16_t DROP 	= 0x0000;
const uint16_t FORWARD 	= 0x0001;

const uint8_t ICMP = 0x01;
const uint8_t UDP = 0x11;
const uint8_t TCP = 0x06;

struct axiWord {
	ap_uint<64> data;
	ap_uint<8>	keep;
	ap_uint<1>	last;
	axiWord() {}
	axiWord(ap_uint<64> data, ap_uint<8> keep, ap_uint<1> last)
	: data(data), keep(keep), last(last) {}
};

struct subSums
{
	ap_uint<17>		sum0;
	ap_uint<17>		sum1;
	ap_uint<17>		sum2;
	ap_uint<17>		sum3;
	bool			ipMatch;
	subSums() {}
	subSums(ap_uint<17> sums[4], bool match)
		:sum0(sums[0]), sum1(sums[1]), sum2(sums[2]), sum3(sums[3]), ipMatch(match) {}
	subSums(ap_uint<17> s0, ap_uint<17> s1, ap_uint<17> s2, ap_uint<17> s3, bool match)
		:sum0(s0), sum1(s1), sum2(s2), sum3(s3), ipMatch(match) {}
};

/** @defgroup ip_handler IP handler
 *
 */
void ip_handler(stream<axiWord>&		dataIn,
				stream<axiWord>&		ARPdataOut,
				stream<axiWord>&		ICMPdataOut,
				stream<axiWord>&		ICMPexpDataOut,
				stream<axiWord>&		UDPdataOut,
				stream<axiWord>&		TCPdataOut,
				ap_uint<32>				regIpAddress,
				ap_uint<48>				myMacAddress);
