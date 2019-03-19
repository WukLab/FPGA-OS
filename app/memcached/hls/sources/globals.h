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
#ifndef _GLOBALS_H
#define _GLOBALS_H

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>
#include <math.h>
#include <hls_stream.h>
#include "ap_int.h"
#include <stdint.h>
#include <vector>
//#include "ap_cint.h"

using namespace hls;

#define splitLength	2048
#define noOfFlashMemLocations 131072

#define noOfFlashAddresses 32
#define	maxFlashValueSize 63536
#define flashBytesPerDataWord 8

#define noOfDramAddresses 64
#define	maxDramValueSize 1024
#define dramBytesPerDataWord 64

const uint16_t	noOfMemLocations		= 2048;


const int qDepth 						= 8;			// Number of packets that are to be stored in each queue
const int maxValueSize					= 65536;	// Max. supported value size in bytes
const int maxKeySize 					= 128;		// Max supported key size in bytes
const int valueBusWidth					= 8;
const int keyBusWidth 					= 8;
const unsigned short int memIntWidth 	= 512;
const uint8_t	noOfBins 				= 4;
const uint8_t 	bitsPerBin				= 128;
const uint8_t 	words2aggregate 		= 2;
const uint8_t 	concFilterEntries		= 8;
const uint8_t 	accFilterEntries		= 8;
const uint8_t	dramMemAddressWidth		= 32;
const uint8_t	flashMemAddressWidth	= 32;
const uint8_t	noOfHashTableEntries	= 10;
const uint32_t	hashFunctionSeed		= 13;
const bool 		bramOrDram				= false;	// False is BRAM, True is DRAM

struct extMemCtrlWord {
	ap_uint<dramMemAddressWidth> 	address;
	ap_uint<6>						count;
	ap_uint<1>						rdOrWr;
};

struct flashExtMemCtrlWord {
	ap_uint<flashMemAddressWidth> 	address;
	ap_uint<13>						count;
	ap_uint<1>						rdOrWr;
};

struct ioWord {
	ap_uint<64>		data;
	ap_uint<2>		mod;
	ap_uint<1>		eop;
	ap_uint<1>		sop;
	ap_uint<112>	metadata;
};

struct extendedAxiWord {
	ap_uint<64>		data;
	ap_uint<112>	user;
	ap_uint<8>		keep;
	ap_uint<1>		last;
};

struct pipelineWord {
	ap_uint<124>	metadata;
	ap_uint<1>		SOP;
	ap_uint<1>		keyValid;
	ap_uint<1>		valueValid;
	ap_uint<1>		EOP;
	ap_uint<64>		value;
	ap_uint<64>		key;
};

struct internalWord {
	ap_uint<64> data;
	ap_uint<1>	SOP;
	ap_uint<1>	EOP;
};

struct hashTableInternalWord {
	ap_uint<64*words2aggregate> data;
	ap_uint<1>	SOP;
	ap_uint<1>	EOP;
};

#define rot(x,k) (((x)<<(k)) | ((x)>>(32-(k))))

struct metadataWord {
	ap_uint<124>	metadata;
	ap_uint<1>		SOP;
	ap_uint<1>		keyValid;
	ap_uint<1>		valueValid;
	ap_uint<1>		EOP;
};

struct internalMdWord {
	ap_uint<8> 	operation;
	ap_uint<32> metadata;
	ap_uint<8>	keyLength;				// The key length here is stored in 192-bit words.
	ap_uint<16>	valueLength;
};

struct valueStoreInternalWordMd {
	ap_uint<dramMemAddressWidth> 	address;
	ap_uint<13> 					length;
};

struct flashValueStoreInternalWordMd {
	ap_uint<flashMemAddressWidth> address;
	ap_uint<16> length;
};

struct memCtrlWord {
	ap_uint<dramMemAddressWidth> 	address;
	ap_uint<8>						count;
};

struct flashMemCtrlWord {
	ap_uint<flashMemAddressWidth> 	address;
	ap_uint<13>						count;
};

