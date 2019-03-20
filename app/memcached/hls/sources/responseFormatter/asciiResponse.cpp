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

void valueLengthJuggler(stream<ap_uint<80> > &inData, stream<ap_uint<4> > &inCount, stream<ap_uint<80> > &outData, stream<ap_uint<4> > &outCount) { // This functions reorders the bytes in the value length. E.g. if you get 0x333231, it converts that 0x313233. This is to counter the little endianess of the network data
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	ap_uint<8> 	placeHolder = 0;
	ap_uint<4> 	swapCounter	= 1;
	ap_uint<80> inputWord 	= 0;
	ap_uint<4> 	location	= 0;
	ap_uint<80> outputWord	= 0;

	if (!inData.empty() && !inCount.empty() && !outData.full() && !outCount.full()) {
		inData.read(inputWord);
		for (unsigned short int k=10;k>0;--k)
			outputWord.range((8*k)-1, (k-1)*8) = inputWord.range(8*(11-k)-1, (10-k)*8);
		outData.write(outputWord);
		outCount.write(inCount.read());
	}
}

char decimalDigit(ap_uint<34> &remainder, const ap_uint<34> compArray[9]) {
#pragma HLS ARRAY_PARTITION variable=compArray complete
#pragma HLS INLINE
    char decDigit = 0;
    for (char i=8;i>=0;--i) {
        if (remainder >= compArray[i]) {
            remainder -= compArray[i];
            decDigit = i + 1;
            break;
        }
    }
    return decDigit;
}

void byteCounter(stream<ap_uint<80> > &inData, stream<ap_uint<80> > &outData, stream<ap_uint<4> > &outLength) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	if (!inData.empty() && !outLength.full() && !outData.full()) {
		ap_uint<80> inputWord = inData.read();
		for (unsigned short int i=10;i>0;--i) {
			if (inputWord.range((8*i)-1, (i-1)*8) != 0x30) {
				outLength.write(i);
				outData.write(inputWord);
				break;
			}
		}
	}
}

void bin2asciiConverter(stream<ap_uint<32> > &inData, stream<ap_uint<80> > &result) {
	#pragma HLS pipeline II=1 enable_flush

	ap_uint<80> imResult = 0;

	const ap_uint<34> compArray[10][9] = {
	            {1, 2, 3, 4, 5, 6, 7, 8, 9},
	            {1e1, 2e1, 3e1, 4e1, 5e1, 6e1, 7e1, 8e1, 9e1},
	            {1e2, 2e2, 3e2, 4e2, 5e2, 6e2, 7e2, 8e2, 9e2},
	            {1e3, 2e3, 3e3, 4e3, 5e3, 6e3, 7e3, 8e3, 9e3},
	            {1e4, 2e4, 3e4, 4e4, 5e4, 6e4, 7e4, 8e4, 9e4},
	            {1e5, 2e5, 3e5, 4e5, 5e5, 6e5, 7e5, 8e5, 9e5},
	            {1e6, 2e6, 3e6, 4e6, 5e6, 6e6, 7e6, 8e6, 9e6},
	            {1e7, 2e7, 3e7, 4e7, 5e7, 6e7, 7e7, 8e7, 9e7},
	            {1e8, 2e8, 3e8, 4e8, 5e8, 6e8, 7e8, 8e8, 9e8},
	            {1e9, 2e9, 3e9, 4e9, 5e9, 6e9, 7e9, 8e9, 9e9}};
	#pragma HLS ARRAY_PARTITION variable=compArray dim=1 complete

	if (!inData.empty()) {
		ap_uint<34> inputInt = inData.read();

		for (int k = 9; k >= 0; k--) {
			imResult.range(8 * (k + 1) - 1, 8*k) = 48 + decimalDigit(inputInt, compArray[k]);
		}
		result.write(imResult);
	}
}

void merge_s1(stream<ap_uint<80> > &flagsCount2merge, stream<ap_uint<4> > &flagsLength2merge, stream<ap_uint<96> > &merge12merge2, stream<ap_uint<4> > &merge12merge2Length)
{
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	ap_uint<192> 	mergedTemp			=	0;

	if (!flagsCount2merge.empty() && !merge12merge2.full() && !merge12merge2Length.full()) {	// Read everything from the queues
		ap_uint<80> 	flags			= flagsCount2merge.read();
		ap_uint<4>		flagsLength		= flagsLength2merge.read();

		ap_uint<5> mergedLengthTemp = flagsLength + 2;

		mergedTemp.range(7, 0) = 0x20;
		mergedTemp.range(static_cast <short int>(7+(flagsLength*8)), 8) = flags.range((static_cast <short int>(flagsLength*8)-1), 0);
		mergedTemp.range(15+(flagsLength*8), 8+(flagsLength*8)) = 0x20;
		merge12merge2.write(mergedTemp);
		merge12merge2Length.write(mergedLengthTemp);
	}
}

