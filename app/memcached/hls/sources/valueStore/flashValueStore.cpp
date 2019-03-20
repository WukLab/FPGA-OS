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

void flashAccessControl(stream<pipelineWord> &inData, stream<pipelineWord> &accCtrl2demux, stream<ap_uint<1> > &filterPopSet, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE region
	#pragma HLS pipeline II=1 enable_flush

	static enum faState{FACC_IDLE = 0, FACC_EVAL, FACC_QRD, FACC_POP, FACC_POP_WAIT, FACC_STREAM, FACC_WAIT, FACC_PUSH} flashAccState;
	static accessFilter 		flashAccessCtrl;
	static pipelineWord 		flashAccCtrlInputWord 	= {0, 0, 0, 0, 0, 0, 0};
	static accessWord 			flashPushWord 			= {0, 0, 1};
	static stream<ap_uint<2> >	flashFilterSeq;									// This stream stores the order of the operations to be read from the two pop queues.
	static ap_uint<2>			flashStreamToPop		= 2;					// Indicates which stream is to be popped next


	#pragma HLS STREAM variable=flashFilterSeq	depth=16

	switch(flashAccState) {
		case FACC_IDLE:
		{
			if (flashStreamToPop == 1 && !filterPopSet.empty() )							// If the next operation to pop is a set and a SET has been completed...
				flashAccState = FACC_POP;													// then move to ACC_POP and extract it from the queue
			else if (flashStreamToPop == 0 && !filterPopGet.empty())						// Same thing for a get
				flashAccState = FACC_POP;
			else {																	// If not
				if (!inData.empty() && !flashFilterSeq.full()) {							// Check if there's new data at the input AND if the pop order queue is not full
					inData.read(flashAccCtrlInputWord);
					if (flashAccCtrlInputWord.metadata.bit(112) == 1 || flashAccCtrlInputWord.metadata.range(111, 104) == 8 || flashAccCtrlInputWord.metadata.range(111, 104) == 4) {	// If this is a failed operation, a FLUSH or a DEL just stream it through as it does not affect the pipeline
						accCtrl2demux.write(flashAccCtrlInputWord);
						flashAccState = FACC_STREAM;
					}
					else {
						flashPushWord.address 		= flashAccCtrlInputWord.metadata.range(103, 72);
						flashPushWord.operation 	= flashAccCtrlInputWord.metadata.range(111, 104);
						flashFilterSeq.write(flashAccCtrlInputWord.metadata.bit(104));
						flashAccState = FACC_EVAL;
					}
				}
			}
			break;
		}
		case FACC_EVAL:
		{
			if (!flashAccessCtrl.compare(flashPushWord) && !flashAccessCtrl.full())
				flashAccState = FACC_PUSH;
			else {
				if (flashStreamToPop == 2)
					flashAccState = FACC_QRD;
				else
					flashAccState = FACC_WAIT;
			}
			break;
		}
		case FACC_QRD:
		{
			flashFilterSeq.read(flashStreamToPop);
			flashAccState = FACC_WAIT;
			break;
		}
		case FACC_PUSH:
		{
			if (flashStreamToPop == 2 && !flashFilterSeq.empty())
				flashFilterSeq.read(flashStreamToPop);
			flashAccessCtrl.push(flashPushWord);
			accCtrl2demux.write(flashAccCtrlInputWord);
			flashAccState = FACC_STREAM;
			break;
		}
		case FACC_STREAM:
		{
			inData.read(flashAccCtrlInputWord);
			accCtrl2demux.write(flashAccCtrlInputWord);
			if (flashAccCtrlInputWord.EOP == 1)
				flashAccState = FACC_IDLE;
			break;
		}
		case FACC_WAIT:
		{
			if (flashStreamToPop == 1 && !filterPopSet.empty() )
				flashAccState = FACC_POP_WAIT;
			else if (flashStreamToPop == 0 && !filterPopGet.empty())
				flashAccState = FACC_POP_WAIT;
			else {
				if (!flashAccessCtrl.compare(flashPushWord) && !flashAccessCtrl.full())
					flashAccState = FACC_PUSH;
			}
			break;
		}
		case FACC_POP_WAIT:
		{
			if (flashStreamToPop == 1)
				ap_uint<1> tempPop = filterPopSet.read();
			else if (flashStreamToPop == 0)
				ap_uint<1> tempPop = filterPopGet.read();
			if (!flashFilterSeq.empty())
				flashFilterSeq.read(flashStreamToPop);
			else
				flashStreamToPop = 2;
			flashAccessCtrl.pop();
			flashAccState = FACC_WAIT;
			break;
		}
		case FACC_POP:
		{
			if (flashStreamToPop == 1)
				ap_uint<1> tempPop = filterPopSet.read();
			else if (flashStreamToPop == 0)
				ap_uint<1> tempPop = filterPopGet.read();
			if (!flashFilterSeq.empty())
				flashFilterSeq.read(flashStreamToPop);
			else
				flashStreamToPop = 2;
			flashAccessCtrl.pop();
			flashAccState = FACC_IDLE;
			break;
		}
	}
}

