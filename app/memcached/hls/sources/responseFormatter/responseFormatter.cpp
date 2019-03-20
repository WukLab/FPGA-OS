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

void responseInputSelection(stream<pipelineWord> &inData, stream<pipelineWord> &sel2bin, stream<pipelineWord> &sel2ascii, stream<ap_uint<2> > &packetSeqBuffer) {

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1

	static bool 		is_validFlag 	= false;
	static ap_uint<1>	binOrASCII 		= 0;	// 1 = ASCII, 0 = bin

	if (!inData.empty()) {
		pipelineWord inputWord;
		inData.read(inputWord);
		if (inputWord.SOP == 1) {
			is_validFlag = true;
			binOrASCII = inputWord.metadata.bit(120);
			packetSeqBuffer.write(binOrASCII);
		}
		if (is_validFlag) {
			if (binOrASCII == 0)
				sel2bin.write(inputWord);
			else if (binOrASCII == 1)
				sel2ascii.write(inputWord);
			if (inputWord.EOP == 1)	{
				is_validFlag = false;
			}
		}
	}
}



void responseOutputSelection(stream<ioWord> &bin2sel, stream<ioWord> &ascii2sel, stream<ap_uint<2> > &packetSeqBuffer, stream<ioWord> &outData) {

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1

	static ap_uint<2> 	parserOutputLogicState 	= 0;
	static ap_uint<2> 	seqBuffer 				= 0;
	static bool 		outputValidFlag 		= false;

	if (parserOutputLogicState == 0) {
		if (!packetSeqBuffer.empty()) {
			packetSeqBuffer.read(seqBuffer);
			parserOutputLogicState++;
		}
	}
	else if (parserOutputLogicState == 1) {
		ioWord outputWord;
		if (seqBuffer == 0 && !bin2sel.empty())	{
			bin2sel.read(outputWord);
			if (outputWord.SOP == 1)
				outputValidFlag = true;
			if (outputValidFlag == true) {
				outData.write(outputWord);
				if (outputWord.EOP == 1) {
					outputValidFlag = false;
					parserOutputLogicState = 0;
				}
			}
		}
		else if (seqBuffer == 1 && !ascii2sel.empty()) {
			ascii2sel.read(outputWord);
			if (outputWord.SOP == 1)
				outputValidFlag = true;
			if (outputValidFlag == true) {
				outData.write(outputWord);
				if (outputWord.EOP == 1) {
					outputValidFlag = false;
					parserOutputLogicState = 0;
				}
			}
		}
	}
}

void responseFormatter(stream<pipelineWord> &responseFormatterInData, stream<ioWord> &responseFormatterOutData) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE

	static stream<pipelineWord>			rf_sel2bin("rf_sel2bin");					// Internal queue from the selection module to the binary conversion module
	static stream<pipelineWord>			rf_sel2ascii("rf_sel2ascii");				// Internal queue from the selection module to the ASCII conversion module
	static stream<ioWord>				rf_bin2sel("rf_bin2sel");					// Internal queue from the binary conversion module to the selection module
	static stream<ioWord>				rf_ascii2sel("rf_ascii2sel");				// Internal queue from the ASCII conversion module to the selection module
	static stream<ap_uint<2> >			rf_packetSeqBuffer("rf_packetSeqBuffer");

	#pragma HLS DATA_PACK variable=rf_sel2bin
	#pragma HLS DATA_PACK variable=rf_sel2ascii
	#pragma HLS DATA_PACK variable=rf_bin2sel
	#pragma HLS DATA_PACK variable=rf_ascii2sel

	#pragma HLS STREAM variable=rf_sel2bin 			depth=4
	#pragma HLS STREAM variable=rf_sel2ascii 		depth=4
	#pragma HLS STREAM variable=rf_bin2sel 			depth=4
	#pragma HLS STREAM variable=rf_ascii2sel 		depth=4
	#pragma HLS STREAM variable=rf_packetSeqBuffer 	depth=64

	responseInputSelection(responseFormatterInData, rf_sel2bin, rf_sel2ascii, rf_packetSeqBuffer);
	binaryResponse(rf_sel2bin, rf_bin2sel);
	asciiResponse(rf_sel2ascii, rf_ascii2sel);
	responseOutputSelection(rf_bin2sel, rf_ascii2sel, rf_packetSeqBuffer, responseFormatterOutData);
	//std::cout << "RF Clear!" << std::endl;
}
