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
#include "../globals.h"

ap_uint<8> length2keep_mapping(uint8_t lengthValue) {
	//const static ap_uint<8> keepArray[9] = {0x00, 0x01, 0x03, 0x07, 0x0F, 0x1F, 0x3F, 0x7F, 0xFF};
	//return keepArray[lengthValue];
	switch(lengthValue) {
		case 8:
			return 0xFF;
			break;
		case 1:
			return 0x01;
			break;
		case 2:
			return 0x03;
			break;
		case 3:
			return 0x07;
			break;
		case 4:
			return 0x0F;
			break;
		case 5:
			return 0x1F;
			break;
		case 6:
			return 0x3F;
			break;
		case 7:
			return 0x7F;
			break;
		default:
			return 0xFF;
	}
}

void response_f(stream<pipelineWord> &respInput, stream<ap_uint<248> > &metadataBuffer, stream<ap_uint<64> > &valueBuffer) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static ap_uint<2>			inWordCounter 			= 0;
	static ap_uint<248>			bf_metadataTempBuffer 	= 0;		// This value stores the metadata coming from the pipeline and parallelizes the 3 words, so that they are reshuffled in the back-end function.
	// Storage path. Reads data of the bus and stores them into the buffers
	if (!valueBuffer.full() && !metadataBuffer.full() && !respInput.empty()) {
		pipelineWord tempInput;
		respInput.read(tempInput);
		if (tempInput.SOP == 1 && inWordCounter == 0) {
			bf_metadataTempBuffer.range(123, 0) = tempInput.metadata;
			if (tempInput.valueValid == 1)
				valueBuffer.write(tempInput.value);
			inWordCounter++;
		}
		else if (inWordCounter > 0) {
			if (inWordCounter < 2) {
				bf_metadataTempBuffer.range(247, 124) = tempInput.metadata;
				if (inWordCounter == 1)
					metadataBuffer.write(bf_metadataTempBuffer);
				inWordCounter++;
			}
			if (tempInput.valueValid == 1)
				valueBuffer.write(tempInput.value);
			if (tempInput.EOP == 1) {
				inWordCounter = 0;
			}
		}
	}
}