void flashDemux(stream<pipelineWord> &accCtrl2demux, stream<internalWord>	&setValueIn, stream<flashValueStoreInternalWordMd>	&setMetadata, stream<flashValueStoreInternalWordMd>	&getMetadata, stream<metadataWord>	&metadataBuffer, stream<ap_uint<64> > &keyBuffer) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum fdState{FDMUX_IDLE = 0, FDMUX_SET, FDMUX_STREAM} flashDemuxState;
	static ap_uint<16>	flashDemuxValueLength 	= 0;
	static pipelineWord flashDemuxInputWord 	= {0, 0, 0, 0, 0, 0, 0};
	static ap_uint<2> 	flashWordCounter 		= 0;

	switch(flashDemuxState)	{
		case FDMUX_IDLE:
		{
			if (!accCtrl2demux.empty()) {
				accCtrl2demux.read(flashDemuxInputWord);
				if(flashDemuxInputWord.SOP == 1) {
					flashWordCounter = 1;
					if (flashDemuxInputWord.metadata.bit(112) == 1 || flashDemuxInputWord.metadata.range(111, 104) == 8 || flashDemuxInputWord.metadata.range(111, 104) == 4) {	// If this is a failed GET/SET or a DELETE or a FLUSH
						metadataWord metadataWrWord = {flashDemuxInputWord.metadata, flashDemuxInputWord.SOP, flashDemuxInputWord.keyValid, flashDemuxInputWord.valueValid, flashDemuxInputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						if (flashDemuxInputWord.keyValid == 1 && flashDemuxInputWord.metadata.range(111, 104) != 8)
							keyBuffer.write(flashDemuxInputWord.key);
						flashDemuxState = FDMUX_STREAM;
					}
					else if (flashDemuxInputWord.metadata.range(111, 104) == 0)	{	// If this is a GET operation
						metadataWord metadataWrWord = {flashDemuxInputWord.metadata, flashDemuxInputWord.SOP, flashDemuxInputWord.keyValid, flashDemuxInputWord.valueValid, flashDemuxInputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						flashValueStoreInternalWordMd	getMd = {flashDemuxInputWord.metadata.range(72+flashMemAddressWidth, 72), flashDemuxInputWord.metadata.range(23, 8)};
						getMetadata.write(getMd);
						if (flashDemuxInputWord.keyValid == 1)
							keyBuffer.write(flashDemuxInputWord.key);
						flashDemuxState = FDMUX_STREAM;
					}
					else if (flashDemuxInputWord.metadata.range(111, 104) == 1)	{	// or if finally this is a SET operation
						metadataWord metadataWrWord = {flashDemuxInputWord.metadata, flashDemuxInputWord.SOP, flashDemuxInputWord.keyValid, flashDemuxInputWord.valueValid, flashDemuxInputWord.EOP};
						metadataBuffer.write(metadataWrWord);
						flashValueStoreInternalWordMd	setMd = {flashDemuxInputWord.metadata.range(72+flashMemAddressWidth, 72), flashDemuxInputWord.metadata.range(23, 8)};
						setMetadata.write(setMd);
						internalWord setData = {flashDemuxInputWord.value, 1, 0};
						flashDemuxValueLength = flashDemuxInputWord.metadata(23, 8);
						if (flashDemuxInputWord.metadata(23, 8) < 9)  /////////// issue was here ///////////////////
							setData.EOP = 1;
						else
							flashDemuxValueLength -= 8;
						setValueIn.write(setData);
						if (flashDemuxInputWord.keyValid == 1)
							keyBuffer.write(flashDemuxInputWord.key);
						flashDemuxState = FDMUX_SET;
					}
				}
			}
			break;
		}
		case FDMUX_STREAM:
		{
			if(!accCtrl2demux.empty()) {
				accCtrl2demux.read(flashDemuxInputWord);
				metadataWord metadataWrWord = {flashDemuxInputWord.metadata, flashDemuxInputWord.SOP, flashDemuxInputWord.keyValid, flashDemuxInputWord.valueValid, flashDemuxInputWord.EOP};
				if (flashWordCounter < 2) {
					metadataBuffer.write(metadataWrWord);
					flashWordCounter++;
				}
				if (flashDemuxInputWord.keyValid == 1)
					keyBuffer.write(flashDemuxInputWord.key);
				if (flashDemuxInputWord.EOP == 1)
					flashDemuxState = FDMUX_IDLE;
			}
			break;
		}
		case FDMUX_SET:
		{
			accCtrl2demux.read(flashDemuxInputWord);
			metadataWord metadataWrWord = {flashDemuxInputWord.metadata, flashDemuxInputWord.SOP, flashDemuxInputWord.keyValid, flashDemuxInputWord.valueValid, flashDemuxInputWord.EOP};
			if (flashWordCounter < 2) {
				metadataBuffer.write(metadataWrWord);
				flashWordCounter++;
			}
			if (flashDemuxInputWord.keyValid == 1)
				keyBuffer.write(flashDemuxInputWord.key);
			internalWord setData = {flashDemuxInputWord.value, 0, 0};
			if (flashDemuxValueLength < 9)
				setData.EOP = 1;
			else
				flashDemuxValueLength -= 8;
			if (flashDemuxInputWord.valueValid == 1)
				setValueIn.write(setData);
			if (flashDemuxInputWord.EOP == 1)
				flashDemuxState = FDMUX_IDLE;
			break;
		}
	}
}


void flashRemux(stream<ap_uint<64> >	&getPath2remux, stream<ap_uint<64> > &keyBuffer, stream<metadataWord>	&metadataBuffer, stream<pipelineWord> &outData) {
	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum frmState{FRMUX_IDLE = 0, FRMUX_OPCODECHECK, FRMUX_REST_MD1, FRMUX_REST_MD2, FRMUX_GET_REST, FRMUX_GET_MD1, FRMUX_GET_MD2, FRMUX_REST_REST} flashRemuxState;
	static metadataWord flashRmMdBuffer 		= {0, 0, 0, 0, 0};
	static uint8_t 		flashRmKeyLength		= 0;
	static uint16_t		flashRmValueLength 		= 0;
	pipelineWord		flashOutputWord			= {0, 0, 0, 0, 0, 0, 0};

	switch(flashRemuxState) {
		case FRMUX_IDLE:
		{
			if (!metadataBuffer.empty()) {
				metadataBuffer.read(flashRmMdBuffer);
				if (flashRmMdBuffer.SOP == 1) {
					flashRmKeyLength = flashRmMdBuffer.metadata.range(7, 0);
					flashRemuxState = FRMUX_OPCODECHECK;
				}
			}
		case FRMUX_OPCODECHECK:
		{
			if (flashRmMdBuffer.metadata.range(119, 112) == 1 || flashRmMdBuffer.metadata.range(111, 104) == 8 || flashRmMdBuffer.metadata.range(111, 104) == 4 || flashRmMdBuffer.metadata.range(111, 104) == 1) {
				if (flashRmKeyLength > 0) {	// If there is a key present
					if (!keyBuffer.empty()) {
						keyBuffer.read(flashOutputWord.key);		// Read it
						flashOutputWord.keyValid = 1;
						flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
						flashOutputWord.SOP = 1;
						flashOutputWord.metadata = flashRmMdBuffer.metadata;
						flashRemuxState = FRMUX_REST_MD1;
						outData.write(flashOutputWord);
					}
				}
				else {
					flashOutputWord.SOP = 1;
					flashOutputWord.metadata = flashRmMdBuffer.metadata;
					flashRemuxState = FRMUX_REST_MD1;
					outData.write(flashOutputWord);
				}
			}
			else if (flashRmMdBuffer.metadata.range(111, 104) == 0 && !getPath2remux.empty()) {
				if (flashRmKeyLength > 0) {	// If there is a key present
					keyBuffer.read(flashOutputWord.key);							// Read it
					flashOutputWord.keyValid = 1;
					flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
				}
				flashRmValueLength = flashRmMdBuffer.metadata.range(23, 8);
				flashRmValueLength > 7 ? flashRmValueLength -= 8 : flashRmValueLength = 0;
				flashOutputWord.value = getPath2remux.read();
				flashOutputWord.valueValid = 1;
				flashOutputWord.SOP = 1;
				flashOutputWord.metadata = flashRmMdBuffer.metadata;
				flashRemuxState = FRMUX_GET_MD1;
				outData.write(flashOutputWord);
			}
		}
		break;
		}
		case FRMUX_REST_MD1:
		{
			if (!metadataBuffer.empty()) {
				metadataBuffer.read(flashRmMdBuffer);
				if (flashRmKeyLength > 0) { 		// If there is a key present
					if (!keyBuffer.empty())	{
						keyBuffer.read(flashOutputWord.key);		// Read it
						flashOutputWord.keyValid = 1;
						flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
						flashOutputWord.metadata = flashRmMdBuffer.metadata;
						if (flashRmKeyLength > 0)
							flashRemuxState = FRMUX_REST_REST;
						else {
							flashOutputWord.EOP = 1;
							flashRemuxState = FRMUX_IDLE;
						}
						outData.write(flashOutputWord);
					}
				}
				else {
					flashOutputWord.metadata = flashRmMdBuffer.metadata;
					flashOutputWord.EOP 		= 1;
					flashRemuxState	 		= FRMUX_IDLE;
					outData.write(flashOutputWord);
				}
			}
			break;
		}
		case FRMUX_REST_REST:
		{
			if (flashRmKeyLength > 0) { // If there is a key present
				if (!keyBuffer.empty()) {
					keyBuffer.read(flashOutputWord.key);		// Read it
					flashOutputWord.keyValid = 1;
					flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
					if (flashRmKeyLength == 0) {
						flashOutputWord.EOP = 1;
						flashRemuxState = FRMUX_IDLE;
					}
					outData.write(flashOutputWord);
				}
			}
			break;
		}
		case FRMUX_GET_MD1:
		{
			if (!metadataBuffer.empty() && (!(flashRmKeyLength > 0) || (flashRmKeyLength > 0 && !keyBuffer.empty())) && (!(flashRmValueLength > 0) || (flashRmValueLength > 0 && !getPath2remux.empty())))  {
				metadataBuffer.read(flashRmMdBuffer);
				if (flashRmKeyLength > 0) { // If there is a key present
					flashOutputWord.key 		= keyBuffer.read();							// Read it
					flashOutputWord.keyValid = 1;
					flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
				}
				if (flashRmValueLength > 0) {
					flashOutputWord.value = getPath2remux.read();
					flashOutputWord.valueValid = 1;
					flashRmValueLength > 7 ? flashRmValueLength -= 8 : flashRmValueLength = 0;
				}
				flashOutputWord.metadata = flashRmMdBuffer.metadata;
				if (flashRmValueLength == 0 && flashRmKeyLength == 0) {
					flashOutputWord.EOP = 1;
					flashRemuxState = FRMUX_IDLE;
				}
				else
					flashRemuxState = FRMUX_GET_REST;
				outData.write(flashOutputWord);
			}
			break;
		}
		case FRMUX_GET_REST:
		{
			if ((!(flashRmKeyLength > 0) || (flashRmKeyLength > 0 && !keyBuffer.empty())) && (!(flashRmValueLength > 0) || (flashRmValueLength > 0 && !getPath2remux.empty()))) {
				if (flashRmKeyLength > 0) {												// If there is a key present
					flashOutputWord.key 		= keyBuffer.read();							// Read it
					flashOutputWord.keyValid = 1;
					flashRmKeyLength > 7 ? flashRmKeyLength -= 8: flashRmKeyLength = 0;
				}
				if (flashRmValueLength > 0) {
					flashOutputWord.value = getPath2remux.read();
					flashOutputWord.valueValid = 1;
					flashRmValueLength > 7 ? flashRmValueLength -= 8 : flashRmValueLength = 0;
				}
				if (flashRmValueLength == 0 && flashRmKeyLength == 0)	{
					flashOutputWord.EOP = 1;
					flashRemuxState = FRMUX_IDLE;
				}
				outData.write(flashOutputWord);
			}
			break;
		}
	}
}

void flashSetPathNoFilter(stream<flashValueStoreInternalWordMd>	&setMetadata, stream<internalWord>	&setValueIn, stream<flashMemCtrlWord> &memWrCmd, stream<ap_uint<64> > &memWrData) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static flashValueStoreInternalWordMd 	flashSetMdBuffer	= {0, 0};
	internalWord							flashSetInputWord		= {0, 0, 0};
	static ap_uint<64>						flashSetValueBuffer 	= 0;
	static uint8_t							flashCounter			= 0;
	static uint16_t							flashSetNumOfWords		= 0;
	static enum fsState{SET_IDLE = 0, SET_ACC} flashSetState;

	switch(flashSetState)
	{
		case SET_IDLE:
		{
			if (!setMetadata.empty() && !setValueIn.empty()) {
				setMetadata.read(flashSetMdBuffer);
				flashSetNumOfWords = flashSetMdBuffer.length / 8;
				if (flashSetMdBuffer.length > (flashSetNumOfWords*8))
					flashSetNumOfWords++;
				setValueIn.read(flashSetInputWord);
				if (flashSetInputWord.SOP == 1) {
					flashMemCtrlWord setCtrlWord = {flashSetMdBuffer.address, flashSetNumOfWords};
					memWrCmd.write(setCtrlWord);
					memWrData.write(flashSetInputWord.data);
					flashSetState = SET_ACC;
				}
			}
			break;
		}
		case SET_ACC:
		{
			if (!setValueIn.empty()) {
				setValueIn.read(flashSetInputWord);
				memWrData.write(flashSetInputWord.data);
				if (flashSetInputWord.EOP == 1) {
					//filterPop.write(1);
					flashSetState = SET_IDLE;
				}
			}
			break;
		}
	}
}

