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

void memcachedPipeline(stream<extendedAxiWord> &inData, stream<extendedAxiWord> &outData,
					   stream<memCtrlWord> &dramValueStoreMemRdCmd, stream<ap_uint<512> > &dramValueStoreMemRdData, stream<memCtrlWord> &dramValueStoreMemWrCmd, stream<ap_uint<512> > &dramValueStoreMemWrData,
					   stream<flashMemCtrlWord> &flashValueStoreMemRdCmd, stream<ap_uint<64> > &flashValueStoreMemRdData, stream<flashMemCtrlWord> &flashValueStoreMemWrCmd, stream<ap_uint<64> > &flashValueStoreMemWrData,
					   stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemRdCmd, stream<ap_uint<512> > &hashTableMemWrData, stream<memCtrlWord> &hashTableMemWrCmd,
					   stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone) {

	#pragma HLS INTERFACE ap_ctrl_none port=return 
	#pragma HLS INTERFACE ap_none register port=flushReq 
	#pragma HLS INTERFACE ap_none register port=flushAck
	#pragma HLS INTERFACE ap_none register port=flushDone

	//#pragma HLS DATA_PACK 	variable=inData
	//#pragma HLS DATA_PACK 	variable=outData
	#pragma HLS DATA_PACK 	variable=hashTableMemRdData
	#pragma HLS DATA_PACK 	variable=hashTableMemRdCmd
	#pragma HLS DATA_PACK 	variable=hashTableMemWrData
	#pragma HLS DATA_PACK 	variable=hashTableMemWrCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemRdCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemRdData
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemWrCmd
	#pragma HLS DATA_PACK 	variable=dramValueStoreMemWrData
	#pragma HLS DATA_PACK 	variable=flashValueStoreMemRdCmd
	#pragma HLS DATA_PACK 	variable=flashValueStoreMemRdData
	#pragma HLS DATA_PACK 	variable=flashValueStoreMemWrCmd
	#pragma HLS DATA_PACK 	variable=flashValueStoreMemWrData

#pragma HLS INTERFACE port=inData axis
#pragma HLS INTERFACE port=outData axis
#pragma HLS INTERFACE port=hashTableMemWrData axis
#pragma HLS INTERFACE port=hashTableMemRdData axis
#pragma HLS INTERFACE port=hashTableMemRdCmd axis
#pragma HLS INTERFACE port=hashTableMemWrCmd axis
#pragma HLS INTERFACE port=flashValueStoreMemRdCmd axis
#pragma HLS INTERFACE port=flashValueStoreMemRdData axis
#pragma HLS INTERFACE port=flashValueStoreMemWrCmd axis
#pragma HLS INTERFACE port=flashValueStoreMemWrData axis
#pragma HLS INTERFACE port=dramValueStoreMemRdCmd axis
#pragma HLS INTERFACE port=dramValueStoreMemRdData axis
#pragma HLS INTERFACE port=dramValueStoreMemWrCmd axis
#pragma HLS INTERFACE port=dramValueStoreMemWrData axis
	/*#pragma HLS RESOURCE 	variable=inData 					core=AXI4Stream
	#pragma HLS RESOURCE 	variable=outData 					core=AXI4Stream
	#pragma HLS RESOURCE 	variable=hashTableMemWrData			core=AXI4Stream
	#pragma HLS RESOURCE 	variable=hashTableMemRdData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=hashTableMemRdCmd			core=AXI4Stream
	#pragma HLS RESOURCE 	variable=hashTableMemWrCmd			core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dramValueStoreMemRdCmd 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dramValueStoreMemRdData	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dramValueStoreMemWrCmd 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dramValueStoreMemWrData 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=flashValueStoreMemRdCmd 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=flashValueStoreMemRdData	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=flashValueStoreMemWrCmd 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=flashValueStoreMemWrData 	core=AXI4Stream*/
	//#pragma HLS RESOURCE 	variable=addressReturnOut			core=AXI4Stream
	//#pragma HLS RESOURCE 	variable=addressAssignDramIn 		core=AXI4Stream
	//#pragma HLS RESOURCE 	variable=addressAssignFlashIn 		core=AXI4Stream
	#pragma HLS INTERFACE 	port=addressReturnOut 				axis
	#pragma HLS INTERFACE 	port=addressAssignDramIn 			axis
	#pragma HLS INTERFACE 	port=addressAssignFlashIn 			axis

	#pragma HLS DATAFLOW interval=1

	static stream<pipelineWord>	requestParser2hashTable("requestParser2hashTable");
	static stream<pipelineWord>	hashTable2splitter("hashTable2splitter");
	static stream<pipelineWord> merger2responseFormatter("merger2responseFormatter");
	static stream<pipelineWord> splitter2valueStoreFlash("splitter2valueStoreFlash");
	static stream<pipelineWord> splitter2valueStoreDram("splitter2valueStoreDram");
	static stream<pipelineWord> valueStoreFlash2merger("valueStoreFlash2merger");
	static stream<pipelineWord> valueStoreDram2merger("valueStoreDram2Smerger");

	#pragma HLS DATA_PACK 	variable=requestParser2hashTable
	#pragma HLS DATA_PACK 	variable=hashTable2splitter
	#pragma HLS DATA_PACK 	variable=merger2responseFormatter
	#pragma HLS DATA_PACK 	variable=splitter2valueStoreFlash
	#pragma HLS DATA_PACK 	variable=splitter2valueStoreDram
	#pragma HLS DATA_PACK 	variable=valueStoreFlash2merger
	#pragma HLS DATA_PACK 	variable=valueStoreDram2merger

	#pragma HLS STREAM variable=requestParser2hashTable 		depth=16
	#pragma HLS STREAM variable=hashTable2splitter				depth=16
	#pragma HLS STREAM variable=merger2responseFormatter	 	depth=16
	#pragma HLS STREAM variable=splitter2valueStoreFlash 		depth=16
	#pragma HLS STREAM variable=splitter2valueStoreDram			depth=16
	#pragma HLS STREAM variable=valueStoreFlash2merger	 		depth=16
	#pragma HLS STREAM variable=valueStoreDram2merger			depth=16

	binaryParser(inData, requestParser2hashTable);
	hashTable(requestParser2hashTable, hashTable2splitter, hashTableMemRdData, hashTableMemRdCmd, hashTableMemWrData, hashTableMemWrCmd, addressReturnOut, addressAssignDramIn, addressAssignFlashIn, flushReq, flushAck, flushDone);
	splitter(hashTable2splitter, splitter2valueStoreFlash, splitter2valueStoreDram);
	valueStoreDram(splitter2valueStoreDram, dramValueStoreMemRdCmd, dramValueStoreMemRdData, dramValueStoreMemWrCmd, dramValueStoreMemWrData, valueStoreDram2merger);
	valueStoreFlash(splitter2valueStoreFlash, flashValueStoreMemRdCmd, flashValueStoreMemRdData, flashValueStoreMemWrCmd, flashValueStoreMemWrData, valueStoreFlash2merger);
	merger(valueStoreFlash2merger, valueStoreDram2merger, merger2responseFormatter);
	binaryResponse(merger2responseFormatter, outData);
}
