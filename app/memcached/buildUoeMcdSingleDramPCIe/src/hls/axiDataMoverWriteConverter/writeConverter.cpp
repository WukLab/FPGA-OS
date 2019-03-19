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

void writeConverter(stream<memCtrlWord> &memWrCmd, stream<ap_uint<memBusWidth> > &memWrData, stream<datamoverCtrlWord> &dmWrCmd, stream<axiWord> &dmWrData, stream<ap_uint<8> > &dmWrStatus) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	
	#pragma HLS DATA_PACK 	variable=memWrCmd
	#pragma HLS DATA_PACK 	variable=dmWrCmd
	#pragma HLS DATA_PACK 	variable=dmWrData

	#pragma HLS RESOURCE 	variable=memWrCmd 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=memWrData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmWrCmd		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmWrData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmWrStatus		core=AXI4Stream

	static ap_uint<4> 	tagCounter 			= 0;
	static ap_uint<16> 	noOfBytesToWrite 	= 0;
	static ap_uint<16> 	byteCount			= 0;

	static enum wcState{WRC_IDLE = 0, WRC_FWD, WRC_STATUS} writeConverterState;

	switch(writeConverterState) {
	case WRC_IDLE:
		if (!memWrCmd.empty() && !dmWrCmd.full()) {
			memCtrlWord writeTemp = memWrCmd.read();
			ap_uint<32> convertedAddress = writeTemp.address * 64;
			datamoverCtrlWord writeCtrlWord = {(writeTemp.count*(memBusWidth/8)), 1, 0, 1, 0, convertedAddress, tagCounter, 0};
			noOfBytesToWrite = writeTemp.count;
			dmWrCmd.write(writeCtrlWord);
			tagCounter++;
			writeConverterState = WRC_FWD;
		}
		break;
	case WRC_FWD:
		if (!memWrData.empty() && !dmWrData.full()) {
			axiWord writeTemp2 = {0, 0xFFFFFFFFFFFFFFFF, 0};
			memWrData.read(writeTemp2.data);
			if (byteCount == noOfBytesToWrite - 1) {
				writeTemp2.last = 1;
				writeConverterState = WRC_STATUS;
				byteCount = 0;
			}
			else
				byteCount++;
			dmWrData.write(writeTemp2);
		}
		break;
	case WRC_STATUS:
		if (!dmWrStatus.empty()) {
			ap_uint<8> tempVariable = dmWrStatus.read();
			writeConverterState = WRC_IDLE;
		}
		break;
	}
}