void flashSetPath(stream<flashValueStoreInternalWordMd>	&setMetadata, stream<internalWord>	&setValueIn, stream<flashMemCtrlWord> &memWrCmd, stream<ap_uint<64> > &memWrData, stream<ap_uint<1> > &filterPop) {

	#pragma HLS INTERFACE ap_ctrl_none port=return

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static flashValueStoreInternalWordMd 	flashSetMdBuffer	= {0, 0};
	internalWord							flashSetInputWord		= {0, 0, 0};
	static ap_uint<64>						flashSetValueBuffer 	= 0;
	static uint8_t							flashCounter			= 0;
	static uint16_t							flashSetNumOfWords		= 0;
	static enum fsState{SET_IDLE = 0, SET_ACC} flashSetState;

	switch(flashSetState)
	{
		case SET_IDLE:
		{
			if (!setMetadata.empty() && !setValueIn.empty()) {
				setMetadata.read(flashSetMdBuffer);
				flashSetNumOfWords = flashSetMdBuffer.length / 8;
				if (flashSetMdBuffer.length > (flashSetNumOfWords*8))
					flashSetNumOfWords++;
				setValueIn.read(flashSetInputWord);
				if (flashSetInputWord.SOP == 1) {
					flashMemCtrlWord setCtrlWord = {flashSetMdBuffer.address, flashSetNumOfWords};
					memWrCmd.write(setCtrlWord);
					memWrData.write(flashSetInputWord.data);
					flashSetState = SET_ACC;
				}
			}
			break;
		}
		case SET_ACC:
		{
			if (!setValueIn.empty()) {
				setValueIn.read(flashSetInputWord);
				memWrData.write(flashSetInputWord.data);
				if (flashSetInputWord.EOP == 1) {
					filterPop.write(1);
					flashSetState = SET_IDLE;
				}
			}
			break;
		}
	}
}

