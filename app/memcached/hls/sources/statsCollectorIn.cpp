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
#include "globals.h"

void statsCollectorIn(stream<ioWord> &inData, stream<ioWord> &outData, stream<stats> &statsOut) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS DATA_PACK 	variable=inData
	#pragma HLS DATA_PACK 	variable=outData
	#pragma HLS DATA_PACK 	variable=statsOut

	#pragma HLS INTERFACE 	port=inData 	axis
	#pragma HLS INTERFACE 	port=outData 	axis
	#pragma HLS INTERFACE 	port=statsOut 	axis
	
	#pragma HLS INLINE
	#pragma HLS pipeline II=1 enable_flush

	static enum			sinState {SIN_IDLE = 0, SIN_STREAM} statsInState;
	
	static ap_uint<64>	totalPacketNo		= 0;
	static ap_uint<64>	asciiRequestsNo		= 0;
	static ap_uint<64>	binRequestsNo		= 0;
	static ap_uint<64>	ufoNo				= 0;
	static ap_uint<64>	binaryRequests[4] 	= {0, 0, 0, 0};	// SET, GET, DEL, FLUSH
	static ap_uint<64>	asciiRequests[4]	= {0, 0, 0, 0};	// SET, GET, DEL, FLUSH

	ioWord inputWord;
					
	switch(statsInState) {
		case SIN_IDLE:
			if(!inData.empty()) {
				inData.read(inputWord);										// Read data from the input
				if (inputWord.SOP == 1) {									// This should be the first packet word, but better make sure
					totalPacketNo++;
					if (inputWord.data.range(23, 0) == 0x746567				// GET 
					|| inputWord.data.range(23, 0) == 0x746573 				// SET
					|| inputWord.data.range(63, 0) == 0x6C615F6873756C66 	// FLUSH
					|| inputWord.data.range(47, 0) == 0x6574656C6564) { 	// DEL - Check for ASCII protocol cmds
						asciiRequestsNo++;									// If found, set the flag appropriately...
						if (inputWord.data.range(23, 0) == 0x746567)
							asciiRequests[1]++;
						else if (inputWord.data.range(23, 0) == 0x746573)
							asciiRequests[0]++;
						else if (inputWord.data.range(63, 0) == 0x6C615F6873756C66)
							asciiRequests[2]++;
						else if (inputWord.data.range(47, 0) == 0x6574656C6564)
							asciiRequests[3]++;
						outData.write(inputWord);
					}
					else if (inputWord.data.range(7, 0) == 0x80 {													// if not,
						binRequestsNo++;
						if (inputWord.data.range(15, 8) == 0x0)
							binaryRequests[1]++;
						else if (inputWord.data.range(15, 8) == 0x1)
							binaryRequests[0]++;
						else if (inputWord.data.range(15, 8) == 0x4)
							binaryRequests[2]++;
						else if (inputWord.data.range(15, 8) == 0x8)
							binaryRequests[3]++;
						outData.write(inputWord);
					}
					else 
						ufoNo++;
					if (inputWord.EOP == 0)									// if not...	
						statsInState = SIN_STREAM;							// go to the stream state and continue packet output
				}
			}
			break;
		case SIN_STREAM:
			if(!inData.empty()) {											// Check if data is present at the input
				inData.read(inputWord);										// Read them in
				outData.write(inputWord);
				if (inputWord.EOP == 1)
					statsInState = SIN_IDLE;
			}
			break;
	}
}
