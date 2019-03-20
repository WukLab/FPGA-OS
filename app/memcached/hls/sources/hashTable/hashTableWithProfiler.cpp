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
#include "../memcachedDssPipeline.h"

void ht_inputLogic(stream<pipelineWord> &inData, stream<ap_uint<64> > &in2key, stream<ap_uint<64> > &in2value, stream<ap_uint<128> > &in2md, stream<hashTableInternalWord> &in2hash, stream<ap_uint<8> > &in2hashKeyLength, stream<hashTableInternalWord> &in2cc, stream<internalMdWord> &in2ccMd) { // This modules reads an input data word, writes key, value and metadata into buffers, sends the key to the hash function int 64-bit words and aggregates the key into stripes for processing in the hash pipeline

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	pipelineWord 					inputWord		= {0, 0, 0, 0, 0, 0, 0};	// Input data word read from the parser modules
	static 	hashTableInternalWord 	bufferWord 		= {0, 0, 0};				// Internal word which is sent down the hash pipeline
	static	internalMdWord			bufferWordMd	= {0, 0, 0};
	static	enum					ilState {IL_IDLE = 0, IL_STREAM} iState;	// Maintains the state of the module
	static	ap_uint<2>				wordCounter		= 0;
	static	ap_uint<2>				keyWordCounter		= 0;
	static 	ap_uint<3>				aggregatedKeyLength	= 0;					// Length of the key when aggregated into 192-bit data words
	static	ap_uint<8>				keyLength 			= 0;					// Holds the key length. Used to count down as the key words come in.
	ap_uint<128> 					metadataBuffer 		= 0;					// Agreggates all the metadata info (keyValid, EOP, etc in one bit vector and stores it. This is possible since the hash table NEVER changes the length of a packet.

	switch(iState) {
		case IL_IDLE:
		{
			if (!inData.empty()) {
				inData.read(inputWord);
				bufferWordMd.keyLength 	= 0;
				wordCounter				= 0;
				aggregatedKeyLength		= 0;
				if (inputWord.SOP == 1)	{
					bufferWord.SOP 				= 1;
					bufferWordMd.operation 		= inputWord.metadata.range(111, 104);
					bufferWordMd.valueLength 	= inputWord.metadata.range(39, 8);
					if (inputWord.metadata.range(111, 104) == 8) {
						bufferWordMd.keyLength 		= 1;
						keyLength					= 1;
					}
					else {
						bufferWordMd.keyLength 		= inputWord.metadata.range(7, 0);
						keyLength 					= inputWord.metadata.range(7, 0);
					}
					keyWordCounter 	= 1;
					if (bufferWordMd.keyLength > 0) {
						if (bufferWordMd.operation != 8)
							in2key.write(inputWord.key);
						bufferWord.SOP = 1;
						in2hashKeyLength.write(keyLength);
						if (keyLength <= 8) {
							bufferWord.data.range((keyLength*8)-1, 0) = inputWord.key.range((keyLength*8)-1, 0);
							bufferWord.EOP = 1;
							in2cc.write(bufferWord);
							in2ccMd.write(bufferWordMd);
							in2hash.write(bufferWord);
							keyLength = 0;
						}
						else {
							bufferWord.data.range(63, 0) = inputWord.key;
							keyLength -= 8;
						}
					}
					if (inputWord.valueValid == 1)
						in2value.write(inputWord.value);
					metadataBuffer.bit(127) 		= inputWord.EOP;
					metadataBuffer.bit(126) 		= inputWord.valueValid;
					metadataBuffer.bit(125)	 		= inputWord.keyValid;
					metadataBuffer.bit(124) 		= inputWord.SOP;
					metadataBuffer.range(123, 0) 	= inputWord.metadata;
					in2md.write(metadataBuffer);
					wordCounter++;
					iState = IL_STREAM;
				}
				else
					keyWordCounter			= 0;
			}
			break;
		}
		case IL_STREAM:
		{

			if (!inData.empty()) {
				inData.read(inputWord);
				if (inputWord.valueValid == 1)
					in2value.write(inputWord.value);
				if (wordCounter < 3) {
					metadataBuffer.bit(127) 		= inputWord.EOP;
					metadataBuffer.bit(126) 		= inputWord.valueValid;
					metadataBuffer.bit(125)	 		= inputWord.keyValid;
					metadataBuffer.bit(124) 		= inputWord.SOP;
					metadataBuffer.range(123, 0) 	= inputWord.metadata;
					in2md.write(metadataBuffer);
					wordCounter++;
				}
				if (keyLength > 0) {
					bufferWord.SOP = 0;
					in2key.write(inputWord.key);
					if (keyLength <= 8) {
						bufferWord.data.range(((64*keyWordCounter)+(keyLength*8))-1, (64*keyWordCounter)) = inputWord.key;
						keyLength = 0;
						bufferWord.EOP = 1;
						in2cc.write(bufferWord);
						in2ccMd.write(bufferWordMd);
						in2hash.write(bufferWord);
					}
					else {
						bufferWord.data.range((64*(keyWordCounter+1))-1, (64*keyWordCounter)) = inputWord.key;
						if (keyWordCounter == 1) {
							bufferWord.EOP = 0;
							in2cc.write(bufferWord);
							in2hash.write(bufferWord);

							keyWordCounter = 0;
						}
						else
							keyWordCounter++;
						keyLength -= 8;
					}
				}
				if (inputWord.EOP == 1)
					iState = IL_IDLE;
			}
			break;
		}
	}
}

