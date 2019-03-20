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

void bp_f(stream<extendedAxiWord> &feInput, stream<ap_uint<248> > &metadataBuffer, stream<ap_uint<64> > &keyBuffer, stream<ap_uint<64> > &valueBuffer) { //  Binary parser front-end. Receives data, shuffles them and places them into the 3 internal buffer (key, value, metadata).

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static uint8_t				bpf_wordCounter 		= 0; 			//	Counts the words in the current packet
	static uint8_t				valueShift				= 0;			// 	Indicates how much the value has been shifted
	static uint8_t				notValueShift			= 0; 			//  8 - valueShift
	static ap_uint<8>			bpf_keyLength 			= 0;
	static ap_uint<8>			bpf_opCode 				= 0;
	static ap_uint<4>			protocol 				= 0;
	static ap_uint<32>			bpf_valueLength 		= 0;
	static ap_uint<64>  		valueTempBuffer 		= 0;
	static ap_uint<108>  		mdTempBuffer	 		= 0;
	static uint8_t				keyLengthBuffer 		= 0;
	static ap_uint<17>			bpf_valueLengthBuffer 	= 0;
	static bool					lastValueWord			= false;
	static bool 				keyComplete 			= false; // Designates that the key has been streamed through and stored in the buffer

	static	ap_uint<248>		metadataTempBuffer	= 0;	// This value store the metadata coming from the UDP until they can be written into the metadatabuffer.

	extendedAxiWord						tempInput = {0, 0, 0, 0};

	if (lastValueWord == false)	{
		if (!feInput.empty()) {
			feInput.read(tempInput);

			if (bpf_wordCounter == 0) {
				mdTempBuffer 						= tempInput.user.range(107, 0);
				metadataTempBuffer.range(247, 124) 	= mdTempBuffer; 					// Store metadata in the appropriate location in the metadata buffer word
				bpf_keyLength 						= tempInput.data.range(31, 24);
				keyLengthBuffer 					= bpf_keyLength;
				bpf_opCode 							= tempInput.data.range(15, 8);
				protocol  							= tempInput.data.range(3, 0);
				bpf_wordCounter++;
			}
			else if (bpf_wordCounter > 0) {
				if (bpf_wordCounter == 1) {
					bpf_valueLength 					= byteSwap32(tempInput.data.range(31, 0));
					bpf_valueLengthBuffer 				= bpf_valueLength - keyLengthBuffer;
					//metadataTempBuffer.range(279, 248) 	= tempInput.data.range(63, 32);
					metadataTempBuffer.range(123, 120) 	= protocol;
					metadataTempBuffer.range(111, 104) 	= bpf_opCode;
					metadataTempBuffer.range(85, 56) 	= tempInput.data.range(31,0);
					metadataTempBuffer.range(24, 8) 	= bpf_valueLengthBuffer;
					metadataTempBuffer.range(7, 0) 		= bpf_keyLength;
					metadataBuffer.write(metadataTempBuffer);
					bpf_wordCounter++;
				}
				else if (bpf_wordCounter == 2) {
					if (bpf_opCode == 1)
						bpf_wordCounter++;
					else if (bpf_opCode == 0 || bpf_opCode == 4) {
						if (keyLengthBuffer >=  8)
							bpf_wordCounter = 4;
						else if (keyLengthBuffer < 8)
							bpf_wordCounter = 5;
					}
					else if (bpf_opCode == 8) {
						bpf_wordCounter = 0 ;
					}
				}
				else if (bpf_wordCounter == 3) { // Extras word, store as value, for a set, first key word for a get
					valueBuffer.write(tempInput.data.range(31,0));
					bpf_valueLengthBuffer -= 8;
					if (keyLengthBuffer >=  8)
						bpf_wordCounter = 4;
					else if (keyLengthBuffer < 8)
						bpf_wordCounter = 5;
				}
				else if (bpf_wordCounter == 4) {	// Start storing key, value  as required
					if (keyLengthBuffer == 8) {		// Determine next state. If key is data word aligned than go to value output directly
						if (bpf_opCode == 0 || bpf_opCode == 4)	{
							bpf_wordCounter = 0;
						}
						else
							bpf_wordCounter = 6;
						valueShift = 0;
					}
					else if (keyLengthBuffer < 8) {
						bpf_wordCounter = 0;
					}
					else if (keyLengthBuffer <= 15)	{	// Else if this is the previous to last word of a non-aligned data word then move to state 5 where the realignment takes place.
						if (bpf_opCode == 0 || bpf_opCode == 4)
							bpf_wordCounter = 4;
						else
							bpf_wordCounter = 5;
					}
					keyBuffer.write(tempInput.data);
					keyLengthBuffer -= 8;
				}
				else if (bpf_wordCounter == 5) {
					keyBuffer.write(tempInput.data);
					if (bpf_opCode == 1) {
						valueShift = (8 - keyLengthBuffer) * 8;		// Number of bits to shift value data
						bpf_valueLengthBuffer = (bpf_valueLengthBuffer > (8 - keyLengthBuffer) ? bpf_valueLengthBuffer -= (8 - keyLengthBuffer) : bpf_valueLengthBuffer = 0);
						if (bpf_valueLengthBuffer > 0) {
							valueTempBuffer.range(valueShift-1, 0) = tempInput.data.range(63, 64-valueShift);
							keyLengthBuffer = 0;
							bpf_wordCounter = 6;
						}
						else {
							valueTempBuffer.range(63-(keyLengthBuffer*8), 0) = tempInput.data.range(63, keyLengthBuffer*8);
							valueBuffer.write(valueTempBuffer);
							//tempInput.EOP 		= 1;
							keyLengthBuffer 	= 0;
							bpf_wordCounter 	= 0;
						}
					}
					else if (bpf_opCode == 0 || bpf_opCode == 4) {
						keyLengthBuffer = 0;
						bpf_wordCounter = 0;
					}
				}
				else if (bpf_wordCounter == 6) {
					if (bpf_valueLengthBuffer <= (8-(valueShift/8))) {	//Value Remainder fits into this data word word and no spill over exists
						valueTempBuffer.range(63, valueShift) = tempInput.data.range(63-valueShift, 0);
						valueBuffer.write(valueTempBuffer);
						bpf_wordCounter 		= 0;
						bpf_valueLengthBuffer	= 0;
						keyComplete 			= false;
					}
					else { 	// Otherwise output data normally
						valueTempBuffer.range(63, valueShift) = tempInput.data.range(63-valueShift, 0);
						valueBuffer.write(valueTempBuffer);
						if (valueShift != 0) {
							unsigned short int valueTemp = bpf_valueLengthBuffer - keyLengthBuffer;
							valueTempBuffer.range(valueShift - 1, 0) = tempInput.data.range(63, 64-valueShift);
							if (valueTemp <= 8 && valueTemp > 0) {
								lastValueWord 	= true;
							}
						}
						bpf_valueLengthBuffer > 8 ? bpf_valueLengthBuffer -= 8 : bpf_valueLengthBuffer = 0;
					}
				}
			}
		}
	}
	else if (lastValueWord == true) {
		valueBuffer.write(valueTempBuffer);
		lastValueWord = false;
		keyComplete 	= false;
		bpf_wordCounter 	= 0;
	}
}