void response_r(stream<ap_uint<248> > &metadataBuffer, stream<ap_uint<64> > &valueBuffer, stream<extendedAxiWord> &respOutput) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	//Output path. Reads data from the internal buffers, reorders metadata and produces headers as needed and outputs them to the bus
	static uint16_t				valueLength				= 0;
	static uint8_t				br_outWordCounter		= 0;
	static uint8_t				outOpCode				= 0;
	static uint8_t				errorCode				= 0;
	static ap_uint<32>  		resp_ValueConvertTemp 	= 0;
	ap_uint<1> 					readTemp 				= 0;

	static ap_uint<248>		outMetadataTempBuffer;		// This value store the metadata coming from the UDP until they can be written into the metadatabuffer.
	static ap_uint<64>		xtrasBuffer = 0;
	extendedAxiWord			tempOutput = {0, 0, 0xFF, 0};

	if (br_outWordCounter == 0)	{
		if (!metadataBuffer.empty()) {
			metadataBuffer.read(outMetadataTempBuffer);
			outOpCode						= outMetadataTempBuffer.range(111, 104);
			errorCode						= outMetadataTempBuffer.range(119,112);		// Store error code
			br_outWordCounter++;
		}
	}
	else if (br_outWordCounter == 1) {
		if ((!valueBuffer.empty() && outOpCode == 0 && errorCode != 1) || errorCode == 1 || outOpCode != 0) {
			ap_uint<112> tmpMetadata;
			resp_ValueConvertTemp			= outMetadataTempBuffer.range(39, 8);
			resp_ValueConvertTemp			-=  8;
			valueLength						= resp_ValueConvertTemp;
			tmpMetadata.range(95, 0)		= outMetadataTempBuffer.range(219, 124);
			tempOutput.data 				= 0;
			xtrasBuffer						= 0;
			tempOutput.data.range(7, 0) 	= 0x81;
			tempOutput.data.range(15, 8) 	= outMetadataTempBuffer.range(111, 104);	// Opcodein our binary protocol implementation
			if (errorCode != 0)
				tempOutput.data.range(39, 32)	= 0;									// Extras Length
			else if (outOpCode == 0)
				tempOutput.data.range(39, 32)	= 4;									// Extras Length
			else
				tempOutput.data.range(39, 32)	= 0;									// Extras Length
			tempOutput.data.range(63, 56) 	= outMetadataTempBuffer.range(119,112);
			if (outOpCode == 0 && errorCode != 1) {
				valueBuffer.read(xtrasBuffer);
			}
			ap_uint<16> br_valueLengthTemp = 24; 	
			if (outOpCode == 0 && errorCode != 1) {
				
				ap_uint<16> tempVar = outMetadataTempBuffer.range(23, 8);
				br_valueLengthTemp += (tempVar - 4);
			}
			else if (errorCode == 1)
				br_valueLengthTemp = 32;
			tmpMetadata.range(111, 96)		= br_valueLengthTemp;
         		tempOutput.user = tmpMetadata;
			tempOutput.keep = 0xFF;
			br_outWordCounter++;
			respOutput.write(tempOutput);
		}
	}
	else if (br_outWordCounter == 2) {		// 2nd packet header word
		if (outOpCode == 0 && errorCode == 0) {
			resp_ValueConvertTemp 			= resp_ValueConvertTemp + 4;
			tempOutput.data.range(31, 0) 	= byteSwap32(resp_ValueConvertTemp.range(31, 0));
		}
		else if ((outOpCode == 0 || outOpCode == 4) && errorCode == 1)
			tempOutput.data.range(31, 0)	= 0x08000000;
		else if (outOpCode == 1 && errorCode == 1)
			tempOutput.data.range(31, 0)	= 0x00000000;
		//tempOutput.data.range(63, 32) 	= outMetadataTempBuffer.range(279, 248);
		br_outWordCounter++;
		respOutput.write(tempOutput);
	}
	else if (br_outWordCounter == 3) {	// 3rd packet header word
		if (errorCode == 1)				// error Packet, go to error state
			br_outWordCounter = 7;
		else  if (outOpCode == 1 || outOpCode ==  4 || outOpCode == 8) {	// Set operation
			br_outWordCounter = 0;
			tempOutput.last = 1;
		}
		else if (outOpCode == 0) // Get operation, output value
			br_outWordCounter++;
		respOutput.write(tempOutput);
	}
	else if (br_outWordCounter == 4) { 	// Xtras & Value
		if (!valueBuffer.empty()) {
			tempOutput.data.range(31, 0) = xtrasBuffer(31, 0);
			valueBuffer.read(xtrasBuffer);
			tempOutput.data.range(63, 32) = xtrasBuffer(31, 0);
			if (valueLength <= 4) {
				br_outWordCounter = 0;
				tempOutput.last = 1;
				tempOutput.keep = length2keep_mapping(valueLength + 4);
				}
			else {
				br_outWordCounter++;
				valueLength -= 4;
			}
			respOutput.write(tempOutput);
		}
	}
	else if (br_outWordCounter == 5) {
		if (valueLength > 4 && !valueBuffer.empty()) {
			//if (valueLength <=8)
			//	tempOutput.keep = length2keep_mapping(valueLength);
			tempOutput.data.range(31, 0) = xtrasBuffer(63, 32);
			valueBuffer.read(xtrasBuffer);
			tempOutput.data.range(63, 32) = xtrasBuffer(31, 0);
			//std::cerr << std::hex << tempOutput.data << std::endl;
			ap_uint<8> tempKeep = length2keep_mapping(valueLength);
			valueLength > 8 ? valueLength -=8 : valueLength = 0;
			if (valueLength == 0) {
				tempOutput.last = 1;
				br_outWordCounter = 0;
				tempOutput.keep = tempKeep;
			}
			else if (valueLength <= 4)
				br_outWordCounter++;
			respOutput.write(tempOutput);
		}
		else if (valueLength <= 4) {
			tempOutput.data.range((valueLength*8)-1, 0) = xtrasBuffer((valueLength*8)+31, 32);
			tempOutput.keep = length2keep_mapping(valueLength);
			valueLength = 0;
			tempOutput.last = 1;
			br_outWordCounter = 0;
			respOutput.write(tempOutput);
		}
	}
	else if (br_outWordCounter == 6) {
		tempOutput.data.range(31, 0) = xtrasBuffer(63, 32);
		tempOutput.keep = length2keep_mapping(valueLength);
		valueLength = 0;
		tempOutput.last = 1;
		br_outWordCounter = 0;
		respOutput.write(tempOutput);
	}
	else if (br_outWordCounter == 7) {
		br_outWordCounter = 0;
		tempOutput.last = 1;
		tempOutput.data.range(63, 0)	= 0x313020524F525245;
		respOutput.write(tempOutput);
	}
}

void binaryResponse(stream<pipelineWord> &inData_rf, stream<extendedAxiWord> &outData_rf) {
	#pragma HLS DATA_PACK variable=inData_rf
	//#pragma HLS DATA_PACK variable=outData_rf

	#pragma HLS INLINE

	static stream<ap_uint<248> >	metadataBuffer_rf("metadataBuffer_rf");		// Internal queue to store the metadata words
	static stream<ap_uint<64> >		valueBuffer_rf("valueBuffer_rf");			// Internal queue to store the value words

	#pragma HLS STREAM variable=metadataBuffer_rf 	depth=8
	#pragma HLS STREAM variable=valueBuffer_rf 		depth=1024

	response_f(inData_rf, metadataBuffer_rf, valueBuffer_rf);
	response_r(metadataBuffer_rf, valueBuffer_rf, outData_rf);
}
