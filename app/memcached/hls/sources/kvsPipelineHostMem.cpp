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

void kvsPipelineHostMem(stream<pipelineWord> &kvsIn, stream<pipelineWord> &kvsOut,
					   stream<memCtrlWord> &hostMemValueStoreMemRdCmd, stream<ap_uint<256> > &hostMemValueStoreMemRdData, stream<memCtrlWord> &hostMemValueStoreMemWrCmd, stream<ap_uint<256> > &hostMemValueStoreMemWrData,
					   stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemRdCmd, stream<ap_uint<512> > &hashTableMemWrData, stream<memCtrlWord> &hashTableMemWrCmd,
					   stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone) {

#pragma HLS RESOURCE variable=kvsIn core=AXI4Stream
#pragma HLS RESOURCE variable=kvsOut core=AXI4Stream
#pragma HLS RESOURCE variable=hostMemValueStoreMemRdCmd core=AXI4Stream
#pragma HLS RESOURCE variable=hostMemValueStoreMemRdData core=AXI4Stream
#pragma HLS RESOURCE variable=hostMemValueStoreMemWrCmd core=AXI4Stream
#pragma HLS RESOURCE variable=hostMemValueStoreMemWrData core=AXI4Stream
#pragma HLS RESOURCE variable=hashTableMemRdData core=AXI4Stream
#pragma HLS RESOURCE variable=hashTableMemRdCmd core=AXI4Stream
#pragma HLS RESOURCE variable=hashTableMemWrData core=AXI4Stream
#pragma HLS RESOURCE variable=hashTableMemWrCmd core=AXI4Stream
#pragma HLS RESOURCE variable=addressReturnOut core=AXI4Stream
#pragma HLS RESOURCE variable=addressAssignDramIn core=AXI4Stream
#pragma HLS RESOURCE variable=addressAssignFlashIn core=AXI4Stream

	#pragma HLS INTERFACE ap_ctrl_none port=return 
	#pragma HLS INTERFACE ap_none register port=flushReq 
	#pragma HLS INTERFACE ap_none register port=flushAck
	#pragma HLS INTERFACE ap_none register port=flushDone



	#pragma HLS DATAFLOW interval=1

	static stream<pipelineWord>	hashTable2ValueStore("hashTable2ValueStore");

	#pragma HLS DATA_PACK 	variable=kvsIn
	#pragma HLS DATA_PACK 	variable=hashTable2ValueStore
	#pragma HLS DATA_PACK 	variable=kvsOut

#pragma HLS DATA_PACK variable=hostMemValueStoreMemRdCmd
#pragma HLS DATA_PACK variable=hostMemValueStoreMemRdData
#pragma HLS DATA_PACK variable=hostMemValueStoreMemWrCmd
#pragma HLS DATA_PACK variable=hostMemValueStoreMemWrData
#pragma HLS DATA_PACK variable=hashTableMemRdData
#pragma HLS DATA_PACK variable=hashTableMemRdCmd
#pragma HLS DATA_PACK variable=hashTableMemWrData
#pragma HLS DATA_PACK variable=hashTableMemWrCmd
#pragma HLS DATA_PACK variable=addressReturnOut
#pragma HLS DATA_PACK variable=addressAssignDramIn
#pragma HLS DATA_PACK variable=addressAssignFlashIn

	#pragma HLS STREAM variable=hashTable2ValueStore				depth=16

	hashTable(kvsIn, hashTable2ValueStore, hashTableMemRdData, hashTableMemRdCmd, hashTableMemWrData, hashTableMemWrCmd, addressReturnOut, addressAssignDramIn, addressAssignFlashIn, flushReq, flushAck, flushDone);
	valueStoreHostMem(hashTable2ValueStore, hostMemValueStoreMemRdCmd, hostMemValueStoreMemRdData, hostMemValueStoreMemWrCmd, hostMemValueStoreMemWrData, kvsOut);
}
