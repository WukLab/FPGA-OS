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

void accessControl(stream<pipelineWord> &inData, stream<pipelineWord> &accCtrl2demux, stream<ap_uint<1> > &filterPopSet, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE region
	#pragma HLS pipeline II=1 enable_flush

	static enum aState{ACC_IDLE = 0, ACC_EVAL, ACC_QRD, ACC_POP, ACC_POP_WAIT, ACC_STREAM, ACC_WAIT, ACC_PUSH} accState;
	static accessFilter 		accessCtrl;
	static pipelineWord 		inputWord 	= {0, 0, 0, 0, 0, 0, 0};
	static accessWord 			pushWord 	= {0, 0, 1};
	static stream<ap_uint<2> >	filterSeq;										// This stream stores the order of the operations to be read from the two pop queues.
	static ap_uint<2>			streamToPop	= 2;								// Indicates which stream is to be popped next


	#pragma HLS STREAM variable=filterSeq	depth=16

	switch(accState) {
		case ACC_IDLE:
		{
			if (streamToPop == 1 && !filterPopSet.empty() )							// If the next operation to pop is a set and a SET has been completed...
				accState = ACC_POP;													// then move to ACC_POP and extract it from the queue
			else if (streamToPop == 0 && !filterPopGet.empty())						// Same thing for a get
				accState = ACC_POP;
			else {																	// If not
				if (!inData.empty() && !filterSeq.full()) {							// Check if there's new data at the input AND if the pop order queue is not full
					inData.read(inputWord);
					if (inputWord.metadata.bit(112) == 1 || inputWord.metadata.range(111, 104) == 8 || inputWord.metadata.range(111, 104) == 4) {	// If this is a failed operation, a FLUSH or a DEL just stream it through as it does not affect the pipeline
						accCtrl2demux.write(inputWord);
						accState = ACC_STREAM;
					}
					else {
						pushWord.address 	= inputWord.metadata.range(103, 72);
						pushWord.operation 	= inputWord.metadata.range(111, 104);
						filterSeq.write(inputWord.metadata.bit(104));
						accState = ACC_EVAL;
					}
				}
			}
			break;
		}
		case ACC_EVAL:
		{
			if (!accessCtrl.compare(pushWord) && !accessCtrl.full())
				accState = ACC_PUSH;
			else {
				if (streamToPop == 2)
					accState = ACC_QRD;
				else
					accState = ACC_WAIT;
			}
			break;
		}
		case ACC_QRD:
		{
			filterSeq.read(streamToPop);
			accState = ACC_WAIT;
			break;
		}
		case ACC_PUSH:
		{
			if (streamToPop == 2 && !filterSeq.empty())
				filterSeq.read(streamToPop);
			accessCtrl.push(pushWord);
			accCtrl2demux.write(inputWord);
			accState = ACC_STREAM;
			break;
		}
		case ACC_STREAM:
		{
			inData.read(inputWord);
			accCtrl2demux.write(inputWord);
			if (inputWord.EOP == 1)
				accState = ACC_IDLE;
			break;
		}
		case ACC_WAIT:
		{
			if (streamToPop == 1 && !filterPopSet.empty() )
				accState = ACC_POP_WAIT;
			else if (streamToPop == 0 && !filterPopGet.empty())
				accState = ACC_POP_WAIT;
			else {
				if (!accessCtrl.compare(pushWord) && !accessCtrl.full())
					accState = ACC_PUSH;
			}
			break;
		}
		case ACC_POP_WAIT:
		{
			if (streamToPop == 1)
				ap_uint<1> tempPop = filterPopSet.read();
			else if (streamToPop == 0)
				ap_uint<1> tempPop = filterPopGet.read();
			if (!filterSeq.empty())
				filterSeq.read(streamToPop);
			else
				streamToPop = 2;
			accessCtrl.pop();
			accState = ACC_WAIT;
			break;
		}
		case ACC_POP:
		{
			if (streamToPop == 1)
				ap_uint<1> tempPop = filterPopSet.read();
			else if (streamToPop == 0)
				ap_uint<1> tempPop = filterPopGet.read();
			if (!filterSeq.empty())
				filterSeq.read(streamToPop);
			else
				streamToPop = 2;
			accessCtrl.pop();
			accState = ACC_IDLE;
			break;
		}
	}
}