void merge_s2(stream<ap_uint<80> > &vlCount2merge, stream<ap_uint<4> > &vlLength2merge, stream<ap_uint<96> > &merge12merge2, stream<ap_uint<4> > &merge12merge2Length, stream<ap_uint<192> > &mergedFields, stream<ap_uint<5> > &mergedLength)
{
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	ap_uint<192> 	mergedTemp			=	0;

	if (!vlCount2merge.empty() && !merge12merge2.empty() && !mergedFields.full() && !mergedLength.full()) {	// Read everything from the queues
		ap_uint<80> 	valueLength			= vlCount2merge.read();
		ap_uint<4>		vlLength			= vlLength2merge.read();
		ap_uint<96> 	merged1				= merge12merge2.read();
		ap_uint<4>		m1Length			= merge12merge2Length.read();

		ap_uint<5> mergedLengthTemp = m1Length + vlLength + 2;

		mergedTemp.range((m1Length*8)-1,0) = merged1;
		mergedTemp.range(((vlLength*8)+(m1Length*8))-1, m1Length*8) = valueLength.range(79, 80-(static_cast <short int>(vlLength*8)));
		mergedTemp.range(15+((vlLength*8)+(m1Length*8)), ((vlLength*8)+(m1Length*8))) = 0x0a0d;
		mergedFields.write(mergedTemp);
		mergedLength.write(mergedLengthTemp);
	}
}

void inputLogic(stream<pipelineWord> &inData, stream<ap_uint<8> > &opCodeBuffer, stream<ap_uint<8> > &statusBuffer, stream<ap_uint<32> > &flagsExt2flagsConv, stream<ap_uint<32> > &vlExt2vlConv, stream<ap_uint<64> > &valueBuffer, stream<ap_uint<64> > &keyBuffer, stream<ap_uint<8> > &keyLengthBuffer, stream<ap_uint<123> > &networkDataBuffer, stream<ap_uint<32> >	&valueLengthBuffer) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static uint8_t				inWordCounter 		= 0;
	static ap_uint<8>			il_opCode			= 0;
	static ap_uint<8>			af_il_statusCode	= 0;
	// Storage path. Reads data of the bus and stores them into the buffers
	if (!valueBuffer.full() && !opCodeBuffer.full() && !inData.empty())	{
		pipelineWord tempInput = inData.read();
		if (tempInput.SOP == 1 && inWordCounter == 0) {
			statusBuffer.write(tempInput.metadata.range(119, 112));
			opCodeBuffer.write(tempInput.metadata.range(111, 104));
			il_opCode 			= tempInput.metadata.range(111, 104);
			af_il_statusCode 	= tempInput.metadata.range(119, 112);
			if (il_opCode == 0 && tempInput.metadata.bit(112) != 1) {
				keyLengthBuffer.write(tempInput.metadata.range(7, 0));
				vlExt2vlConv.write(tempInput.metadata.range(39, 8) - 8);
				valueLengthBuffer.write(tempInput.metadata.range(39, 8) - 8);
				flagsExt2flagsConv.write(tempInput.value.range(31, 0));
				if (tempInput.keyValid == 1)
					keyBuffer.write(tempInput.key);
			}
			inWordCounter++;
		}
		else if (inWordCounter > 0) {
			if (inWordCounter == 1)
				networkDataBuffer.write(tempInput.metadata);
			if (il_opCode == 0 && tempInput.valueValid == 1 && af_il_statusCode != 1)
				valueBuffer.write(tempInput.value);
			if (il_opCode == 0 && tempInput.keyValid == 1 && af_il_statusCode != 1)
				keyBuffer.write(tempInput.key);
			inWordCounter++;
			if (tempInput.EOP == 1)
				inWordCounter = 0;
		}
	}
}

