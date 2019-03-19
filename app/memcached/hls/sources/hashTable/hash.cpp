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

void bobj(stream<ap_uint<96> > &key, stream<uint32_t> &lengthStream, stream<uint32_t> &initvalStream, stream<ap_uint<32> > &hashOut)
{

	#pragma HLS LATENCY min=1 max=10
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush
	#pragma HLS INTERFACE ap_ctrl_none port=return

	static enum hS {HASH_IDLE = 0, HASH_ACC_1, HASH_ACC_2, HASH_ACC_3, HASH_ACC_4, HASH_FINAL, HASH_FINAL_MIX_1, HASH_FINAL_MIX_2, HASH_FINAL_MIX_3, HASH_FINAL_MIX_4} hashState;
	static uint32_t a,b,c;
	static size_t 	length = 0;
	ap_uint<96> 	inputWord = 0;

	switch(hashState) {
		case HASH_IDLE: {
			if (!lengthStream.empty()&& !initvalStream.empty()) {
				length = lengthStream.read();
				uint32_t initval = initvalStream.read();
				a = b = c = 0xdeadbeef + ((uint32_t)length) + initval;	/* Set up the internal state */
				if (length > 12)
					hashState = HASH_ACC_1;
				else
					hashState = HASH_FINAL;
			}
			break;
		}
		case HASH_ACC_1: {
			if (!key.empty()) {
				key.read(inputWord);
				a += inputWord.range(31, 0);
				b += inputWord.range(63, 32);
				c += inputWord.range(95, 64);
				//mix(a,b,c);
				a -= c;  a ^= rot(c, 4);  c += b;
				hashState = HASH_ACC_2;
			}
			break;
		}
		case HASH_ACC_2: {
			b -= a;  b ^= rot(a, 6);  a += c;
			c -= b;  c ^= rot(b, 8);  b += a;
			hashState = HASH_ACC_3;
			break;
		}
		case HASH_ACC_3: {
			a -= c;  a ^= rot(c,16);  c += b;
			b -= a;  b ^= rot(a,19);  a += c;
			hashState = HASH_ACC_4;
			break;
		}
		case HASH_ACC_4: {
			c -= b;  c ^= rot(b, 4);  b += a;
			length -= 12;
			if (length > 12)
				hashState = HASH_ACC_1;
			else
				hashState = HASH_FINAL;
			break;
		}
		case HASH_FINAL: {
			uint32_t temp = 0;
			if (length == 0) {
				hashOut.write(c); /* zero length strings require no mixing */
				hashState = HASH_IDLE;
			}
			else {
				if (!key.empty()) {
					switch(length) {
						case 12: {
							key.read(inputWord);
							a += inputWord.range(31, 0); b += inputWord.range(63, 32); c += inputWord.range(95, 64); break;
						}
						case 11: {
							key.read(inputWord);
							a += inputWord.range(31, 0); b += inputWord.range(63, 32);
							temp = inputWord.range(95, 64); c += temp & 0xffffff; break;
						}
						case 10: {
							key.read(inputWord);
							a += inputWord.range(31, 0); b += inputWord.range(63, 32);
							temp = inputWord.range(95, 64); c += temp & 0xffff; break;
						}
						case 9 : {
							key.read(inputWord);
							a += inputWord.range(31, 0); b += inputWord.range(63, 32);
							temp = inputWord.range(95, 64); c += temp & 0xff; break;
						}
						case 8 : {
							key.read(inputWord);
							a += inputWord.range(31, 0); b += inputWord.range(63, 32); break;
						}
						case 7 : {
							key.read(inputWord);
							a += inputWord.range(31, 0);
							temp = inputWord(63, 32); b += temp & 0xffffff; break;
						}
						case 6 : {
							key.read(inputWord);
							a += inputWord.range(31, 0);
							temp = inputWord(63, 32); b += temp & 0xffff; break;
						}
						case 5 : {
							key.read(inputWord);
							a += inputWord.range(31, 0);
							temp = inputWord(63, 32); b += temp & 0xff; break;
						}
						case 4 : {
							key.read(inputWord);
							a += inputWord.range(31, 0); break;
						}
						case 3 : {
							key.read(inputWord);
							temp = inputWord.range(31, 0); a += temp & 0xffffff; break;
						}
						case 2 : {
							key.read(inputWord);
							temp = inputWord.range(31, 0); a += temp & 0xffff; break;
						}
						case 1 : {
							key.read(inputWord);
							temp = inputWord.range(31, 0); a += temp & 0xff; break;
						}
					}
					hashState = HASH_FINAL_MIX_1;
				}
			}
			break;
		}
		case HASH_FINAL_MIX_1: {
			c ^= b; c -= rot(b,14);
			a ^= c; a -= rot(c,11);

			/*b ^= a; b -= rot(a,25);
			c ^= b; c -= rot(b,16);
			a ^= c; a -= rot(c,4);
			b ^= a; b -= rot(a,14);
			c ^= b; c -= rot(b,24);
			hashOut.write(c);
			hashState = HASH_IDLE;*/
			hashState = HASH_FINAL_MIX_2;
			break;
		}
		case HASH_FINAL_MIX_2: {
			b ^= a; b -= rot(a,25);
			c ^= b; c -= rot(b,16);
			hashState = HASH_FINAL_MIX_3;
			break;
		}
		case HASH_FINAL_MIX_3: {
			a ^= c; a -= rot(c,4);
			b ^= a; b -= rot(a,14);
			hashState = HASH_FINAL_MIX_4;
			break;
		}
		case HASH_FINAL_MIX_4: {
			c ^= b; c -= rot(b,24);
			hashOut.write(c);
			hashState = HASH_IDLE;
			break;
		}
	}
}