void demux(stream<pipelineWord> &accCtrl2demux, stream<internalWord>	&setValueIn, stream<valueStoreInternalWordMd>	&setMetadata, stream<valueStoreInternalWordMd>	&getMetadata, stream<metadataWord>	&metadataBuffer, stream<ap_uint<64> > &keyBuffer) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum dState{DMUX_IDLE = 0, DMUX_SET, DMUX_STREAM} demuxState;
	static ap_uint<16>	valueLength = 0;
	static pipelineWord inputWord = {0, 0, 0, 0, 0, 0, 0};
	static ap_uint<2> 	wordCounter = 0;
	
	switch(demuxState)
	{
		case DMUX_IDLE:
		{
			if (!accCtrl2demux.empty())
			{
				accCtrl2demux.read(inputWord);
				if(inputWord.SOP == 1)
				{
					wordCounter = 1;
					if (inputWord.metadata.bit(112) == 1 || inputWord.metadata.range(111, 104) == 8 || inputWord.metadata.range(111, 104) == 4)	// If this is a failed GET/SET or a DELETE or a FLUSH
					{
						metadataWord metadataWrWord = {inputWord.metadata, inputWord.SOP, inputWord.keyValid, inputWord.valueValid, inputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						if (inputWord.keyValid == 1 && inputWord.metadata.range(111, 104) != 8)
							keyBuffer.write(inputWord.key);
						demuxState = DMUX_STREAM;
					}
					else if (inputWord.metadata.range(111, 104) == 0)	// If this is a GET operation
					{
						metadataWord metadataWrWord = {inputWord.metadata, inputWord.SOP, inputWord.keyValid, inputWord.valueValid, inputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						valueStoreInternalWordMd	getMd = {inputWord.metadata.range(72+dramMemAddressWidth, 72), inputWord.metadata.range(20, 8)};
						getMetadata.write(getMd);
						if (inputWord.keyValid == 1)
							keyBuffer.write(inputWord.key);
						demuxState = DMUX_STREAM;
					}
					else if (inputWord.metadata.range(111, 104) == 1)	// or if finally this is a SET operation
					{
						metadataWord metadataWrWord = {inputWord.metadata, inputWord.SOP, inputWord.keyValid, inputWord.valueValid, inputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						valueStoreInternalWordMd	setMd = {inputWord.metadata.range(72+dramMemAddressWidth, 72), inputWord.metadata.range(20, 8)};
						setMetadata.write(setMd);
						internalWord setData = {inputWord.value, 1, 0};
						valueLength = inputWord.metadata(19, 8);
						if (inputWord.metadata(19, 8) < 9)
							setData.EOP = 1;
						else
							valueLength -= 8;
						setValueIn.write(setData);
						if (inputWord.keyValid == 1)
							keyBuffer.write(inputWord.key);
						demuxState = DMUX_SET;
					}
				}
			}
			break;
		}
		case DMUX_STREAM:
		{
			if(!accCtrl2demux.empty())
			{
				accCtrl2demux.read(inputWord);
				metadataWord metadataWrWord = {inputWord.metadata, inputWord.SOP, inputWord.keyValid, inputWord.valueValid, inputWord.EOP};
				if (wordCounter < 2)
				{
					metadataBuffer.write(metadataWrWord);
					wordCounter++;
				}
				if (inputWord.keyValid == 1)
					keyBuffer.write(inputWord.key);
				if (inputWord.EOP == 1)
					demuxState = DMUX_IDLE;
			}
			break;
		}
		case DMUX_SET:
		{
			accCtrl2demux.read(inputWord);
			metadataWord metadataWrWord = {inputWord.metadata, inputWord.SOP, inputWord.keyValid, inputWord.valueValid, inputWord.EOP};
			if (wordCounter < 2)
			{
				metadataBuffer.write(metadataWrWord);
				wordCounter++;
			}
			if (inputWord.keyValid == 1)
				keyBuffer.write(inputWord.key);
			internalWord setData = {inputWord.value, 0, 0};
			if (valueLength < 9)
				setData.EOP = 1;
			else
				valueLength -= 8;
			if (inputWord.valueValid == 1)
				setValueIn.write(setData);
			if (inputWord.EOP == 1)
				demuxState = DMUX_IDLE;
			break;
		}
	}
}

void setPath(stream<valueStoreInternalWordMd>	&setMetadata, stream<internalWord>	&setValueIn, stream<memCtrlWord> &memWrCmd, stream<ap_uint<512> > &memWrData, stream<ap_uint<1> > &filterPop) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static valueStoreInternalWordMd 	setMdBuffer		= {0, 0};
	internalWord			setInputWord	= {0, 0, 0};
	static	ap_uint<512>	setValueBuffer 	= 0;
	static uint8_t			counter			= 0;
	static uint8_t			setNumOfWords	= 0;
	static enum sState{SET_IDLE = 0, SET_ACC_FIRST, SET_ACC, SET_WR_SINGLE, SET_WR_FIRST, SET_WR, SET_WR_FINAL} setState;

	switch(setState)
	{
		case SET_IDLE:
		{
			setValueBuffer = 0;
			if (!setMetadata.empty() && !setValueIn.empty())
			{
				setMetadata.read(setMdBuffer);
				setNumOfWords = setMdBuffer.length / 64;
				if (setMdBuffer.length > (setNumOfWords*64))
					setNumOfWords++;
				setValueIn.read(setInputWord);
				if (setInputWord.SOP == 1)
				{
					setValueBuffer.range (63, 0) = setInputWord.data;
					setState = SET_ACC_FIRST;
				}
			}
			break;
		}
		case SET_ACC_FIRST:
		{
			if (!setValueIn.empty())
			{
				counter++;
				setValueIn.read(setInputWord);
				setValueBuffer.range (((counter+1)*64)-1, counter*64) = setInputWord.data;
				if (setInputWord.EOP == 1)
					setState = SET_WR_SINGLE;
				else if (counter == (memIntWidth/64) - 1)
					setState = SET_WR_FIRST;
				else
					setState = SET_ACC_FIRST;
			}
			break;
		}
		case SET_WR_SINGLE:
		{
			counter = 0;
			memCtrlWord setCtrlWord = {setMdBuffer.address, 0};
			setCtrlWord.count = setNumOfWords;
			memWrCmd.write(setCtrlWord);
			memWrData.write(setValueBuffer);
			filterPop.write(1);
			setState = SET_IDLE;
			break;
		}
		case SET_WR_FIRST:
		{
			counter = 0;
			memCtrlWord setCtrlWord = {setMdBuffer.address, 0};
			setCtrlWord.count = setNumOfWords;
			memWrCmd.write(setCtrlWord);
			memWrData.write(setValueBuffer);
			setState = SET_ACC;
			break;
		}
		case SET_ACC:
		{
			if (!setValueIn.empty())
			{
				setValueIn.read(setInputWord);
				setValueBuffer.range (((counter+1)*64)-1, counter*64) = setInputWord.data;
				if (setInputWord.EOP == 1)
					setState = SET_WR_FINAL;
				else if (counter == (memIntWidth/64) - 1)
					setState = SET_WR;
				else
					setState = SET_ACC;
				counter++;
			}
			break;
		}
		case SET_WR:
		{
			counter = 0;
			memWrData.write(setValueBuffer);
			setState = SET_ACC;
			break;
		}
		case SET_WR_FINAL:
		{
			counter = 0;
			memWrData.write(setValueBuffer);
			filterPop.write(1);
			setState = SET_IDLE;
			break;
		}
	}
}

void setPathNoFilter(stream<valueStoreInternalWordMd>	&setMetadata, stream<internalWord>	&setValueIn, stream<memCtrlWord> &memWrCmd, stream<ap_uint<512> > &memWrData) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static valueStoreInternalWordMd 	setMdBuffer		= {0, 0};
	internalWord			setInputWord	= {0, 0, 0};
	static	ap_uint<512>	setValueBuffer 	= 0;
	static uint8_t			counter			= 0;
	static uint8_t			setNumOfWords	= 0;
	static enum sState{SET_IDLE = 0, SET_ACC_FIRST, SET_ACC, SET_WR_SINGLE, SET_WR_FIRST, SET_WR, SET_WR_FINAL} setState;

	switch(setState)
	{
		case SET_IDLE:
		{
			setValueBuffer = 0;
			if (!setMetadata.empty() && !setValueIn.empty())
			{
				setMetadata.read(setMdBuffer);
				setNumOfWords = setMdBuffer.length / 64;
				if (setMdBuffer.length > (setNumOfWords*64))
					setNumOfWords++;
				setValueIn.read(setInputWord);
				if (setInputWord.SOP == 1)
				{
					setValueBuffer.range (63, 0) = setInputWord.data;
					setState = SET_ACC_FIRST;
				}
			}
			break;
		}
		case SET_ACC_FIRST:
		{
			if (!setValueIn.empty())
			{
				counter++;
				setValueIn.read(setInputWord);
				setValueBuffer.range (((counter+1)*64)-1, counter*64) = setInputWord.data;
				if (setInputWord.EOP == 1)
					setState = SET_WR_SINGLE;
				else if (counter == (memIntWidth/64) - 1)
					setState = SET_WR_FIRST;
				else
					setState = SET_ACC_FIRST;
			}
			break;
		}
		case SET_WR_SINGLE:
		{
			counter = 0;
			memCtrlWord setCtrlWord = {setMdBuffer.address, 0};
			setCtrlWord.count = setNumOfWords;
			memWrCmd.write(setCtrlWord);
			memWrData.write(setValueBuffer);
			setState = SET_IDLE;
			break;
		}
		case SET_WR_FIRST:
		{
			counter = 0;
			memCtrlWord setCtrlWord = {setMdBuffer.address, 0};
			setCtrlWord.count = setNumOfWords;
			memWrCmd.write(setCtrlWord);
			memWrData.write(setValueBuffer);
			setState = SET_ACC;
			break;
		}
		case SET_ACC:
		{
			if (!setValueIn.empty())
			{
				setValueIn.read(setInputWord);
				setValueBuffer.range (((counter+1)*64)-1, counter*64) = setInputWord.data;
				if (setInputWord.EOP == 1)
					setState = SET_WR_FINAL;
				else if (counter == (memIntWidth/64) - 1)
					setState = SET_WR;
				else
					setState = SET_ACC;
				counter++;
			}
			break;
		}
		case SET_WR:
		{
			counter = 0;
			memWrData.write(setValueBuffer);
			setState = SET_ACC;
			break;
		}
		case SET_WR_FINAL:
		{
			counter = 0;
			memWrData.write(setValueBuffer);
			setState = SET_IDLE;
			break;
		}
	}
}