void outputLogic(stream<ap_uint<8> > &opCodeBuffer, stream<ap_uint<8> > &statusBuffer, stream<ap_uint<192> > &mergedFields, stream<ap_uint<5> > &mergedLength, stream<ap_uint<64> > &valueBuffer, stream<ap_uint<64> > &keyBuffer, stream<ap_uint<8> >	&keyLengthBuffer, stream<ioWord> &outData, stream<ap_uint<123> > &networkDataBuffer, stream<ap_uint<32> >	&valueLengthBuffer) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static ap_uint<123> networkDataTemp 	= 0;
	static ap_uint<192> mergedFieldsTemp 	= 0;
	static ap_uint<64>	keyTemp				= 0;
	static ap_uint<64>	valueTemp			= 0;
	static ap_uint<56>  endTemp				= 0x0a0d444E450a0d; //
	static ap_uint<16>	valueLengthTemp		= 0;
	static ap_uint<5>	mergedLengthTemp 	= 0;
	static ap_uint<5>	mergedLengthBuffer 	= 0;
	static ap_uint<8>	keyLengthTemp		= 0;
	static ap_uint<8>	opCodeTemp			= 0;
	static ap_uint<8>	statusTemp			= 0;
	static uint8_t		outWordCounter		= 0;
	static uint8_t 		outOffset			= 0;
	ioWord 				writeWord 			= {0, 0, 0, 0, 0};
	uint8_t 			mlTemp				= 0;
	uint8_t				vlTemp				= 0;
	uint8_t				klTemp				= 0;

	if (outWordCounter == 0) {	// CD Load ends here
		if (!opCodeBuffer.empty() && !networkDataBuffer.empty() && !statusBuffer.empty()) {
			opCodeBuffer.read(opCodeTemp);
			networkDataBuffer.read(networkDataTemp);
			statusBuffer.read(statusTemp);
			if (opCodeTemp == 1) {
				writeWord.metadata.range(95, 0)	= networkDataTemp.range(95, 0);
				writeWord.SOP 			= 1;
				writeWord.EOP 			= 1;
				opCodeTemp 			= 0;
				if (statusTemp == 0) {// Success!
					writeWord.data 		= 0x0a0d4445524F5453;
					writeWord.metadata.range(111, 96)	= 8;
				}
				else { 				// Failure!
					writeWord.data 		= 0x1111110A0D444E45;
					writeWord.modulus	= 5;
					writeWord.metadata.range(111, 96)	= 5;
				}
				outData.write(writeWord);
			}
			else if (opCodeTemp == 4) {
				writeWord.metadata 	= networkDataTemp;
				writeWord.SOP 		= 1;
				if (statusTemp == 0) {	// Success!
					writeWord.data 		= 0x0D444554454C4544;
					writeWord.metadata.range(111, 96)	= 9;
				}
				else {				// Failure!
					writeWord.data 		= 0x4E554F465F544F4E;
					writeWord.metadata.range(111, 96)	= 11;
				}
				outData.write(writeWord);
				outWordCounter = 60;
			}
			else if (opCodeTemp == 8) {
				writeWord.metadata 	= networkDataTemp;
				writeWord.data 		= 0x0a0d4B4F;
				writeWord.SOP 		= 1;
				writeWord.EOP 		= 1;
				writeWord.modulus	= 4;
				writeWord.metadata.range(111, 96)	= 4;
				outData.write(writeWord);
				opCodeTemp 			= 0;
			}
			else if (opCodeTemp == 0) {
				if (statusTemp == 0) // Success!
					outWordCounter = 5;
				else	// Failure!
				{
					writeWord.metadata 	= networkDataTemp;
					writeWord.data 		= 0x0000000A0D444E45;
					writeWord.SOP 		= 1;
					writeWord.EOP 		= 1;
					writeWord.modulus	= 5;
					writeWord.metadata.range(111, 96)	= 5;
					opCodeTemp 			= 0;
					outData.write(writeWord);
				}
			}
		}
	}
	else if (outWordCounter == 5) {
		if (!keyBuffer.empty() && !keyLengthBuffer.empty() && !mergedFields.empty() && !mergedLength.empty()) {
			ap_uint<32>	vlTempReadVar		= valueLengthBuffer.read();
			valueLengthTemp		= vlTempReadVar.range(15, 0);
			keyLengthBuffer.read(keyLengthTemp);
			mergedFields.read(mergedFieldsTemp);
			mergedLength.read(mergedLengthTemp);
			mergedLengthBuffer = mergedLengthTemp;
			keyBuffer.read(keyTemp);
			writeWord.metadata.range(111, 96)	= 13 + keyLengthTemp + mergedLengthTemp + vlTempReadVar.range(15, 0); // Fill this in with the appropriate value
			writeWord.metadata.range(95, 0)	= networkDataTemp.range(95, 0);
			writeWord.data.range(47, 0) = 0x2045554C4156; // _EULAV
			if (keyLengthTemp == 0) {		// If there is not key at all, then use the two remaining data words to output part of the merged fields
				writeWord.data.range(63, 48) = mergedFieldsTemp.range(15, 0);
				mergedLengthTemp -= 2;
				if (mergedLengthTemp > 7)
					outWordCounter = 2;
				else {
					//uint8_t sum = mergedLengthTemp + valueLengthTemp;
					//if (sum > 8) outWordCounter = 21;
					//else if (sum == 8) outWordCounter = 22;
					//else outWordCounter = 23;
					outWordCounter = 21;	//////////////////////////////////////////////
				}
				outOffset		= 2;
			}
			else if (keyLengthTemp == 1) {	// If the key is only one byte long the output that byte and use also a byte from the merged fields.
				writeWord.data.range(55, 48) = keyTemp.range(7, 0);
				writeWord.data.range(63, 56) = mergedFieldsTemp.range(7, 0);
				mergedLengthTemp--;
				if (mergedLengthTemp > 7)
					outWordCounter = 2;
				else {
					//uint8_t sum = mergedLengthTemp + valueLengthTemp;
					//if (sum > 8) outWordCounter = 21;
					//else if (sum == 8) outWordCounter = 22;
					//else outWordCounter = 23;
					outWordCounter = 21;	//////////////////////////////////////////////
				}

				outOffset		= 1;
				//outWordCounter 	= 2; // There are more merged fields to output
			}
			else if (keyLengthTemp == 2) {
				writeWord.data.range(63, 48) = keyTemp.range(15, 0);
				keyLengthTemp 	= 0;
				outOffset		= 0;
				if (mergedLengthTemp > 7)
					outWordCounter = 2;
					else {
						//uint8_t sum = mergedLengthTemp + valueLengthTemp;
						//if (sum > 8) outWordCounter = 21;
						//else if (sum == 8) outWordCounter = 22;
						outWordCounter = 21;
						//outWordCounter = 21;	//////////////////////////////////////////////
					}
			}
			else if (keyLengthTemp > 2) {	// If the key is > 2 then the remainder of the first word will be occupied by the key
				writeWord.data.range(63, 48) = keyTemp.range(15, 0);
				keyLengthTemp 	-= 2;
				outOffset		= 2;
				if (keyLengthTemp >= 8)
					outWordCounter 	= 11;  	// There's more key to output - THIS IS THE ONLY TRANSITION NTO STATE 1.
				else if ((keyLengthTemp + mergedLengthTemp) >= 9)
					outWordCounter = 12;	// If the sum of the remaining key and the merged fields is enough to fill this word and have at least one left over byte
				else
					outWordCounter = 1;
			}
			writeWord.SOP = 1;
			outData.write(writeWord);
		}
	}
	else if (outWordCounter == 11) {
		if (!keyBuffer.empty()) {
			if (keyLengthTemp > 8) {
				writeWord.data.range(47, 0) = keyTemp.range(63, 16);
				keyBuffer.read(keyTemp);
				writeWord.data.range(63, 48) = keyTemp.range(15, 0);
				keyLengthTemp -= 8;
				if (keyLengthTemp + mergedLengthTemp <= 8)
					outWordCounter = 1;
				else if (keyLengthTemp < 8)
					outWordCounter = 12;
			}
			else if (keyLengthTemp == 8) {
				writeWord.data.range(47, 0) = keyTemp.range(63, 16);
				keyBuffer.read(keyTemp);
				writeWord.data.range(63, 48) = keyTemp.range(15, 0);
				keyLengthTemp 	= 0;
				outOffset 		= 0;
				if (mergedLengthTemp > 7)
					outWordCounter = 2;
				else {
					//uint8_t sum = mergedLengthTemp + valueLengthTemp;
					//if (sum > 8) outWordCounter = 21;
					//else if (sum == 8) outWordCounter = 22;
					//else outWordCounter = 23;
					outWordCounter = 21;	//////////////////////////////////////////////
				}
			}
			outData.write(writeWord);
		}
	}
	else if (outWordCounter == 12) {
		klTemp = keyLengthTemp;
		if (keyLengthTemp > 6 && !keyBuffer.empty()) {
			klTemp -= 6;
			writeWord.data.range(47, 0) = keyTemp.range(63, 16);
			keyBuffer.read(keyTemp);
			writeWord.data.range((klTemp*8)+47, 48) = keyTemp.range((klTemp*8)-1, 0);
			writeWord.data.range(63, (klTemp+6)*8) = mergedFieldsTemp.range(((2-klTemp)*8)-1 , 0);
			outData.write(writeWord);
			mergedLengthTemp -= (8-keyLengthTemp);
			outOffset = 8 - keyLengthTemp;
			if (mergedLengthTemp > 7)
				outWordCounter = 2; // CD Store starts here
			else {
				//uint8_t sum = mergedLengthTemp + valueLengthTemp;
				//if (sum > 8) outWordCounter = 21;
				//else if (sum == 8) outWordCounter = 22;
				//else outWordCounter = 23;
				outWordCounter = 21;	//////////////////////////////////////////////
			}
		}
		else {
			writeWord.data.range((klTemp*8)-1, 0) = keyTemp.range((klTemp*8)+15, 16);
			writeWord.data.range(63, (klTemp*8)) = mergedFieldsTemp.range(((8-klTemp)*8)-1 , 0);
			outData.write(writeWord);
			mergedLengthTemp -= (8-keyLengthTemp);
			outOffset = 8 - keyLengthTemp;
			if (mergedLengthTemp > 7)
				outWordCounter = 2;
			else {
				//uint8_t sum = mergedLengthTemp + valueLengthTemp;
				//if (sum > 8) outWordCounter = 21;
				//else if (sum == 8) outWordCounter = 22;
				//else outWordCounter = 23;
				outWordCounter = 21;	//////////////////////////////////////////////
			}
		}
		//mergedLengthTemp -= (8-keyLengthTemp);
		//outOffset = 8 - keyLengthTemp;
		/*if (mergedLengthTemp > 7)
					outWordCounter = 2;
				else {
					//uint8_t sum = mergedLengthTemp + valueLengthTemp;
					//if (sum > 8) outWordCounter = 21;
					//else if (sum == 8) outWordCounter = 22;
					//else outWordCounter = 23;
					outWordCounter = 21;	//////////////////////////////////////////////
				}*/
		}
	else if (outWordCounter == 1) {
		klTemp = keyLengthTemp;
		if ((keyLengthTemp + mergedLengthTemp) == 8) {
			writeWord.data.range((klTemp*8)-1, 0) = keyTemp.range((klTemp*8)+15, 16);
			writeWord.data.range(63, (klTemp*8)) = mergedFieldsTemp.range(((8-klTemp)*8)-1 , 0);
			mergedLengthTemp = 0;
			outOffset = 0;
			outData.write(writeWord);
			if (valueLengthTemp > 7)		// In this case the value is always byte aligned, so go to state 33 if there are more than 1 value words
				outWordCounter = 33;
			else
				outWordCounter = 31;		// Or to 31 if there will be parts from endTemp output as well
		}
		else {
			writeWord.data.range(7, 0) = keyTemp.range(23, 16);
			writeWord.data.range(55 ,8) = mergedFieldsTemp.range(47, 0);
			valueBuffer.read(valueTemp);
			writeWord.data.range(63, 56) = valueTemp.range(7, 0);
			mergedLengthTemp = 0;
			outData.write(writeWord);
			if (valueLengthTemp == 1) {
				outWordCounter = 4;
				outOffset = 0;
			}
			else if (valueLengthTemp < 9) {
				outWordCounter = 31;
				outOffset = 1;
			}
			else {
				outWordCounter = 3;
				outOffset = 1;
			}
			valueLengthTemp--;
		}
	}
	else if (outWordCounter == 2) {		// State 2 handles packets which have only key remainder and merged length
		mlTemp = mergedLengthTemp;
		vlTemp = valueLengthTemp;
		if (mergedLengthTemp > 8)	{ // If there are more merged output words stay in this state
			writeWord.data.range(63, 0) = mergedFieldsTemp.range((outOffset*8)+63, outOffset*8);
			outOffset 			+= 8;
			//mergedLengthTemp 	-= 8;
			if (mergedLengthTemp > 15)
				outWordCounter 		= 2;
			else {
				outWordCounter 		= 21;
			}
			/*if (mergedLengthTemp < 8) {
				uint8_t sum = mergedLengthTemp + valueLengthTemp;
				if (sum > 8) outWordCounter = 21;
				else if (sum == 8) outWordCounter = 22;
				else outWordCounter = 23;
			}*/
			mergedLengthTemp 	-= 8;
		}
		else if (mergedLengthTemp == 8) {
			writeWord.data.range(63, 0) = mergedFieldsTemp.range((outOffset*8)+63, outOffset*8);
			mergedLengthTemp = 0;
			outOffset = 0;
			if (valueLengthTemp >= 8)
				outWordCounter = 33;
			else
				outWordCounter = 31;
		}
		outData.write(writeWord);
	}
	/*uint8_t sum = mergedLengthTemp + valueLengthTemp;
	if (sum > 8) outWordCounter == 21
	else if (sum == 8) outWordCounter == 22)
	else outWordCounter == 23;*/
	/*else if (outWordCounter == 21) { 	// State 21 - The merge field remainder and the value completely fill this data word and there is value residue to go into the next data word
		if (!valueBuffer.empty()) {
			mlTemp = mergedLengthTemp;
			vlTemp = valueLengthTemp;
			valueBuffer.read(valueTemp);
			writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
			writeWord.data.range(63, (static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range(((static_cast <uint8_t>(8-mergedLengthTemp)*8))-1,0);
			valueLengthTemp -= 8-mergedLengthTemp;			////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			outOffset = 8-mergedLengthTemp;
			outWordCounter = 34;
		}
		mergedLengthTemp = 0;
		outData.write(writeWord);
	}
	else if (outWordCounter == 22) {	// In this case the merged field remainder and the value end exactly at the end of the data word
		if (!valueBuffer.empty()) {
			mlTemp = mergedLengthTemp;
			vlTemp = valueLengthTemp;
			valueBuffer.read(valueTemp);
			writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
			writeWord.data.range(63, (static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range(((static_cast <uint8_t>(8-mergedLengthTemp)*8))-1,0);
			outOffset = 0;
			outWordCounter = 4;
		}
		mergedLengthTemp = 0;
		outData.write(writeWord);
	}
	else if (outWordCounter == 23) {	// Otherwise output the merge remained, the value and the part of the end string (stored in the endTemp variable) that fits into this data word.
		if (!valueBuffer.empty()) {
			mlTemp = mergedLengthTemp;
			vlTemp = valueLengthTemp;
			valueBuffer.read(valueTemp);
			writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
			writeWord.data.range(((static_cast <uint8_t>(mergedLengthTemp)+vlTemp)*8)-1,(static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range((vlTemp*8)-1,0);
			writeWord.data.range(63, (static_cast <short int>(mlTemp+vlTemp)*8)) = endTemp.range((static_cast <short int>((8-(mlTemp+vlTemp))*8))-1, 0);
			outOffset = 8 - (mergedLengthTemp + valueLengthTemp);
			outWordCounter = 4;
		}
		mergedLengthTemp = 0;
		outData.write(writeWord);
	}*/
	else if (outWordCounter == 21) { 	// State 21- This state is used when there's a merged fields remainder to output plus a value. 
		if (!valueBuffer.empty()) {
			mlTemp = mergedLengthTemp;
			vlTemp = valueLengthTemp;
			valueBuffer.read(valueTemp);
			if ((mergedLengthTemp + valueLengthTemp) > 8)	{ // The merge field remainder and the value completely fill this data word and there is value residue to go into the next data word
				writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
				writeWord.data.range(63, (static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range(((static_cast <uint8_t>(8-mergedLengthTemp)*8))-1,0);
				valueLengthTemp -= 8-mergedLengthTemp;
				outOffset = 8-mergedLengthTemp;
				outWordCounter = 34;
			}
			else if ((mergedLengthTemp + valueLengthTemp) == 8) { // In this case the merged field remainder and the value end exactly at the end of the data word
				writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
				writeWord.data.range(63, (static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range(((static_cast <uint8_t>(8-mergedLengthTemp)*8))-1,0);
				outOffset = 0;
				outWordCounter = 4;
			}
			else if ((mergedLengthTemp + valueLengthTemp) < 8)	{ 	// Otherwise output the merge remained, the value and the part of the end string (stored in the endTemp variable) that fits into this data word.
				writeWord.data.range((static_cast <uint8_t>(mergedLengthTemp)*8)-1, 0) = mergedFieldsTemp.range((static_cast <uint8_t>(mergedLengthTemp+outOffset)*8)-1, outOffset*8);
				writeWord.data.range(((static_cast <uint8_t>(mergedLengthTemp)+vlTemp)*8)-1,(static_cast <uint8_t>(mergedLengthTemp)*8)) = valueTemp.range((vlTemp*8)-1,0);
				writeWord.data.range(63, (static_cast <short int>(mlTemp+vlTemp)*8)) = endTemp.range((static_cast <short int>((8-(mlTemp+vlTemp))*8))-1, 0);
				outOffset = 8 -(mergedLengthTemp + valueLengthTemp);
				outWordCounter = 4;
			}
			mergedLengthTemp = 0;
			outData.write(writeWord);
		}
	}
	else if (outWordCounter == 3)	{ // Output value state, when the value has more than one data words.
		if (!valueBuffer.empty()) {
			if (outOffset != 0) {
				writeWord.data.range(63-(outOffset*8), 0) = valueTemp.range(63, (outOffset*8));
				valueBuffer.read(valueTemp);
				writeWord.data.range(63, (8-outOffset)*8) = valueTemp.range((outOffset*8)-1, 0);
				outData.write(writeWord);
			}
			else if (outOffset == 0) {
				valueBuffer.read(valueTemp);
				writeWord.data.range(63, 0) = valueTemp.range(63, 0);
				outData.write(writeWord);
			}
			if (valueLengthTemp >= 16)
				valueLengthTemp -= 8;
			else if (valueLengthTemp > 8) {
				valueLengthTemp -= 8;
				outWordCounter = 31;
			}
			else if (valueLengthTemp == 8) {
				valueLengthTemp = 0;
				outOffset = 0;
				outWordCounter = 4;
			}
		}
		//outData.write(writeWord);
	}
	else if (outWordCounter == 31) {
		bool executed = false;
		if (outOffset == 0)	{
			if  (!valueBuffer.empty()) {
				valueBuffer.read(valueTemp);
				writeWord.data.range((static_cast <uint8_t>(valueLengthTemp)*8)-1, 0) = valueTemp.range((static_cast <uint8_t>(outOffset+valueLengthTemp)*8)-1, (outOffset*8));
				executed = true;
			}
		}
		else if (valueLengthTemp > (8-outOffset)) {
			if (!valueBuffer.empty()) {
				writeWord.data.range((static_cast <uint8_t>(valueLengthTemp)*8)-1, 0) = valueTemp.range(63, outOffset*8);
				valueBuffer.read(valueTemp);
				writeWord.data.range((static_cast <uint8_t>(valueLengthTemp)*8)-1, (static_cast <uint8_t>(8-outOffset)*8)) = valueTemp.range((static_cast <uint8_t>(valueLengthTemp-(8-outOffset))*8)-1, 0);
				executed = true;
			}
		}
		else if (outOffset != 0 && (valueLengthTemp <= (8-outOffset))) {
			writeWord.data.range((static_cast <uint8_t>(valueLengthTemp)*8)-1, 0) = valueTemp.range((static_cast <uint8_t>(outOffset+valueLengthTemp)*8)-1, (outOffset*8));
			executed = true;
		}
		if (executed == true) {
			writeWord.data.range(63, (static_cast <uint8_t>(valueLengthTemp*8))) = endTemp.range((static_cast <uint8_t>(8-valueLengthTemp)*8)-1, 0);
			if (valueLengthTemp == 1) {
				writeWord.EOP = 1;
				outWordCounter = 0;
				outOffset = 0;
			}
			else {
				outWordCounter = 4;
				outOffset = 8-valueLengthTemp;
			}
			valueLengthTemp = 0;
			outData.write(writeWord);
		}
	}
	else if (outWordCounter == 33)	{ 	// This state outputs value data when the value is correctly aligned in the output (practically, when the merged data end at the end of the previous data word)
		if (!valueBuffer.empty()) {
			valueBuffer.read(valueTemp);
			writeWord.data.range(63, 0) = valueTemp.range(63, 0);
			if (valueLengthTemp >= 16)
				valueLengthTemp -= 8;
			else if (valueLengthTemp > 8)
			{
				valueLengthTemp -= 8;
				outWordCounter = 31;
			}
			else if (valueLengthTemp == 8)
			{
				valueLengthTemp = 0;
				outOffset = 0;
				outWordCounter = 4;
			}
			outData.write(writeWord);
		}
	}
	else if (outWordCounter == 34) {	// This state is actually a bubble in the pipeline (not in the output). Will try to alleviate this in future versions.
		if (valueLengthTemp >= 8)
			outWordCounter = 3;
		else
			outWordCounter = 31;
	}
	else if (outWordCounter == 4)	{	// Output remaining trail characters
		writeWord.data.range((static_cast <uint8_t>(7-outOffset)*8)-1, 0) = endTemp.range(55, (static_cast <uint8_t>(outOffset)*8));
		if (outOffset == 7)
			writeWord.modulus = 0;
		else
			writeWord.modulus = 7-outOffset;
		writeWord.EOP = 1;
		outWordCounter = 0;
		outData.write(writeWord);
	}
	else if (outWordCounter == 60) {	// output state for delete rqs
		if (statusTemp == 0) {	// Success!
			writeWord.data 		= 0x000000000000000A;
			writeWord.EOP 		= 1;
			writeWord.modulus	= 1;
			outData.write(writeWord);
		}
		else {				// Failure!
			writeWord.data 		= 0x00000000000A0D44;
			writeWord.EOP 		= 1;
			writeWord.modulus	= 3;
			outData.write(writeWord);
		}
		outWordCounter = 0;
	}
}

void asciiResponse(stream<pipelineWord> &inData, stream<ioWord> &outData) {
	#pragma HLS INLINE

	static stream<ap_uint<8> >		opCodeBuffer("opCodeBuffer");				// Internal queue to store the metadata words
	static stream<ap_uint<8> > 		statusBuffer("statusBuffer");				// Contains the sequence in which the contents of the two buffers have to be read out
	static stream<ap_uint<64> >		valueBuffer("valueBuffer");
	static stream<ap_uint<32> >		vlExt2vlConv("vlExt2vlConv");
	static stream<ap_uint<80> >		vlConv2ol("vlConv2ol");
	static stream<ap_uint<80> >	   	vlZF2vlCount("vlZF2vlCount");
	static stream<ap_uint<64> >		keyBuffer("apKeyBuffer");
	static stream<ap_uint<8> >		keyLengthBuffer("keyLengthBuffer");
	static stream<ap_uint<32> >		valueLengthBuffer("valueLengthBuffer");		// This stores the value length used for value output and NOT for conversion
	static stream<ap_uint<80> >		flagsCount2mergeS1("flagsCount2mergeS1");
	static stream<ap_uint<4> >		flagsLength2mergeS1("flagsLength2mergeS1");
	static stream<ap_uint<32> >		flagsExt2flagsConv("flagsExt2flagsConv");
	static stream<ap_uint<80> >		flagsConv2ol("flagsConv2ol");
	static stream<ap_uint<80> >		flagsZF2flagsCount("flagsZF2flagsCount");
	static stream<ap_uint<80> >		vlJug2merge("vlJug2merge");
	static stream<ap_uint<4> >		vlJugLength2merge("vlJugLength2merge");
	static stream<ap_uint<80> >		vlCount2vlJug("vlCount2vlJug");
	static stream<ap_uint<4> >		vlCountLength2vlJug("vlCountLength2vlJug");
	static stream<ap_uint<192> >	mergedFields("mergedFields");
	static stream<ap_uint<5> >		mergedLength("mergedLength");
	static stream<ap_uint<123> > 	networkDataBuffer("networkDataBuffer");
	static stream<ap_uint<96> >     merge12merge2("merge12merge2");
	static stream<ap_uint<4> > 		merge12merge2Length("merge12merge2Length");

	#pragma HLS STREAM variable=merge12merge2 			depth=1
	#pragma HLS STREAM variable=merge12merge2Length		depth=1
	#pragma HLS STREAM variable=opCodeBuffer 			depth=16
	#pragma HLS STREAM variable=statusBuffer			depth=16
	#pragma HLS STREAM variable=valueBuffer 			depth=1024
	#pragma HLS STREAM variable=keyBuffer 				depth=128
	#pragma HLS STREAM variable=vlExt2vlConv 			depth=4
	#pragma HLS STREAM variable=vlConv2ol 				depth=4
	#pragma HLS STREAM variable=keyLengthBuffer 		depth=16
	#pragma HLS STREAM variable=valueLengthBuffer 		depth=16
	#pragma HLS STREAM variable=flagsExt2flagsConv 		depth=4
	#pragma HLS STREAM variable=flagsConv2ol 			depth=1
	#pragma HLS STREAM variable=mergedFields 			depth=1
	#pragma HLS STREAM variable=mergedLength 			depth=1
	#pragma HLS STREAM variable=networkDataBuffer 		depth=16
	#pragma HLS STREAM variable=flagsCount2mergeS1 		depth=1
	#pragma HLS STREAM variable=flagsLength2mergeS1 	depth=1

	#pragma HLS resource variable=merge12merge2Length core=FIFO_LUTRAM

	inputLogic(inData, opCodeBuffer, statusBuffer, flagsExt2flagsConv, vlExt2vlConv, valueBuffer, keyBuffer, keyLengthBuffer, networkDataBuffer, valueLengthBuffer);
	bin2asciiConverter(flagsExt2flagsConv, flagsConv2ol);
	byteCounter(flagsConv2ol, flagsCount2mergeS1, flagsLength2mergeS1);
	bin2asciiConverter(vlExt2vlConv, vlConv2ol);
	byteCounter(vlConv2ol, vlCount2vlJug, vlCountLength2vlJug);
	valueLengthJuggler(vlCount2vlJug, vlCountLength2vlJug, vlJug2merge, vlJugLength2merge);
	merge_s1(flagsCount2mergeS1, flagsLength2mergeS1, merge12merge2, merge12merge2Length);
	merge_s2(vlJug2merge, vlJugLength2merge, merge12merge2, merge12merge2Length, mergedFields, mergedLength);
	outputLogic(opCodeBuffer, statusBuffer, mergedFields, mergedLength, valueBuffer, keyBuffer, keyLengthBuffer, outData, networkDataBuffer, valueLengthBuffer);
}