void ht_outputLogic(stream<decideResultWord> &memWr2out, stream<ap_uint<64> > &key2out, stream<ap_uint<64> > &value2out, stream<ap_uint<128> > &md2out, stream<pipelineWord> &outData) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum	oState	{OL_IDLE = 0, OL_W1, OL_MD1, OL_MD2, OL_REST} olState;
	static decideResultWord 	ol_addressWord	= {0, 0, 0, 0};
	ap_uint<64>					keyWord			= 0;
	ap_uint<64>					valueWord		= 0;
	static ap_uint<128>			ol_metadataWord	= 0;
	pipelineWord				outputWord		= {0, 0, 0, 0, 0, 0, 0};
	static ap_uint<3>			ol_WordCounter	= 0;
	static ap_uint<8>			ol_keyLength	= 0;
	static ap_uint<16>			ol_valueLength	= 0;

	switch (olState) {
		case OL_IDLE:
		{
			if (!memWr2out.empty() && !md2out.empty()) {
				memWr2out.read(ol_addressWord);
				md2out.read(ol_metadataWord);
				ol_keyLength = ol_metadataWord.range(7, 0);
				olState	= OL_W1;
			}
			break;
		}
		case OL_W1:
		{
			if ((!(ol_keyLength > 0) || (ol_keyLength > 0 && !key2out.empty())) && (!(ol_addressWord.operation == 1) || (ol_addressWord.operation == 1 && !value2out.empty()))) {
				outputWord.SOP 						= ol_metadataWord.bit(124);
				outputWord.keyValid 				= ol_metadataWord.bit(125);
				outputWord.valueValid 				= ol_metadataWord.bit(126);
				outputWord.EOP 						= ol_metadataWord.bit(127);
				outputWord.metadata.range(103, 72) 	= ol_addressWord.address.range(31, 0);
				outputWord.metadata.range(123, 104) = ol_metadataWord.range(123, 104);
				outputWord.metadata.bit(112) 		= ol_addressWord.status;

				if (ol_addressWord.operation != 1)
					ol_metadataWord.range(23, 8) = ol_addressWord.valueLength;
				else {
					ol_valueLength = ol_metadataWord.range(23, 8);
					value2out.read(valueWord);
					outputWord.value = valueWord;
					ol_valueLength > 8 ? ol_valueLength -= 8 : ol_valueLength = 0;
				}
				if (ol_keyLength > 0) {
					key2out.read(keyWord);
					outputWord.key = keyWord;
					ol_keyLength > 8 ? ol_keyLength -= 8 : ol_keyLength = 0;
				}
				outputWord.metadata.range(71, 0) 	= ol_metadataWord.range(71, 0);
				outData.write(outputWord);
				olState = OL_MD1;
			}
			break;
		}
		case OL_MD1:
		{
			if (!md2out.empty() && (!(ol_keyLength > 0) || (ol_keyLength > 0 && !key2out.empty())) && (!(ol_valueLength > 0) || (ol_valueLength > 0 && !value2out.empty()))) {
				md2out.read(ol_metadataWord);
				outputWord.metadata = ol_metadataWord.range(123, 0);
				if (ol_keyLength > 0) {
					key2out.read(keyWord);
					outputWord.key = keyWord;
					outputWord.keyValid = 1;
					ol_keyLength > 8 ? ol_keyLength -= 8 : ol_keyLength = 0;
				}
				if (ol_valueLength > 0)	{
					value2out.read(valueWord);
					outputWord.value = valueWord;
					outputWord.valueValid = 1;
					ol_valueLength > 8 ? ol_valueLength -= 8 : ol_valueLength = 0;
				}
				outData.write(outputWord);
				olState = OL_MD2;
			}
			break;
		}
		case OL_MD2:
		{
			if (!md2out.empty() && (!(ol_keyLength > 0) || (ol_keyLength > 0 && !key2out.empty())) && (!(ol_valueLength > 0) || (ol_valueLength > 0 && !value2out.empty()))) {
				md2out.read(ol_metadataWord);
				outputWord.metadata = ol_metadataWord.range(123, 0);
				if (ol_keyLength > 0) {
					key2out.read(keyWord);
					outputWord.key = keyWord;
					outputWord.keyValid = 1;
					ol_keyLength > 8 ? ol_keyLength -= 8 : ol_keyLength = 0;
				}
				if (ol_valueLength > 0)	{
					value2out.read(valueWord);
					outputWord.value = valueWord;
					outputWord.valueValid = 1;
					ol_valueLength > 8 ? ol_valueLength -= 8 : ol_valueLength = 0;
				}
				if (ol_valueLength == 0 && ol_keyLength == 0) {
					outputWord.EOP = 1;
					olState = OL_IDLE;
				}
				else
					olState = OL_REST;
				outData.write(outputWord);
			}
			break;
		}
		case OL_REST:
		{
			if ((!(ol_keyLength > 0) || (ol_keyLength > 0 && !key2out.empty())) && (!(ol_valueLength > 0) || (ol_valueLength > 0 && !value2out.empty()))) {
				if (ol_keyLength > 0) {
					key2out.read(keyWord);
					outputWord.key 		= keyWord;
					outputWord.keyValid = 1;
					ol_keyLength > 8 ? ol_keyLength -= 8 : ol_keyLength = 0;
				}
				if (ol_valueLength > 0) {
					value2out.read(valueWord);
					outputWord.value 		= valueWord;
					outputWord.valueValid 	= 1;
					ol_valueLength > 8 ? ol_valueLength -= 8 : ol_valueLength = 0;
				}
				if (ol_valueLength == 0 && ol_keyLength == 0) {
					outputWord.EOP = 1;
					olState = OL_IDLE;
				}
				outData.write(outputWord);
			}
			break;
		}
	}
}