void dispatch(stream<valueStoreInternalWordMd>	&getMetadata, stream<ap_uint<12> > &valueLengthQ, stream<memCtrlWord> &memRdCmd) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	valueStoreInternalWordMd getMdBuffer	= {0, 0};
	static uint8_t					getNumOfWords	= 0;

	if (!getMetadata.empty())
	{
		getMetadata.read(getMdBuffer);
		getNumOfWords = getMdBuffer.length / 64;
		if (getMdBuffer.length > (getNumOfWords*64))
			getNumOfWords++;
		memCtrlWord getCtrlWord = {getMdBuffer.address, getNumOfWords};
		memRdCmd.write(getCtrlWord);
		valueLengthQ.write(getMdBuffer.length);
	}
}

void receive(stream<ap_uint<12> > &valueLengthQ, stream<ap_uint<512> > &memRdData, stream<ap_uint<64> >	&getValueOut, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum gState {GET_IDLE, GET_ACC} getState;
	static	ap_uint<512>			memInputWord 	= 0;
	static  ap_uint<12> 		 	getValueLength 	= 0;
	static	uint8_t					getCounter		= 0;

	switch(getState) {
		case GET_IDLE:
		{
			if(!valueLengthQ.empty() && !memRdData.empty())	{
				valueLengthQ.read(getValueLength);
				memRdData.read(memInputWord);
				getValueOut.write(memInputWord.range(63, 0));
				getValueLength -= 8;
				getCounter++;
				getState = GET_ACC;
			}
			break;
		}
		case GET_ACC:
		{
			getValueOut.write(memInputWord.range(((getCounter+1)*64)-1, getCounter*64));
			getValueLength > 7 ? getValueLength -= 8 : getValueLength = 0;
			if (getValueLength == 0) {
				filterPopGet.write(1);
				getState = GET_IDLE;
				getCounter = 0;
			}
			else if (getCounter == 7) {
				memRdData.read(memInputWord);
				getCounter = 0;
			}
			else
				getCounter++;
			break;
		}
	}
}