struct binStatus {
	ap_uint<1> free;
	ap_uint<1> match;
};
struct comp2decWord {
	binStatus	bin[noOfBins];
};
struct decideResultWord {
	ap_uint<32> address;
	ap_uint<16> valueLength;
	ap_uint<8>	operation;
	ap_uint<1>	status;
};

struct ccWord {
	ap_uint<noOfHashTableEntries-4> 	address;
	ap_uint<16> 						valueLength;
	ap_uint<8>							operation;
	ap_uint<1>							status;
};

class concurrencyFilter {
private:
	uint8_t		wrPtr;
	uint8_t		rdPtr;
	uint8_t		level;
	ccWord filterEntries[concFilterEntries];
public:
	concurrencyFilter();
	//decideResultWord filterEntries[concFilterEntries];
	bool full();									// Returns true if the filter is full
	bool push(ccWord newElement);			// Returns true if write completed successfully, else false
	bool pop();										// Returns true if read completed successfully, else false
	bool compare(ccWord compareElement);	// Compares the provided data with the contents of the filter and returns true if the entry should be blocked, false if not
};

struct accessWord {
	ap_uint<32> address;
	ap_uint<8>	operation;
	ap_uint<1>	status;
};

class accessFilter {
private:
	uint8_t		wrPtr;
	uint8_t		rdPtr;
	uint8_t		level;
	accessWord 	filterEntries[accFilterEntries];
public:
	accessFilter();
	bool full();
	bool push(accessWord newElement);			// Returns true if write completed successfully, else false
	bool pop();										// Returns true if read completed successfully, else false
	bool compare(accessWord compareElement);	// Compares the provided data with the contents of the filter and returns true if the entry should be blocked, false if not
};

ap_uint<32> byteSwap32(ap_uint<32> inputVector);
ap_uint<16> byteSwap16(ap_uint<16> inputVector);

int myPow(const short int &exp);

void memAccessHash(stream<extMemCtrlWord> &aggregateMemCmd, stream<ap_uint<512> > &rdDataOut, stream<ap_uint<512> > &wrDataIn);

void cmdAggregatorHash(stream<memCtrlWord> &rdCmdIn, stream<memCtrlWord> &wrCmdIn, stream<extMemCtrlWord> &aggregateMemCmd);

void bramModelHash(stream<memCtrlWord> &rdCmdIn, stream<ap_uint<512> > &rdDataOut, stream<memCtrlWord> &wrCmdIn, stream<ap_uint<512> > &wrDataIn);

void memAccessValueStore(stream<extMemCtrlWord> &aggregateMemCmd, stream<ap_uint<512> > &rdDataOut, stream<ap_uint<512> > &wrDataIn);

void cmdAggregatorValueStore(stream<memCtrlWord> &rdCmdIn, stream<memCtrlWord> &wrCmdIn, stream<extMemCtrlWord> &aggregateMemCmd);

void bramModelValueStore(stream<memCtrlWord> &rdCmdIn, stream<ap_uint<512> > &rdDataOut, stream<memCtrlWord> &wrCmdIn, stream<ap_uint<512> > &wrDataIn);

void flashMemAccessValueStore(stream<flashExtMemCtrlWord> &aggregateMemCmd, stream<ap_uint<64> > &rdDataOut, stream<ap_uint<64> > &wrDataIn);

void flashCmdAggregatorValueStore(stream<flashMemCtrlWord> &rdCmdIn, stream<flashMemCtrlWord> &wrCmdIn, stream<flashExtMemCtrlWord> &aggregateMemCmd);

void flashBramModelValueStore(stream<flashMemCtrlWord> &rdCmdIn, stream<ap_uint<64> > &rdDataOut, stream<flashMemCtrlWord> &wrCmdIn, stream<ap_uint<64> > &wrDataIn);

void hash(stream<hashTableInternalWord> &in2hash, stream<ap_uint<8> > &in2hashKeyLength, stream<ap_uint<32> > &hash2cc);