void flashDispatch(stream<flashValueStoreInternalWordMd>	&getMetadata, stream<ap_uint<16> > &valueLengthQ, stream<flashMemCtrlWord> &memRdCmd) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	flashValueStoreInternalWordMd 	getMdBuffer			= {0, 0};
	static uint16_t					flashGetNumOfWords	= 0;

	if (!getMetadata.empty())
	{
		getMetadata.read(getMdBuffer);
		flashGetNumOfWords = getMdBuffer.length / 8;
		if (getMdBuffer.length > (flashGetNumOfWords*8))
			flashGetNumOfWords++;
		flashMemCtrlWord getCtrlWord = {getMdBuffer.address, flashGetNumOfWords};
		memRdCmd.write(getCtrlWord);
		valueLengthQ.write(getMdBuffer.length);
	}
}

void flashReceiveNoFilter(stream<ap_uint<16> > &valueLengthQ, stream<ap_uint<64> > &memRdData, stream<ap_uint<64> >	&getValueOut) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum fgState {GET_IDLE, GET_ACC} flashGetState;
	static	ap_uint<64>			memInputWord 	= 0;
	static  ap_uint<16> 		getValueLength 	= 0;
	static	uint8_t				getCounter		= 0;

	switch(flashGetState) {
		case GET_IDLE:
		{
			if(!valueLengthQ.empty() && !memRdData.empty())	{
				valueLengthQ.read(getValueLength);
				getValueOut.write(memRdData.read());
				getValueLength -= 8;
				getCounter++;
				flashGetState = GET_ACC;
			}
			break;
		}
		case GET_ACC:
		{
			if (!memRdData.empty()) {
				getValueOut.write(memRdData.read());
				getValueLength > 7 ? getValueLength -= 8 : getValueLength = 0;
				if (getValueLength == 0) {
//					filterPopGet.write(1);
					flashGetState = GET_IDLE;
					getCounter = 0;
				}
			}
			break;
		}
	}
}