void bp_r(stream<ap_uint<248> > &metadataBuffer, stream<ap_uint<64> > &keyBuffer, stream<ap_uint<64> > &valueBuffer, stream<pipelineWord> &feOutput) { // Back-end of the binary parser. Reads data from the 3 buffers and outputs them in the correct internal pipeline format.
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	// This part takes care of the writing into the memcached pipeline.
	ap_uint<64>					outKeyBuffer		= 0;			// Temp variable to store key FIFO output before writing it out
	ap_uint<64>					outValueBuffer		= 0;			// Temp variable to store value FIFO output before writing it out
	static ap_uint<248>			outMetadataBuffer	= 0;			// Temp variable to store metadata FIFO output before writing it out
	static uint8_t				bpr_keyLength		= 0;
	static uint16_t				bpr_valueLength		= 0;
	static uint8_t				bpr_opCode			= 0;
	static ap_uint<2>			bpr_wordCounter		= 0;
	static enum bprState		{BPR_IDLE = 0, BPR_W1, BPR_REST} binaryParserRearState;

	pipelineWord				tempOutput			= {0, 0, 0, 0, 0, 0, 0};

	switch(binaryParserRearState) {
	case BPR_IDLE:
		if (!metadataBuffer.empty()) {
			metadataBuffer.read(outMetadataBuffer);
			bpr_opCode			= outMetadataBuffer.range(111, 104);
			binaryParserRearState = BPR_W1;
		}
		break;
	case BPR_W1:
		if (bpr_opCode == 8 || ((bpr_opCode != 8 && !keyBuffer.empty()) && (bpr_opCode != 1 || (bpr_opCode == 1 && !valueBuffer.empty())))) {
			bpr_keyLength		= outMetadataBuffer.range(7,0);
			if (bpr_opCode != 8) keyBuffer.read(outKeyBuffer);
			bpr_valueLength		= static_cast <unsigned short int>(outMetadataBuffer.range(23, 8));
			tempOutput.metadata = outMetadataBuffer.range(123, 0);
			tempOutput.SOP		= 1;
			tempOutput.keyValid = 1;
			tempOutput.key		= outKeyBuffer;
			(bpr_keyLength <= 8) ? bpr_keyLength = 0 : bpr_keyLength -=8;
			if (bpr_opCode == 1) {
				valueBuffer.read(outValueBuffer);
				tempOutput.valueValid = 1;
				tempOutput.value = outValueBuffer;
				(bpr_valueLength > 8) ? bpr_valueLength -= 8 : bpr_valueLength = 0;
			}
			else {
				tempOutput.valueValid = 0;
				tempOutput.value = 0;
			}
			feOutput.write(tempOutput);
			binaryParserRearState = BPR_REST;
		}
		break;
	case BPR_REST:
		if ((!(bpr_keyLength > 0) || (bpr_keyLength > 0 && !keyBuffer.empty())) && (!(bpr_valueLength > 0) || (bpr_valueLength > 0 && !valueBuffer.empty()))) {
			if (bpr_keyLength > 0) {
				tempOutput.keyValid = 1;
				keyBuffer.read(outKeyBuffer);
				tempOutput.key	= outKeyBuffer;
				(bpr_keyLength > 8) ? bpr_keyLength -= 8 : bpr_keyLength = 0;
			}
			else tempOutput.keyValid = 0;
			if (bpr_valueLength > 0) {
				valueBuffer.read(outValueBuffer);
				tempOutput.valueValid = 1;
				tempOutput.value = outValueBuffer;
				(bpr_valueLength > 8) ? bpr_valueLength -= 8 : bpr_valueLength = 0;
			}
			else tempOutput.valueValid = 0;
			if (bpr_wordCounter == 0) {
				tempOutput.metadata = outMetadataBuffer.range(247, 124);
				bpr_wordCounter++;
			}
			else tempOutput.metadata = 0;
			if (bpr_keyLength == 0 && bpr_valueLength == 0 && bpr_wordCounter >= 1)	{
				tempOutput.EOP = 1;
				bpr_wordCounter = 0;
				binaryParserRearState = BPR_IDLE;
			}
			feOutput.write(tempOutput);
		}
		break;

	}
}

void binaryParser(stream<extendedAxiWord> &inData, stream<pipelineWord> &outData) { 			// Binary parser top-level function.
	//#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE

	static stream<ap_uint<248> >	metadataBuffer_rp("metadataBuffer_rp");			// Internal queue to store the metadata words
	static stream<ap_uint<64> >		keyBuffer_rp("keyBuffer_rp");					// Internal queue to store the key words
	static stream<ap_uint<64> >		valueBuffer_rp("valueBuffer_rp");				// Internal queue to store the value words

	#pragma HLS STREAM variable=metadataBuffer_rp 	depth=16
	#pragma HLS STREAM variable=keyBuffer_rp 		depth=128
	#pragma HLS STREAM variable=valueBuffer_rp 		depth=1024

	bp_f(inData, metadataBuffer_rp, keyBuffer_rp, valueBuffer_rp);
	bp_r(metadataBuffer_rp, keyBuffer_rp, valueBuffer_rp, outData);
}