void concurrencyControl(stream<hashTableInternalWord> &in2cc, stream<internalMdWord> &in2ccMd, stream<ap_uint<32> > &hash2cc, stream<hashTableInternalWord> &cc2memRead, stream<internalMdWord> &cc2memReadMd, stream<ap_uint<1> > &dec2cc);

void memRead(stream<hashTableInternalWord> &cc2memRead, stream<internalMdWord> &cc2memReadMd, stream<memCtrlWord> &memRdCtrl, stream<hashTableInternalWord> &memRd2comp, stream<internalMdWord> &memRd2compMd);

void ht_compare(stream<hashTableInternalWord> &memRd2comp, stream<internalMdWord> &memRd2compMd, stream<ap_uint<512> > &memRdData, stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd, stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData);

void memWrite(stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd, stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData,
			  stream<memCtrlWord> &memWrCtrl, stream<ap_uint<512> > &memWrData, stream<decideResultWord> &memWr2out, stream<ap_uint<1> > &memWr2cc,
			  stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone);

void hash(stream<ap_uint<64> > &in2hash, stream<ap_uint<8> > &in2hashKeyLength, stream<ap_uint<32> > &hash2cc);

void hashTable(stream<pipelineWord> &hashTableInData, stream<pipelineWord> &hashTableOutData,
			   stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemRdCtrl, stream<ap_uint<512> > &hashTableMemWrData, stream<memCtrlWord> &hashTableMemWrCtrl,
			   stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone);

void asciiResponse(stream<pipelineWord> &inData, stream<extendedAxiWord> &outData);

void binaryResponse(stream<pipelineWord> &inData_rf, stream<extendedAxiWord> &outData_rf);

void responseFormatter(stream<pipelineWord> &responseFormatterInData, stream<extendedAxiWord> &responseFormatterOutData);

void binaryParser(stream<extendedAxiWord> &inData, stream<pipelineWord> &outData);

void valueStoreDram(stream<pipelineWord> &valueStoreInData, stream<memCtrlWord> &valueStoreMemRdCmd, stream<ap_uint<512> > &valueStoreMemRdData, stream<memCtrlWord> &valueStoreMemWrCmd, stream<ap_uint<512> > &valueStoreMemWrData, stream<pipelineWord> &valueStoreOutData);

void valueStoreFlash(stream<pipelineWord> &valueStoreInData, stream<flashMemCtrlWord> &valueStoreMemRdCmd, stream<ap_uint<64> > &valueStoreMemRdData, stream<flashMemCtrlWord> &valueStoreMemWrCmd, stream<ap_uint<64> > &valueStoreMemWrData, stream<pipelineWord> &valueStoreOutData);

void splitter(stream<pipelineWord> &valueSplitterIn, stream<pipelineWord> &valueSplitterOut2valueStoreFlash, stream<pipelineWord> &valueSplitterOut2valueStoreDram);

void merger(stream<pipelineWord> &flash2valueMerger, stream<pipelineWord> &dram2valueMerger, stream<pipelineWord> &valueMerger2responseFormatter);

void memcachedPipeline(stream<extendedAxiWord> &inData, stream<extendedAxiWord> &outData,
					   stream<memCtrlWord> &dramValueStoreMemRdCmd, stream<ap_uint<512> > &dramValueStoreMemRdData, stream<memCtrlWord> &dramValueStoreMemWrCmd, stream<ap_uint<512> > &dramValueStoreMemWrData,
					   stream<flashMemCtrlWord> &flashValueStoreMemRdCmd, stream<ap_uint<64> > &flashValueStoreMemRdData, stream<flashMemCtrlWord> &flashValueStoreMemWrCmd, stream<ap_uint<64> > &flashValueStoreMemWrData,
					   stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemRdCmd, stream<ap_uint<512> > &hashTableMemWrData, stream<memCtrlWord> &hashTableMemWrCmd,
					   stream<ap_uint<32> > &addressReturnOut, stream<ap_uint<32> > &addressAssignDramIn, stream<ap_uint<32> > &addressAssignFlashIn, ap_uint<1> &flushReq, ap_uint<1> flushAck, ap_uint<1> &flushDone);

#endif
