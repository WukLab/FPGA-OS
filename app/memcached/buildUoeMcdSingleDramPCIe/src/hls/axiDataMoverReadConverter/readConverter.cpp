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

void readConverter(stream<memCtrlWord> &memRdCmd, stream<ap_uint<memBusWidth> > &memRdData, stream<datamoverCtrlWord> &dmRdCmd,
				   stream<axiWord> &dmRdData, stream<ap_uint<8> > &dmRdStatus) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS pipeline II=1 enable_flush

	#pragma HLS DATA_PACK 	variable=memRdCmd
	#pragma HLS DATA_PACK 	variable=dmRdCmd
	#pragma HLS DATA_PACK 	variable=dmRdData

	#pragma HLS RESOURCE 	variable=dmRdStatus 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=memRdData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmRdCmd		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmRdData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=memRdCmd		core=AXI4Stream

	static ap_uint<4> tagCounter = 0;
	//static enum rcState{RDC_IDLE = 0, RDC_FWD, RDC_STATUS} readConverterState;

	//switch(readConverterState) {
	//case RDC_IDLE:
		if (!memRdCmd.empty() && !dmRdCmd.full()) {
			memCtrlWord readTemp = memRdCmd.read();
			ap_uint<32> convertedAddress = readTemp.address * 64;
			datamoverCtrlWord readCtrlWord = {(readTemp.count * (memBusWidth/8)), 1, 0, 1, 0, convertedAddress, tagCounter, 0};
			//ap_uint<16> readCtrlWord = readTemp.address.range(15, 0);
			dmRdCmd.write(readCtrlWord);
			tagCounter++;
			//readConverterState = RDC_FWD;
		}
		//break;
	//case RDC_FWD:
		if (!dmRdData.empty() && !memRdData.full()) {
			axiWord readTemp = dmRdData.read();
			memRdData.write(readTemp.data);
			//if (readTemp.last)
				//readConverterState = RDC_STATUS;
		}
		//break;
	//case RDC_STATUS:
		if (!dmRdStatus.empty()) {
			ap_uint<8> tempVariable = dmRdStatus.read();
			//readConverterState = RDC_IDLE;
		}
		//break;
	}
//}
