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

void ht_compare(stream<hashTableInternalWord> &memRd2comp, stream<internalMdWord> &memRd2compMd, stream<ap_uint<512> > &memRdData, stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd, stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum  						cState {CMP_IDLE = 0, CMP_HEAD, CMP_COMPARE, CMP_STREAM} cmpState;
	static uint8_t 						cmp_keyLength 	= 	0;
	static hashTableInternalWord		cmp_inData		= 	{0, 0, 0};
	static internalMdWord				cmp_inDataMd	=	{0, 0, 0, 0 };
	static comp2decWord					statusOutput 	= 	{0, 0};
	static bool							cmpResult		=	true;
	ap_uint<512> 						memInput		= 	0;

	switch(cmpState) {
		case CMP_IDLE:
			if (!memRd2compMd.empty()) {
				memRd2compMd.read(cmp_inDataMd);
				cmp_keyLength = cmp_inDataMd.keyLength;
				if (cmp_inDataMd.operation == 8)
					cmpState = CMP_STREAM;
				else
					cmpState = CMP_HEAD;	
				for (uint8_t i=0;i<noOfBins;++i) {
					statusOutput.bin[i].free = 0;
					statusOutput.bin[i].match = 0;
				}
			}
			break;
		case CMP_HEAD:
			if (!memRdData.empty()) {
				memRdData.read(memInput); 										// The first word from the memory just contains the metadata, so there is no need to compare anything.
				for (uint8_t i=0;i<noOfBins;++i) {								// Go through all the bins of the first key data word (contains the key metadata)
					if (memInput.range((bitsPerBin*i)+7, (bitsPerBin*i)) == 0)	// And check the key length. If its 0, then the bin is empty
						statusOutput.bin[i].free = 1;							// mark it as such
					else if (memInput.range((bitsPerBin*i)+7, (bitsPerBin*i)) == cmp_keyLength)
						statusOutput.bin[i].match = 1;							// mark it as
				}
				comp2memWrMemData.write(memInput);								// and stream the word on
				cmpState = CMP_COMPARE;
			}
			break;
		case CMP_COMPARE:
			if (!memRdData.empty() && !memRd2comp.empty()) {
				memRdData.read(memInput);
				memRd2comp.read(cmp_inData);
				for (uint8_t i=0;i<noOfBins;++i) {																	// Again go through all the bins
					if (memInput.range((bitsPerBin*(i+1))-1, (bitsPerBin*i)) != cmp_inData.data)					// If this part of the key does not match the input data
						statusOutput.bin[i].match = 0;																// set the flag to 0
				}																									// Read the next word from the memory. This is going to be the first data word with key data
				comp2memWrMemData.write(memInput);																	// Stream the memory data word down the pipeline
				comp2memWrKey.write(cmp_inData);																	// Stream the input key on
				cmp_keyLength > (8*words2aggregate) ? cmp_keyLength -= (8*words2aggregate) : cmp_keyLength = 0;		// Adjust the key length
				if (cmp_keyLength == 0)	{																			// Check if the key comparison is complete. If so,
					comp2memWrMd.write(cmp_inDataMd);																// write the metadata to the next state
					comp2memWrKeyStatus.write(statusOutput);														// write the status flags to the next stage
					cmpState = CMP_IDLE;																			// and move back to idle
				}																									// if there is more to compare, read the next input key word and stay in this state
			}
			break;
		case CMP_STREAM:
			if (!memRd2comp.empty()) {
				comp2memWrKey.write(memRd2comp.read());
				cmp_keyLength > (8*words2aggregate) ? cmp_keyLength -= (8*words2aggregate) : cmp_keyLength = 0;		// Adjust the key length
				if (cmp_keyLength == 0)	{																			// Check if the key comparison is complete. If so,
					comp2memWrMd.write(cmp_inDataMd);																// write the metadata to the next state
					comp2memWrKeyStatus.write(statusOutput);														// write the status flags to the next stage
					cmpState = CMP_IDLE;																			// and move back to idle
				}
			}
			break;
	}
}