void flashReceive(stream<ap_uint<16> > &valueLengthQ, stream<ap_uint<64> > &memRdData, stream<ap_uint<64> >	&getValueOut, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum fgState {GET_IDLE, GET_ACC} flashGetState;
	static	ap_uint<64>			memInputWord 	= 0;
	static  ap_uint<16> 		getValueLength 	= 0;
	static	uint8_t				getCounter		= 0;

	switch(flashGetState) {
		case GET_IDLE:
		{
			if(!valueLengthQ.empty() && !memRdData.empty())	{
				valueLengthQ.read(getValueLength);
				getValueOut.write(memRdData.read());
				getValueLength -= 8;
				getCounter++;
				flashGetState = GET_ACC;
			}
			break;
		}
		case GET_ACC:
		{
			if (!memRdData.empty()) {
				getValueOut.write(memRdData.read());
				getValueLength > 7 ? getValueLength -= 8 : getValueLength = 0;
				if (getValueLength == 0) {
					filterPopGet.write(1);
					flashGetState = GET_IDLE;
					getCounter = 0;
				}
			}
			break;
		}
	}
}

void flashGetPathNoFilter(stream<flashValueStoreInternalWordMd>	&getMetadata, stream<ap_uint<64> >	&getValueOut, stream<flashMemCtrlWord> &memRdCmd, stream<ap_uint<64> > &memRdData) {
	#pragma HLS INLINE

	static stream<ap_uint<16> >		flash_Disp2rec;							// Internal queue to store the value length of the value to be received from the memory

	#pragma HLS STREAM variable=flash_Disp2rec 	depth=16

	flashDispatch(getMetadata, flash_Disp2rec, memRdCmd);
	flashReceiveNoFilter(flash_Disp2rec, memRdData, getValueOut);// Receives the get metadata from the demux and dispatches the read request to the memory
//	flashReceive(flash_Disp2rec, memRdData, getValueOut, filterPopGet);		// Waits for data from the memory, read them and converts them to 64-bit words. Also pops the respective get from the access control upon completion.
}

