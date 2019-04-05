#include "globals.h"

void readConverter(stream<memCtrlWord> &memRdCmd, stream<ap_uint<memBusWidth> > &memRdData,
		   stream<datamoverCtrlWord> &dmRdCmd,
		   stream<axiWord> &dmRdData, stream<ap_uint<8> > &dmRdStatus)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS pipeline II=1 enable_flush

	#pragma HLS DATA_PACK 	variable=memRdCmd
	#pragma HLS DATA_PACK 	variable=dmRdCmd
	#pragma HLS DATA_PACK 	variable=dmRdData

	#pragma HLS RESOURCE 	variable=dmRdStatus 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=memRdData 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmRdCmd	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=dmRdData 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=memRdCmd	core=AXI4Stream

	static ap_uint<4> tagCounter = 0;

	if (!memRdCmd.empty() && !dmRdCmd.full()) {
		memCtrlWord readTemp = memRdCmd.read();
		ap_uint<32> convertedAddress = readTemp.address * 64;

		datamoverCtrlWord readCtrlWord = {(readTemp.count * (memBusWidth/8)), 1, 0, 1, 0, convertedAddress, tagCounter, 0};
		dmRdCmd.write(readCtrlWord);
		tagCounter++;
	}

	if (!dmRdData.empty() && !memRdData.full()) {
		axiWord readTemp = dmRdData.read();
		memRdData.write(readTemp.data);
	}
	if (!dmRdStatus.empty()) {
		ap_uint<8> tempVariable = dmRdStatus.read();
	}
}