void receiveNoFilter(stream<ap_uint<12> > &valueLengthQ, stream<ap_uint<512> > &memRdData, stream<ap_uint<64> >	&getValueOut) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum gState {GET_IDLE, GET_ACC} getState;
	static	ap_uint<512>			memInputWord 	= 0;
	static  ap_uint<12> 		 	getValueLength 	= 0;
	static	uint8_t					getCounter		= 0;

	switch(getState) {
		case GET_IDLE:
		{
			if(!valueLengthQ.empty() && !memRdData.empty())	{
				valueLengthQ.read(getValueLength);
				memRdData.read(memInputWord);
				getValueOut.write(memInputWord.range(63, 0));
				getValueLength -= 8;
				getCounter++;
				getState = GET_ACC;
			}
			break;
		}
		case GET_ACC:
		{
			getValueOut.write(memInputWord.range(((getCounter+1)*64)-1, getCounter*64));
			getValueLength > 7 ? getValueLength -= 8 : getValueLength = 0;
			if (getValueLength == 0) {
				//filterPopGet.write(1);
				getState = GET_IDLE;
				getCounter = 0;
			}
			else if (getCounter == 7) {
				memRdData.read(memInputWord);
				getCounter = 0;
			}
			else
				getCounter++;
			break;
		}
	}
}

