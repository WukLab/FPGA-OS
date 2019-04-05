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

void memcachedBuddy(stream<extendedAxiWord> &inData, stream<extendedAxiWord> &outData,
		    stream<memCtrlWord> &dramValueStoreMemRdCmd, stream<ap_uint<512> > &dramValueStoreMemRdData,
		    stream<memCtrlWord> &dramValueStoreMemWrCmd, stream<ap_uint<512> > &dramValueStoreMemWrData,
		    stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemRdCmd,
		    stream<ap_uint<512> > &hashTableMemWrData, stream<memCtrlWord> &hashTableMemWrCmd,
		    stream<struct buddy_alloc_if>& alloc,
		    stream<struct buddy_alloc_ret_if>& alloc_ret)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS DATAFLOW interval=1

	#pragma HLS DATA_PACK 	variable=hashTableMemRdData
	#pragma HLS DATA_PACK 	variable=hashTableMemRdCmd
	#pragma HLS DATA_PACK 	variable=hashTableMemWrData
	#pragma HLS DATA_PACK 	variable=hashTableMemWrCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemRdCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemRdData
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemWrCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemWrData
	#pragma HLS DATA_PACK 	variable=alloc
	#pragma HLS DATA_PACK 	variable=alloc_ret

	#pragma HLS INTERFACE port=inData axis
	#pragma HLS INTERFACE port=outData axis
	#pragma HLS INTERFACE port=hashTableMemWrData axis
	#pragma HLS INTERFACE port=hashTableMemRdData axis
	#pragma HLS INTERFACE port=hashTableMemRdCmd axis
	#pragma HLS INTERFACE port=hashTableMemWrCmd axis
	#pragma HLS INTERFACE port=dramValueStoreMemRdCmd axis
	#pragma HLS INTERFACE port=dramValueStoreMemRdData axis
	#pragma HLS INTERFACE port=dramValueStoreMemWrCmd axis
	#pragma HLS INTERFACE port=dramValueStoreMemWrData axis

	#pragma HLS INTERFACE port=alloc 		axis
	#pragma HLS INTERFACE port=alloc_ret 		axis

	static stream<pipelineWord>	requestParser2hashTable("requestParser2hashTable");
	static stream<pipelineWord>	hashTable2valueStoreDram("hashTable2valueStoreDram");
	static stream<pipelineWord>	valueStoreDram2responseFormatter("valueStoreDram2responseFormatter");

	#pragma HLS DATA_PACK 	variable=requestParser2hashTable
	#pragma HLS DATA_PACK 	variable=hashTable2valueStoreDram
	#pragma HLS DATA_PACK 	variable=valueStoreDram2responseFormatter

	#pragma HLS STREAM variable=requestParser2hashTable		depth=1024
	#pragma HLS STREAM variable=hashTable2valueStoreDram		depth=1024
	#pragma HLS STREAM variable=valueStoreDram2responseFormatter	depth=1024

	binaryParser(inData, requestParser2hashTable);

	hashTableWithBuddy(requestParser2hashTable,
			   hashTable2valueStoreDram,
			   hashTableMemRdData, hashTableMemRdCmd,
			   hashTableMemWrData, hashTableMemWrCmd,
			   alloc, alloc_ret);

	valueStoreDram(hashTable2valueStoreDram,
		       dramValueStoreMemRdCmd, dramValueStoreMemRdData,
		       dramValueStoreMemWrCmd, dramValueStoreMemWrData,
		       valueStoreDram2responseFormatter);

	binaryResponse(valueStoreDram2responseFormatter, outData);
}