void hashKeyResizer(stream<hashTableInternalWord> &in2hash, stream<ap_uint<8> > &in2hashKeyLength, stream<ap_uint<96> > &resizedKey, stream<uint32_t> &resizedKeyLength, stream<uint32_t> &resizedInitValue)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum ksState {KS_IDLE = 0, KS_STEP1, KS_STEP2, KS_STEP3, KS_STEP0, KS_RESIDUE, KS_RESIDUE1, KS_RESIDUE2} keyResizerState;
	static ap_uint<8> 				keyResizerLength 	= 0;
	static ap_uint<96> 				resizedKeyOutput	= 0;
	static hashTableInternalWord	tempInput 			= {0, 0 ,0};

	switch(keyResizerState)
	{
		case KS_IDLE:
		{
			if (!in2hashKeyLength.empty() && !in2hash.empty())
			{
				in2hashKeyLength.read(keyResizerLength);
				in2hash.read(tempInput);

				resizedKeyLength.write(static_cast <uint32_t>(keyResizerLength));
				resizedInitValue.write(hashFunctionSeed);
				resizedKeyOutput= tempInput.data.range(95, 0);
				resizedKey.write(resizedKeyOutput);

				if (keyResizerLength > 12) {			// If there is more key to output
					if (tempInput.EOP == 1)  			// Check if there more to read from the input
						keyResizerState = KS_RESIDUE;	// If not, output what has already been read
					else
						keyResizerState = KS_STEP1;
				}
			}
			break;
		}
		case KS_STEP1:
		{
			if (!in2hash.empty()) {
				keyResizerLength -= 16;
				resizedKeyOutput.range(31, 0) = tempInput.data.range(127, 96);
				in2hash.read(tempInput);
				resizedKeyOutput.range(95, 32) = tempInput.data.range(63, 0);
				resizedKey.write(resizedKeyOutput);
				if (keyResizerLength > 8) {				// If there is more key to output
					if (tempInput.EOP == 1)  			// Check if there more to read from the input
						keyResizerState = KS_RESIDUE1;	// If not, output what has already been read
					else
						keyResizerState = KS_STEP2;
				}
				else
					keyResizerState = KS_IDLE;
			}
			break;
		}
		case KS_STEP2:
		{
			if (!in2hash.empty()) {
				keyResizerLength -= 16;
				resizedKeyOutput.range(63, 0) = tempInput.data.range(127, 64);
				in2hash.read(tempInput);
				resizedKeyOutput.range(95, 64) = tempInput.data.range(31, 0);
				resizedKey.write(resizedKeyOutput);
				if (keyResizerLength > 4) {				// If there is more key to output
					if (tempInput.EOP == 1)  			// Check if there more to read from the input
						keyResizerState = KS_RESIDUE2;	// If not, output what has already been read
					else
						keyResizerState = KS_STEP3;
				}
				else
					keyResizerState = KS_IDLE;
			}
			break;
		}
		case KS_STEP3:
		{
			keyResizerLength -= 16;
			resizedKeyOutput = tempInput.data.range(127, 32);
			resizedKey.write(resizedKeyOutput);
			if (keyResizerLength > 0)
				keyResizerState = KS_STEP0;
			else
				keyResizerState = KS_IDLE;
			break;
		}
		case KS_STEP0:
		{
			if (!in2hash.empty()) {
				in2hash.read(tempInput);
				resizedKeyOutput= tempInput.data.range(95, 0);
				resizedKey.write(resizedKeyOutput);
				if (keyResizerLength > 12) {			// If there is more key to output
					if (tempInput.EOP == 1)  			// Check if there more to read from the input
						keyResizerState = KS_RESIDUE;	// If not, output what has already been read
					else
						keyResizerState = KS_STEP1;
				}
			}
			break;
		}
		case KS_RESIDUE:
		{
			resizedKeyOutput.range(31, 0) = tempInput.data.range(127, 96);
			resizedKey.write(resizedKeyOutput);
			keyResizerState = KS_IDLE;
			break;
		}
		case KS_RESIDUE1:
		{
			resizedKeyOutput.range(63, 0) = tempInput.data.range(127, 64);
			resizedKey.write(resizedKeyOutput);
			keyResizerState = KS_IDLE;
			break;
		}
		case KS_RESIDUE2:
		{
			resizedKeyOutput = tempInput.data.range(127, 32);
			resizedKey.write(resizedKeyOutput);
			keyResizerState = KS_IDLE;
			break;
		}
	}
}

void hash(stream<hashTableInternalWord> &in2hash, stream<ap_uint<8> > &in2hashKeyLength, stream<ap_uint<32> > &hash2cc) {
	#pragma HLS INLINE

	static stream<ap_uint<96> > resizedKey;
	static stream<uint32_t>		resizedKeyLength;
	static stream<uint32_t>		resizedInitValue;

	#pragma HLS STREAM variable=resizedKey		depth=8

	hashKeyResizer(in2hash, in2hashKeyLength, resizedKey, resizedKeyLength, resizedInitValue);
	bobj(resizedKey, resizedKeyLength, resizedInitValue, hash2cc);
}