void hashTable(stream<pipelineWord> &ht_inData, stream<pipelineWord> &ht_outData,
			   stream<ap_uint<512> > &memRdData, stream<memCtrlWord> &memRdCtrl, stream<ap_uint<512> > &memWrData, stream<memCtrlWord> &memWrCtrl,
			   stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, 
			   ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone) {

	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INLINE

	static stream<ap_uint<64> >				hashKeyBuffer("hashKeyBuffer");
	static stream<ap_uint<64> >				hashValueBuffer("hashValueBuffer");
	static stream<ap_uint<128> >			hashMdBuffer("hashMdBuffer");

	static stream<hashTableInternalWord>	in2cc("in2cc");
	static stream<internalMdWord>			in2ccMd("in2ccMd");
	static stream<hashTableInternalWord>	in2hash("in2hash");
	static stream<ap_uint<8> >				in2hashKeyLength("in2hashKeyLength");

	static stream<ap_uint<32> >				hash2cc("hash2cc");
	static stream<hashTableInternalWord>	cc2memRead("cc2memRead");
	static stream<internalMdWord>			cc2memReadMd("cc2memReadMd");
	static stream<hashTableInternalWord>	memRd2comp("memRd2comp");
	static stream<internalMdWord>			memRd2compMd("memRd2compMd");
	static stream<decideResultWord>			memWr2out("memWr2out");
	static stream<hashTableInternalWord>	comp2memWrKey("comp2memWrKey");
	static stream<internalMdWord>			comp2memWrMd("comp2memWrMd");
	static stream<comp2decWord>				comp2memWrStatus("comp2memWrStatus");
	static stream<ap_uint<512> > 			comp2memWrMemData("comp2memWrMemData");
	static stream<ap_uint<1> > 				dec2cc("dec2cc");

	#pragma HLS DATA_PACK variable=in2hash
	#pragma HLS DATA_PACK variable=in2cc
	#pragma HLS DATA_PACK variable=in2ccMd
	#pragma HLS DATA_PACK variable=cc2memRead
	#pragma HLS DATA_PACK variable=cc2memReadMd
	#pragma HLS DATA_PACK variable=memRd2comp
	#pragma HLS DATA_PACK variable=memRd2compMd
	#pragma HLS DATA_PACK variable=memWr2out
	#pragma HLS DATA_PACK variable=comp2memWrKey
	#pragma HLS DATA_PACK variable=comp2memWrMd
	#pragma HLS DATA_PACK variable=comp2memWrStatus
	//Here the I/Fs to the memory and the PCIe are missing. I/Fs to be discussed (does it make sense to use the ones in the maxbox go straight for the VC709. If so, what are the differences?)

	#pragma HLS STREAM variable=hashKeyBuffer 		depth=128
	#pragma HLS STREAM variable=hashValueBuffer		depth=1024
	#pragma HLS STREAM variable=hashMdBuffer 		depth=32
	#pragma HLS STREAM variable=in2cc				depth=10
	#pragma HLS STREAM variable=in2ccMd 			depth=10
	#pragma HLS STREAM variable=cc2memRead			depth=10
	#pragma HLS STREAM variable=cc2memReadMd 		depth=10
	#pragma HLS STREAM variable=memRd2comp			depth=10
	#pragma HLS STREAM variable=memRd2compMd 		depth=10
	#pragma HLS STREAM variable=comp2memWrMd		depth=10
	#pragma HLS STREAM variable=comp2memWrKey 		depth=10
	#pragma HLS STREAM variable=comp2memWrMemData	depth=10

	ht_inputLogic(ht_inData, hashKeyBuffer, hashValueBuffer, hashMdBuffer, in2hash, in2hashKeyLength, in2cc, in2ccMd);
	hash(in2hash, in2hashKeyLength, hash2cc);
	concurrencyControl(in2cc, in2ccMd, hash2cc, cc2memRead, cc2memReadMd, dec2cc);
	memRead(cc2memRead, cc2memReadMd, memRdCtrl, memRd2comp, memRd2compMd);
	ht_compare(memRd2comp, memRd2compMd, memRdData, comp2memWrKey, comp2memWrMd, comp2memWrStatus, comp2memWrMemData);
	memWriteWithProfiler(comp2memWrKey,comp2memWrMd,comp2memWrStatus, comp2memWrMemData, memWrCtrl, memWrData, memWr2out, dec2cc, addressReturnOut, addressAssignDramIn, addressAssignFlashIn, flushReq, flushAck, flushDone);
	ht_outputLogic(memWr2out, hashKeyBuffer, hashValueBuffer, hashMdBuffer, ht_outData);
}