void flashGetPath(stream<flashValueStoreInternalWordMd>	&getMetadata, stream<ap_uint<64> >	&getValueOut, stream<flashMemCtrlWord> &memRdCmd, stream<ap_uint<64> > &memRdData, stream<ap_uint<1> > &filterPopGet) {
	#pragma HLS INLINE

	static stream<ap_uint<16> >		flash_Disp2rec;							// Internal queue to store the value length of the value to be received from the memory

	#pragma HLS STREAM variable=flash_Disp2rec 	depth=16

	flashDispatch(getMetadata, flash_Disp2rec, memRdCmd);					// Receives the get metadata from the demux and dispatches the read request to the memory
	flashReceive(flash_Disp2rec, memRdData, getValueOut, filterPopGet);		// Waits for data from the memory, read them and converts them to 64-bit words. Also pops the respective get from the access control upon completion.
}

void valueStoreFlash(stream<pipelineWord> &inData, stream<flashMemCtrlWord> &memRdCmd, stream<ap_uint<64> > &memRdData, stream<flashMemCtrlWord> &memWrCmd, stream<ap_uint<64> > &memWrData, stream<pipelineWord> &outData) {

	#pragma HLS INTERFACE	 ap_ctrl_none 		port=return

	#pragma HLS INLINE

	static stream<internalWord>						flashDemux2setPathValue("flashDemux2setPathValue");
	static stream<ap_uint<64> >						flashGetPath2remux("flashGetPath2remux");
	static stream<flashValueStoreInternalWordMd>	flashDemux2setPathMetadata("flashDemux2setPathMetadata");			// Address & Value Length
	static stream<flashValueStoreInternalWordMd>	flashDemux2getPath("flashDemux2getPath");							// Address & Value Length
	static stream<metadataWord>						flashMetadataBuffer("flashMetadataBuffer");
	static stream<ap_uint<64> >						flashKeyBuffer("flashKeyBuffer");
	static stream<ap_uint<1> >						flashFilterPopSet("flashFilterPopSet");
	static stream<ap_uint<1> >						flashFilterPopGet("flashFilterPopGet");
	static stream<pipelineWord> 					flashAccCtrl2demux("flashAccCtrl2demux");

	#pragma HLS DATA_PACK 	variable=flashDemux2setPathValue
	#pragma HLS DATA_PACK 	variable=flashDemux2setPathMetadata
	#pragma HLS DATA_PACK 	variable=flashDemux2getPath
	#pragma HLS DATA_PACK 	variable=flashMetadataBuffer
	#pragma HLS DATA_PACK 	variable=flashAccCtrl2demux

	#pragma HLS STREAM variable=flashDemux2setPathValue 	depth=96
	#pragma HLS STREAM variable=flashGetPath2remux 			depth=96
	#pragma HLS STREAM variable=flashDemux2setPathMetadata 	depth=16
	#pragma HLS STREAM variable=flashDemux2getPath 			depth=16
	#pragma HLS STREAM variable=flashMetadataBuffer 		depth=24
	#pragma HLS STREAM variable=flashKeyBuffer 				depth=48
	#pragma HLS STREAM variable=flashFilterPopSet			depth=16
	#pragma HLS STREAM variable=flashFilterPopGet			depth=16
	#pragma HLS STREAM variable=flashAccCtrl2demux			depth=4

	//flashAccessControl(inData, flashAccCtrl2demux,  flashFilterPopSet, flashFilterPopGet);
	//flashDemux(flashAccCtrl2demux, flashDemux2setPathValue, flashDemux2setPathMetadata, flashDemux2getPath, flashMetadataBuffer, flashKeyBuffer);
	flashDemux(inData, flashDemux2setPathValue, flashDemux2setPathMetadata, flashDemux2getPath, flashMetadataBuffer, flashKeyBuffer);
	//flashSetPath(flashDemux2setPathMetadata, flashDemux2setPathValue, memWrCmd, memWrData, flashFilterPopSet);
	flashSetPathNoFilter(flashDemux2setPathMetadata, flashDemux2setPathValue, memWrCmd, memWrData);
	//flashGetPath(flashDemux2getPath, flashGetPath2remux, memRdCmd, memRdData, flashFilterPopGet);
	flashGetPathNoFilter(flashDemux2getPath, flashGetPath2remux, memRdCmd, memRdData);
	flashRemux(flashGetPath2remux, flashKeyBuffer, flashMetadataBuffer, outData);
}
