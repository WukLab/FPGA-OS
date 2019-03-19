#include "udpShim.hpp"

void rxPath(stream<axiWord>&       	rxDataIn,
        	stream<metadata>&      	rxMetadataIn,
			stream<extendedAxiWord>	&rxDataOut,
        	stream<ap_uint<16> >&  	requestPortOpenOut,
        	stream<bool >&  		portOpenReplyIn,
			ap_uint<16>				portToOpen) {
#pragma HLS PIPELINE II=1

	static enum sState {LB_IDLE = 0, LB_W8FORPORT, LB_ACC_FIRST, LB_ACC} shimState;

	switch(shimState) {
		case LB_IDLE:
			if(!requestPortOpenOut.full()) {
				requestPortOpenOut.write(portToOpen);
				shimState = LB_W8FORPORT;
			}
			break;
		case LB_W8FORPORT:
			if(!portOpenReplyIn.empty()) {
				bool openPort = portOpenReplyIn.read();
				shimState = LB_ACC_FIRST;
			}
			break;
		case LB_ACC_FIRST:
			if (!rxDataIn.empty() && !rxMetadataIn.empty() && !rxDataOut.full()) {
				extendedAxiWord outputWord = {0, 0, 0, 0};
				axiWord tempWord 		= rxDataIn.read();
				metadata tempMetadata 	= rxMetadataIn.read();
				outputWord.data 		= tempWord.data;
				outputWord.keep 		= tempWord.keep;
				outputWord.last 		= tempWord.last;
				outputWord.user.range(95, 64) = tempMetadata.destinationSocket.addr;
				outputWord.user.range(63, 0) =  (tempMetadata.destinationSocket.port, tempMetadata.sourceSocket.addr, tempMetadata.sourceSocket.port);
				rxDataOut.write(outputWord);
				if (!tempWord.last)
					shimState = LB_ACC;
			}
			break;
		case LB_ACC:
			if (!rxDataIn.empty() && !rxDataOut.full()) {
				extendedAxiWord outputWord = {0, 0, 0, 0};
				axiWord tempWord = rxDataIn.read();
				outputWord.data = tempWord.data;
				outputWord.keep = tempWord.keep;
				outputWord.last = tempWord.last;
				rxDataOut.write(outputWord);
				if (tempWord.last)
					shimState = LB_ACC_FIRST;
			}
			break;
	}
}

void txPath(stream<extendedAxiWord> &txDataIn,
    		stream<axiWord> 	   	&txDataOut,
		 	stream<metadata> 	   	&txMetadataOut,
		 	stream<ap_uint<16> >   	&txLengthOut) {
#pragma HLS PIPELINE II=1
	static enum txsState {SHIM_IDLE = 0, SHIM_STREAM} shimState_tx;
	
	switch(shimState_tx) {
		case SHIM_IDLE:
			if (!txDataIn.empty() && !txDataOut.full() && !txMetadataOut.full() && !txLengthOut.full()) {
				extendedAxiWord tempWord = txDataIn.read();
				axiWord outputWord = {tempWord.data, tempWord.keep, tempWord.last};
				metadata metadataOutput = {tempWord.user.range(63, 48), tempWord.user.range(95, 64), tempWord.user.range(15, 0),tempWord.user.range(47, 16)};
				//metadata metadataOutput = {tempWord.user.range(15, 0), tempWord.user.range(47, 16), tempWord.user.range(63, 48),tempWord.user.range(95, 64)};
				txDataOut.write(outputWord);
				txMetadataOut.write(metadataOutput);		
				txLengthOut.write(tempWord.user.range(111, 96));	// Get the length directly from the pipeline output
				if (tempWord.last == 0)
					shimState_tx = SHIM_STREAM;
			}		
			break;
		case SHIM_STREAM:
			if (!txDataIn.empty() && !txDataOut.full()) {
				extendedAxiWord tempWord = txDataIn.read();
				axiWord outputWord = {tempWord.data, tempWord.keep, tempWord.last};
				txDataOut.write(outputWord);
				if (tempWord.last == 1)
					shimState_tx = SHIM_IDLE;
			}	
			break;
	}
}



void udpShim(stream<axiWord>&       rxDataIn, stream<metadata>&     	rxMetadataIn, stream<extendedAxiWord> &rxDataOut,
			 stream<ap_uint<16> >&  requestPortOpenOut, stream<bool >&	portOpenReplyIn, stream<extendedAxiWord> &txDataIn,
			 stream<axiWord> 		&txDataOut, stream<metadata> 		&txMetadataOut, stream<ap_uint<16> > 	&txLengthOut, ap_uint<16> portToOpen) {
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS DATAFLOW

	  	#pragma HLS DATA_PACK variable=rxMetadataIn
  	#pragma HLS DATA_PACK variable=txMetadataOut

	/*#pragma HLS INTERFACE port=rxDataIn 			axis
	#pragma HLS INTERFACE port=rxMetadataIn 		axis
	#pragma HLS INTERFACE port=rxDataOut 			axis
	#pragma HLS INTERFACE port=requestPortOpenOut 	axis
	#pragma HLS INTERFACE port=portOpenReplyIn 		axis
	#pragma HLS INTERFACE port=txDataOut 			axis
	#pragma HLS INTERFACE port=txMetadataOut	 	axis
	#pragma HLS INTERFACE port=txLengthOut	 		axis
	#pragma HLS INTERFACE port=txDataIn	 			axis*/
	#pragma HLS INTERFACE ap_stable port=portToOpen
	#pragma HLS resource core=AXI4Stream variable=rxDataIn 				metadata="-bus_bundle rxDataIn"
	#pragma HLS resource core=AXI4Stream variable=rxMetadataIn 			metadata="-bus_bundle rxMetadataIn"
	#pragma HLS resource core=AXI4Stream variable=rxDataOut 			metadata="-bus_bundle rxDataOut"
	#pragma HLS resource core=AXI4Stream variable=requestPortOpenOut 	metadata="-bus_bundle requestPortOpenOut"
	#pragma HLS resource core=AXI4Stream variable=portOpenReplyIn 		metadata="-bus_bundle portOpenReplyIn"
	#pragma HLS resource core=AXI4Stream variable=txDataOut 			metadata="-bus_bundle txDataOut"
	#pragma HLS resource core=AXI4Stream variable=txMetadataOut 		metadata="-bus_bundle txMetadataOut"
	#pragma HLS resource core=AXI4Stream variable=txLengthOut 			metadata="-bus_bundle txLengthOut"
	#pragma HLS resource core=AXI4Stream variable=txDataIn 				metadata="-bus_bundle txDataIn"

	rxPath(rxDataIn, rxMetadataIn, rxDataOut, requestPortOpenOut, portOpenReplyIn, portToOpen);
	txPath(txDataIn, txDataOut, txMetadataOut, txLengthOut);
}