void getPath(stream<valueStoreInternalWordMd>	&getMetadata, stream<ap_uint<64> >	&getValueOut, stream<memCtrlWord> &memRdCmd, stream<ap_uint<512> > &memRdData, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INLINE

	static stream<ap_uint<12> >		disp2rec;						// Internal queue to store the value length of the value to be received from the memory

	#pragma HLS STREAM variable=disp2rec 	depth=16

	dispatch(getMetadata, disp2rec, memRdCmd);					// Receives the get metadata from the demux and dispatches the read request to the memory
	receive(disp2rec, memRdData, getValueOut, filterPopGet);	// Waits for data from the memory, read them and converts them to 64-bit words. Also pops the respective get from the access control upon completion.
}

void getPathNoFilter(stream<valueStoreInternalWordMd>	&getMetadata, stream<ap_uint<64> >	&getValueOut, stream<memCtrlWord> &memRdCmd, stream<ap_uint<512> > &memRdData) {
	#pragma HLS INLINE

	static stream<ap_uint<12> >		disp2rec;						// Internal queue to store the value length of the value to be received from the memory

	#pragma HLS STREAM variable=disp2rec 	depth=16

	dispatch(getMetadata, disp2rec, memRdCmd);					// Receives the get metadata from the demux and dispatches the read request to the memory
	receiveNoFilter(disp2rec, memRdData, getValueOut);	// Waits for data from the memory, read them and converts them to 64-bit words. Also pops the respective get from the access control upon completion.
}

