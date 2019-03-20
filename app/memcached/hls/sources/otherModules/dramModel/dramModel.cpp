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
#include "dramModel.h"

void memAccess(stream<extMemCtrlWord> &aggregateMemCmd, stream<ap_uint<512> > &rdDataOut, stream<ap_uint<512> > &wrDataIn)
{
	#pragma HLS pipeline II=1 enable_flush		// Data-flow interval=1 that is, 1 clock cycle between the start of consecutive loop iterations
	#pragma HLS INLINE off						// No function in-lining -> no function "replication" in hardware implementation

	#pragma HLS LATENCY min=1 max=2
	static ap_uint<512> memArray[noOfMemLocations];
#pragma HLS DEPENDENCE variable=memArray inter false
	static enum mState {MEM_IDLE = 0, MEM_ACCESS} memState;
	static extMemCtrlWord inputWord = {0, 0, 0};
	static uint8_t readLatencyCounter = 0;
	
	switch(memState)
	{
	case	MEM_IDLE:
		if (!aggregateMemCmd.empty())
		{
			aggregateMemCmd.read(inputWord);
			memState = MEM_ACCESS;
		}
		break;
	case	MEM_ACCESS:
		if (inputWord.rdOrWr == 0) {
			rdDataOut.write(memArray[inputWord.address]);
			if (inputWord.count == 1)
				memState = MEM_IDLE;
			else
			{
				inputWord.count--;
				inputWord.address++;
			}
		}
		else if (inputWord.rdOrWr == 1 && !wrDataIn.empty()) {
			memArray[inputWord.address] = wrDataIn.read();
			if (inputWord.count == 1)
				memState = MEM_IDLE;
			else {
				inputWord.count--;
				inputWord.address++;
			}
		}
		break;
	}
}

void cmdAggregator(stream<memCtrlWord> &rdCmdIn, stream<memCtrlWord> &wrCmdIn, stream<extMemCtrlWord> &aggregateMemCmd) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	if(!wrCmdIn.empty()) {
		memCtrlWord 	tempCtrlWord 	= wrCmdIn.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address.range(dramNoOfAddressBits-1, 0), tempCtrlWord.count, 1};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
	else if(!rdCmdIn.empty()) {
		memCtrlWord 	tempCtrlWord 	= rdCmdIn.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address.range(dramNoOfAddressBits-1, 0), tempCtrlWord.count, 0};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
}

void dramModel(stream<memCtrlWord> &rdCmdIn, stream<ap_uint<512> > &rdDataOut, stream<memCtrlWord> &wrCmdIn, stream<ap_uint<512> > &wrDataIn) {
	#pragma HLS INTERFACE ap_ctrl_none port=return // The block-level interface protocol is removed

	#pragma HLS DATAFLOW interval=1

	#pragma HLS DATA_PACK variable=rdCmdIn
	#pragma HLS DATA_PACK variable=wrCmdIn

	/*#pragma HLS RESOURCE variable=rdCmdIn 	core=AXI4Stream
	#pragma HLS RESOURCE variable=wrCmdIn 	core=AXI4Stream
	#pragma HLS RESOURCE variable=rdDataOut core=AXI4Stream
	#pragma HLS RESOURCE variable=wrDataIn 	core=AXI4Stream*/
	#pragma HLS INTERFACE port=rdCmdIn		axis
	#pragma HLS INTERFACE port=rdDataOut	axis
	#pragma HLS INTERFACE port=wrCmdIn		axis
	#pragma HLS INTERFACE port=wrDataIn		axis

	static stream<extMemCtrlWord> aggregateMemCmd("aggregateMemCmd");

	#pragma HLS DATA_PACK variable=aggregateMemCmd

	#pragma HLS STREAM variable=aggregateMemCmd depth=16

	cmdAggregator(rdCmdIn, wrCmdIn, aggregateMemCmd);
	memAccess(aggregateMemCmd, rdDataOut, wrDataIn);
}