void remux(stream<ap_uint<64> >	&getPath2remux, stream<ap_uint<64> > &keyBuffer, stream<metadataWord>	&metadataBuffer, stream<pipelineWord> &outData) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum rmState{RMUX_IDLE = 0, RMUX_OPCODECHECK, RMUX_REST_MD1, RMUX_REST_MD2, RMUX_GET_REST, RMUX_GET_MD1, RMUX_GET_MD2, RMUX_REST_REST} remuxState;
	static metadataWord rmMdBuffer 		= {0, 0, 0, 0, 0};
	static uint8_t 		rmKeyLength		= 0;
	static uint16_t		rmValueLength 	= 0;
	pipelineWord		outputWord		= {0, 0, 0, 0, 0, 0, 0};

	switch(remuxState) {
		case RMUX_IDLE:
		{
			if (!metadataBuffer.empty()) {
				metadataBuffer.read(rmMdBuffer);
				if (rmMdBuffer.SOP == 1) {
					rmKeyLength = rmMdBuffer.metadata.range(7, 0);
					remuxState = RMUX_OPCODECHECK;
				}
			}
		case RMUX_OPCODECHECK:
		{
			if (rmMdBuffer.metadata.range(119, 112) == 1 || rmMdBuffer.metadata.range(111, 104) == 8 || rmMdBuffer.metadata.range(111, 104) == 4 || rmMdBuffer.metadata.range(111, 104) == 1) {
				if (rmKeyLength > 0) {	// If there is a key present
					if (!keyBuffer.empty()) {
						keyBuffer.read(outputWord.key);		// Read it
						outputWord.keyValid = 1;
						rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
						outputWord.SOP = 1;
						outputWord.metadata = rmMdBuffer.metadata;
						remuxState = RMUX_REST_MD1;
						outData.write(outputWord);
					}
				}
				else {
					outputWord.SOP = 1;
					outputWord.metadata = rmMdBuffer.metadata;
					remuxState = RMUX_REST_MD1;
					outData.write(outputWord);
				}
			}
			else if (rmMdBuffer.metadata.range(111, 104) == 0 && !getPath2remux.empty()) {
				if (rmKeyLength > 0) {	// If there is a key present
					keyBuffer.read(outputWord.key);							// Read it
					outputWord.keyValid = 1;
					rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
				}
				rmValueLength = rmMdBuffer.metadata.range(20, 8);
				rmValueLength > 7 ? rmValueLength -= 8 : rmValueLength = 0;
				outputWord.value = getPath2remux.read();
				outputWord.valueValid = 1;
				outputWord.SOP = 1;
				outputWord.metadata = rmMdBuffer.metadata;
				remuxState = RMUX_GET_MD1;
				outData.write(outputWord);
			}
		}
		break;
		}
		case RMUX_REST_MD1:
		{
			if (!metadataBuffer.empty()) {
				metadataBuffer.read(rmMdBuffer);
				if (rmKeyLength > 0) { 		// If there is a key present
					if (!keyBuffer.empty())	{
						keyBuffer.read(outputWord.key);		// Read it
						outputWord.keyValid = 1;
						rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
						outputWord.metadata = rmMdBuffer.metadata;
						if (rmKeyLength > 0)
							remuxState = RMUX_REST_REST;
						else {
							outputWord.EOP = 1;
							remuxState = RMUX_IDLE;
						}
						outData.write(outputWord);
					}
				}
				else {
					outputWord.metadata = rmMdBuffer.metadata;
					outputWord.EOP 		= 1;
					remuxState	 		= RMUX_IDLE;
					outData.write(outputWord);
				}
			}
			break;
		}
		case RMUX_REST_REST:
		{
			if (rmKeyLength > 0) { // If there is a key present
				if (!keyBuffer.empty()) {
					keyBuffer.read(outputWord.key);		// Read it
					outputWord.keyValid = 1;
					rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
					if (rmKeyLength == 0) {
						outputWord.EOP = 1;
						remuxState = RMUX_IDLE;
					}
					outData.write(outputWord);
				}
			}
			break;
		}
		case RMUX_GET_MD1:
		{
			if (!metadataBuffer.empty() && (!(rmKeyLength > 0) || (rmKeyLength > 0 && !keyBuffer.empty())) && (!(rmValueLength > 0) || (rmValueLength > 0 && !getPath2remux.empty())))  {
				metadataBuffer.read(rmMdBuffer);
				if (rmKeyLength > 0) { // If there is a key present
					outputWord.key 		= keyBuffer.read();							// Read it
					outputWord.keyValid = 1;
					rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
				}
				if (rmValueLength > 0) {
					outputWord.value = getPath2remux.read();
					outputWord.valueValid = 1;
					rmValueLength > 7 ? rmValueLength -= 8 : rmValueLength = 0;
				}
				outputWord.metadata = rmMdBuffer.metadata;
				if (rmValueLength == 0 && rmKeyLength == 0) {
					outputWord.EOP = 1;
					remuxState = RMUX_IDLE;
				}
				else
					remuxState = RMUX_GET_REST;
				outData.write(outputWord);
			}
			break;
		}
		case RMUX_GET_REST:
		{
			if ((!(rmKeyLength > 0) || (rmKeyLength > 0 && !keyBuffer.empty())) && (!(rmValueLength > 0) || (rmValueLength > 0 && !getPath2remux.empty()))) {
				if (rmKeyLength > 0) {												// If there is a key present
					outputWord.key 		= keyBuffer.read();							// Read it
					outputWord.keyValid = 1;
					rmKeyLength > 7 ? rmKeyLength -= 8: rmKeyLength = 0;
				}
				if (rmValueLength > 0) {
					outputWord.value = getPath2remux.read();
					outputWord.valueValid = 1;
					rmValueLength > 7 ? rmValueLength -= 8 : rmValueLength = 0;
				}
				if (rmValueLength == 0 && rmKeyLength == 0)	{
					outputWord.EOP = 1;
					remuxState = RMUX_IDLE;
				}
				outData.write(outputWord);
			}
			break;
		}
	}
}

void valueStoreDram(stream<pipelineWord> &inData, stream<memCtrlWord> &memRdCmd, stream<ap_uint<512> > &memRdData, stream<memCtrlWord> &memWrCmd, stream<ap_uint<512> > &memWrData, stream<pipelineWord> &outData) {

	#pragma HLS INTERFACE	 ap_ctrl_none 		port=return

	#pragma HLS INLINE

	static stream<internalWord>				demux2setPathValue("demux2setPathValue");
	static stream<ap_uint<64> >				getPath2remux("getPath2remux");
	static stream<valueStoreInternalWordMd>	demux2setPathMetadata("demux2setPathMetadata");			// Address & Value Length
	static stream<valueStoreInternalWordMd>	demux2getPath("demux2getPath");							// Address & Value Length
	static stream<metadataWord>				metadataBuffer("vsMetadataBuffer");
	static stream<ap_uint<64> >				keyBuffer("vsKeyBuffer");
	static stream<ap_uint<1> >				filterPopSet("filterPopSet");
	static stream<ap_uint<1> >				filterPopGet("filterPopGet");
	static stream<pipelineWord> 			accCtrl2demux("accCtrl2demux");

	#pragma HLS DATA_PACK 	variable=demux2setPathValue
	#pragma HLS DATA_PACK 	variable=demux2setPathMetadata
	#pragma HLS DATA_PACK 	variable=demux2getPath
	#pragma HLS DATA_PACK 	variable=metadataBuffer
	#pragma HLS DATA_PACK 	variable=accCtrl2demux

	#pragma HLS STREAM variable=demux2setPathValue 		depth=96
	#pragma HLS STREAM variable=getPath2remux 			depth=96
	#pragma HLS STREAM variable=demux2setPathMetadata 	depth=16
	#pragma HLS STREAM variable=demux2getPath 			depth=16
	#pragma HLS STREAM variable=metadataBuffer 			depth=24
	#pragma HLS STREAM variable=keyBuffer 				depth=48
	#pragma HLS STREAM variable=filterPopGet			depth=16
	#pragma HLS STREAM variable=filterPopSet			depth=16
	#pragma HLS STREAM variable=accCtrl2demux			depth=16//4

	accessControl(inData, accCtrl2demux,  filterPopSet, filterPopGet);
	demux(accCtrl2demux, demux2setPathValue, demux2setPathMetadata, demux2getPath, metadataBuffer, keyBuffer);
	//demux(inData, demux2setPathValue, demux2setPathMetadata, demux2getPath, metadataBuffer, keyBuffer);
	setPath(demux2setPathMetadata, demux2setPathValue, memWrCmd, memWrData, filterPopSet);
	//setPathNoFilter(demux2setPathMetadata, demux2setPathValue, memWrCmd, memWrData);
	getPath(demux2getPath, getPath2remux, memRdCmd, memRdData, filterPopGet);
	//getPathNoFilter(demux2getPath, getPath2remux, memRdCmd, memRdData);
	remux(getPath2remux, keyBuffer, metadataBuffer, outData);
}
