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
#include "globals.h"

#define totalSimCycles	500000	// Defines how many additional C simulation cycles will be executed after the input file has been read in. Used to make sure all the request traverse the entire pipeline.

uint32_t cycleCounter;
unsigned int	simCycleCounter;

using namespace std;

void dummyPCIeJoint(stream<ap_uint<32> > &inData, stream<ap_uint<32> > &outDataFlash, stream<ap_uint<32> > &outDataDram, ap_uint<1> flushReq, ap_uint<1> &flushAck, ap_uint<1> flushDone){
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS pipeline II=1

	#pragma HLS RESOURCE 	variable=inData 		core=AXI4Stream
	#pragma HLS RESOURCE 	variable=outDataFlash 	core=AXI4Stream
	#pragma HLS RESOURCE 	variable=outDataDram 	core=AXI4Stream

	static stream<ap_uint<32> > freeAddressArrayFlash("freeAddressArrayFlash");
	static stream<ap_uint<32> > freeAddressArrayDram("freeAddressArrayDramDram");

	static bool			streamInitializedFlash 	= false;
	static ap_uint<16>	elementCounterFlash		= 0;
	static ap_uint<16>	elementCounterDram		= 0;
	static ap_uint<32> 	inputAddress 			= 0;
	static bool			flushFlag				= false;
	static ap_uint<1>	pcie_flushAck			= 0;

	//#pragma HLS STREAM variable=freeAddressArrayDram depth=64
	//#pragma HLS STREAM variable=freeAddressArrayFlash depth=32

	static enum pState{PCI_IDLE = 0, PCI_INIT_DRAM, PCI_INIT_FLASH, PCI_RECLAIM, PCI_RECLAIM_FLASH, PCI_RECLAIM_DRAM, PCI_ASSIGN_FLASH, PCI_ASSIGN_DRAM, PCI_FLUSH_DRAM, PCI_FLUSH_FLASH, PCI_WAITFORDONE} pcieState;

	switch(pcieState) {
			case PCI_IDLE:
				if (streamInitializedFlash == false)
					pcieState = PCI_INIT_DRAM;
				else if (flushReq == 1)
					pcieState = PCI_FLUSH_DRAM;
				else {
					if (!outDataFlash.full() && !freeAddressArrayFlash.empty())
						pcieState = PCI_ASSIGN_FLASH;
					else if (!outDataDram.full() && !freeAddressArrayDram.empty())
						pcieState = PCI_ASSIGN_DRAM;
					else if (!inData.empty())
						pcieState = PCI_RECLAIM;
				}
				break;
			case PCI_INIT_DRAM:
				pcie_flushAck = 0;
				if (elementCounterDram < noOfDramAddresses) {
					freeAddressArrayDram.write((maxDramValueSize/dramBytesPerDataWord)*elementCounterDram);
					elementCounterDram++;
				}
				else
					pcieState = PCI_INIT_FLASH;
				break;
			case PCI_INIT_FLASH:
				if (elementCounterFlash < noOfFlashAddresses) {
					freeAddressArrayFlash.write(((maxDramValueSize/dramBytesPerDataWord)*noOfDramAddresses) + ((maxFlashValueSize/flashBytesPerDataWord)*elementCounterFlash));
					elementCounterFlash++;
				}
				else {
					streamInitializedFlash = true;
					if (flushFlag == true) {
						flushFlag = false;
						pcieState = PCI_WAITFORDONE;
					}
					else
						pcieState = PCI_IDLE;
				}
				break;

			case PCI_RECLAIM:
				inputAddress = inData.read();
				if (inputAddress < ((maxDramValueSize/dramBytesPerDataWord)*noOfDramAddresses) && !freeAddressArrayDram.full())
					pcieState = PCI_RECLAIM_DRAM;
				else if (!freeAddressArrayFlash.full())
					pcieState = PCI_RECLAIM_FLASH;
				break;
			case PCI_RECLAIM_DRAM:
				freeAddressArrayDram.write(inputAddress);
				pcieState = PCI_IDLE;
				break;
			case PCI_RECLAIM_FLASH:
				freeAddressArrayFlash.write(inputAddress);
				pcieState = PCI_IDLE;
				break;
			case PCI_ASSIGN_FLASH:
				outDataFlash.write(freeAddressArrayFlash.read());
				pcieState = PCI_IDLE;
				break;
			case PCI_ASSIGN_DRAM:
				outDataDram.write(freeAddressArrayDram.read());
				pcieState = PCI_IDLE;
				break;
			case PCI_FLUSH_DRAM:
				if (!freeAddressArrayDram.empty())
					freeAddressArrayDram.read();
				else
					pcieState = PCI_FLUSH_FLASH;
				break;
			case PCI_FLUSH_FLASH:
				if (!freeAddressArrayFlash.empty())
					freeAddressArrayFlash.read();
				else {
					elementCounterDram = 0;
					elementCounterFlash = 0;
					pcie_flushAck = 1;
					flushFlag = true;
					pcieState = PCI_INIT_DRAM;
				}
				break;
			case PCI_WAITFORDONE:
				if (flushDone == 1)
					pcieState = PCI_IDLE;
				break;
		}
		flushAck = pcie_flushAck;


}

void memAccessHash(stream<extMemCtrlWord> &aggregateMemCmdHashTable, stream<ap_uint<512> > &hashTableMemRdData, stream<ap_uint<512> > &hashTableMemWrData)  {
	static ap_uint<512> memArrayHashTable[noOfMemLocations] = {0};

	static enum mState {MEM_IDLE = 0, MEM_ACCESS} memStateHashTable;
	static extMemCtrlWord inputWordHashTable = {0, 0, 0};

	switch(memStateHashTable) {
	case	MEM_IDLE:
		if (!aggregateMemCmdHashTable.empty()) {
			aggregateMemCmdHashTable.read(inputWordHashTable);
			memStateHashTable = MEM_ACCESS;
		}
		break;
	case	MEM_ACCESS:
		if (inputWordHashTable.rdOrWr == 0) {
			hashTableMemRdData.write(memArrayHashTable[inputWordHashTable.address]);
			//cerr << "InMem: " << hashTableMemRdData.empty() << endl;
			if (inputWordHashTable.count == 1)
				memStateHashTable = MEM_IDLE;
			else {
				inputWordHashTable.count--;
				inputWordHashTable.address++;
			}
		}
		else if (inputWordHashTable.rdOrWr == 1 && !hashTableMemWrData.empty()) {
			memArrayHashTable[inputWordHashTable.address] = hashTableMemWrData.read();
			if (inputWordHashTable.count == 1)
				memStateHashTable = MEM_IDLE;
			else {
				inputWordHashTable.count--;
				inputWordHashTable.address++;
			}
		}
		break;
	}
}

void cmdAggregatorHash(stream<memCtrlWord> &hashTableMemRdCmd, stream<memCtrlWord> &hashTableMemWrCmd, stream<extMemCtrlWord> &aggregateMemCmdHashTable) {
	if(!hashTableMemWrCmd.empty()) {
		memCtrlWord tempCtrlWord = hashTableMemWrCmd.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 1};
		aggregateMemCmdHashTable.write(tempExtCtrlWord);
	}
	else if(!hashTableMemRdCmd.empty()) {
		memCtrlWord tempCtrlWord = hashTableMemRdCmd.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 0};
		aggregateMemCmdHashTable.write(tempExtCtrlWord);
	}
}

void bramModelHash(stream<memCtrlWord> &hashTableMemRdCmd, stream<ap_uint<512> > &hashTableMemRdData, stream<memCtrlWord> &hashTableMemWrCmd, stream<ap_uint<512> > &hashTableMemWrData) {
	static stream<extMemCtrlWord> aggregateMemCmdHashTable("aggregateMemCmdHashTable");

	cmdAggregatorHash(hashTableMemRdCmd, hashTableMemWrCmd, aggregateMemCmdHashTable);
	memAccessHash(aggregateMemCmdHashTable, hashTableMemRdData, hashTableMemWrData);
}

void memAccessValueStore(stream<extMemCtrlWord> &aggregateMemCmd, stream<ap_uint<512> > &rdDataOut, stream<ap_uint<512> > &wrDataIn)  {
	static ap_uint<512> memArrayValueStore[noOfMemLocations] = {0};

	static enum mState {MEM_IDLE = 0, MEM_ACCESS} memStateValueStore;
	static extMemCtrlWord inputWordValueStore = {0, 0, 0};

	switch(memStateValueStore) {
	case	MEM_IDLE:
		if (!aggregateMemCmd.empty()) {
			aggregateMemCmd.read(inputWordValueStore);
			memStateValueStore = MEM_ACCESS;
		}
		break;
	case	MEM_ACCESS:
		if (inputWordValueStore.rdOrWr == 0) {
			rdDataOut.write(memArrayValueStore[inputWordValueStore.address]);
			if (inputWordValueStore.count == 1)
				memStateValueStore = MEM_IDLE;
			else {
				inputWordValueStore.count--;
				inputWordValueStore.address++;
			}
		}
		else if (inputWordValueStore.rdOrWr == 1 && !wrDataIn.empty()) {
			memArrayValueStore[inputWordValueStore.address] = wrDataIn.read();
			if (inputWordValueStore.count == 1)
				memStateValueStore = MEM_IDLE;
			else {
				inputWordValueStore.count--;
				inputWordValueStore.address++;
			}
		}
		break;
	}
}

void cmdAggregatorValueStore(stream<memCtrlWord> &rdCmdIn, stream<memCtrlWord> &wrCmdIn, stream<extMemCtrlWord> &aggregateMemCmd) {
	if(!wrCmdIn.empty()) {
		memCtrlWord tempCtrlWord = wrCmdIn.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 1};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
	else if(!rdCmdIn.empty()) {
		memCtrlWord tempCtrlWord = rdCmdIn.read();
		extMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 0};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
}

void bramModelValueStore(stream<memCtrlWord> &rdCmdIn, stream<ap_uint<512> > &rdDataOut, stream<memCtrlWord> &wrCmdIn, stream<ap_uint<512> > &wrDataIn) {
	static stream<extMemCtrlWord> aggregateMemCmdValueStore("aggregateMemCmdValueStore");

	cmdAggregatorValueStore(rdCmdIn, wrCmdIn, aggregateMemCmdValueStore);
	memAccessValueStore(aggregateMemCmdValueStore, rdDataOut, wrDataIn);
}


void flashMemAccessValueStore(stream<flashExtMemCtrlWord> &aggregateMemCmd, stream<ap_uint<64> > &rdDataOut, stream<ap_uint<64> > &wrDataIn)  {
	static ap_uint<64> flashMemArrayValueStore[noOfFlashMemLocations];

	static enum fmState {FMEM_IDLE = 0, FMEM_ACCESS} flashMemStateValueStore;
	static flashExtMemCtrlWord flashInputWordValueStore = {0, 0, 0};

	switch(flashMemStateValueStore) {
	case	FMEM_IDLE:
		if (!aggregateMemCmd.empty()) {
			aggregateMemCmd.read(flashInputWordValueStore);
			flashMemStateValueStore = FMEM_ACCESS;
		}
		break;
	case	FMEM_ACCESS:
		if (flashInputWordValueStore.rdOrWr == 0) {
			rdDataOut.write(flashMemArrayValueStore[flashInputWordValueStore.address]);
			if (flashInputWordValueStore.count == 1)
				flashMemStateValueStore = FMEM_IDLE;
			else {
				flashInputWordValueStore.count--;
				flashInputWordValueStore.address++;
			}
		}
		else if (flashInputWordValueStore.rdOrWr == 1 && !wrDataIn.empty()) {
			flashMemArrayValueStore[flashInputWordValueStore.address] = wrDataIn.read();
			if (flashInputWordValueStore.count == 1)
				flashMemStateValueStore = FMEM_IDLE;
			else {
				flashInputWordValueStore.count--;
				flashInputWordValueStore.address++;
			}
		}
		break;
	}
}

void flashCmdAggregatorValueStore(stream<flashMemCtrlWord> &rdCmdIn, stream<flashMemCtrlWord> &wrCmdIn, stream<flashExtMemCtrlWord> &aggregateMemCmd) {
	if(!wrCmdIn.empty()) {
		flashMemCtrlWord tempCtrlWord = wrCmdIn.read();
		flashExtMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 1};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
	else if(!rdCmdIn.empty()) {
		flashMemCtrlWord tempCtrlWord = rdCmdIn.read();
		flashExtMemCtrlWord tempExtCtrlWord = {tempCtrlWord.address, tempCtrlWord.count, 0};
		aggregateMemCmd.write(tempExtCtrlWord);
	}
}

void flashBramModelValueStore(stream<flashMemCtrlWord> &rdCmdIn, stream<ap_uint<64> > &rdDataOut, stream<flashMemCtrlWord> &wrCmdIn, stream<ap_uint<64> > &wrDataIn) {
	static stream<flashExtMemCtrlWord> flashAggregateMemCmdValueStore("aggregateMemCmdValueStore");

	flashCmdAggregatorValueStore(rdCmdIn, wrCmdIn, flashAggregateMemCmdValueStore);
	flashMemAccessValueStore(flashAggregateMemCmdValueStore, rdDataOut, wrDataIn);
}

vector<string> parseLine(string stringBuffer)
{
	vector<string> tempBuffer;
	bool found = false;

	while (stringBuffer.find(" ") != string::npos)	// Search for spaces delimiting the different data words
	{
		string temp = stringBuffer.substr(0, stringBuffer.find(" "));							// Split the the string
		stringBuffer = stringBuffer.substr(stringBuffer.find(" ")+1, stringBuffer.length());	// into two
		tempBuffer.push_back(temp);		// and store the new part into the vector. Continue searching until no more spaces are found.
	}
	tempBuffer.push_back(stringBuffer);	// and finally push the final part of the string into the vector when no more spaces are present.
	return tempBuffer;
}

using namespace hls;
string decodeApUint64(ap_uint<64> inputNumber) {
	string 						outputString	= "0000000000000000";
	unsigned short int			tempValue 		= 16;
	static const char* const	lut 			= "0123456789ABCDEF";
	for (int i = 15;i>=0;--i) {
	tempValue = 0;
	for (unsigned short int k = 0;k<4;++k) {
		if (inputNumber.bit((i+1)*4-k-1) == 1)
			tempValue += static_cast <unsigned short int>(pow(2.0, 3-k));
		}
		outputString[15-i] = lut[tempValue];
	}
	return outputString;
}

string decodeApUint112(ap_uint<112> inputNumber) {
	string 						outputString	= "0000000000000000000000000000";
	unsigned short int			tempValue 		= 16;
	static const char* const	lut 			= "0123456789ABCDEF";
	for (int i = 27;i>=0;--i) {
	tempValue = 0;
	for (unsigned short int k = 0;k<4;++k) {
		if (inputNumber.bit((i+1)*4-k-1) == 1)
			tempValue += static_cast <unsigned short int>(pow(2.0, 3-k));
		}
		outputString[27-i] = lut[tempValue];
	}
	return outputString;
}

string decodeApUint8(ap_uint<8> inputNumber) {
	string 						outputString	= "00";
	unsigned short int			tempValue 		= 16;
	static const char* const	lut 			= "0123456789ABCDEF";
	for (int i = 1;i>=0;--i) {
	tempValue = 0;
	for (unsigned short int k = 0;k<4;++k) {
		if (inputNumber.bit((i+1)*4-k-1) == 1)
			tempValue += static_cast <unsigned short int>(pow(2.0, 3-k));
		}
		outputString[1-i] = lut[tempValue];
	}
	return outputString;
}

ap_uint<64> encodeApUint64(string dataString){
	ap_uint<64> tempOutput = 0;
	unsigned short int	tempValue = 16;
	static const char* const	lut = "0123456789ABCDEF";

	for (unsigned short int i = 0; i<dataString.size();++i) {
		for (unsigned short int j = 0;j<16;++j) {
			if (lut[j] == dataString[i]) {
				tempValue = j;
				break;
			}
		}
		if (tempValue != 16) {
			for (short int k = 3;k>=0;--k) {
				if (tempValue >= pow(2.0, k)) {
					tempOutput.bit(63-(4*i+(3-k))) = 1;
					tempValue -= static_cast <unsigned short int>(pow(2.0, k));
				}
			}
		}
	}
	return tempOutput;
}

ap_uint<8> encodeApUint112(string keepString){
	ap_uint<8> tempOutput = 0;
	unsigned short int	tempValue = 16;
	static const char* const	lut = "0123456789ABCDEF";

	for (unsigned short int i = 0; i<2;++i) {
		for (unsigned short int j = 0;j<16;++j) {
			if (lut[j] == keepString[i]) {
				tempValue = j;
				break;
			}
		}
		if (tempValue != 16) {
			for (short int k = 3;k>=0;--k) {
				if (tempValue >= pow(2.0, k)) {
					tempOutput.bit(111-(4*i+(3-k))) = 1;
					tempValue -= static_cast <unsigned short int>(pow(2.0, k));
				}
			}
		}
	}
	return tempOutput;
}

ap_uint<8> encodeApUint8(string keepString){
	ap_uint<8> tempOutput = 0;
	unsigned short int	tempValue = 16;
	static const char* const	lut = "0123456789ABCDEF";

	for (unsigned short int i = 0; i<2;++i) {
		for (unsigned short int j = 0;j<16;++j) {
			if (lut[j] == keepString[i]) {
				tempValue = j;
				break;
			}
		}
		if (tempValue != 16) {
			for (short int k = 3;k>=0;--k) {
				if (tempValue >= pow(2.0, k)) {
					tempOutput.bit(7-(4*i+(3-k))) = 1;
					tempValue -= static_cast <unsigned short int>(pow(2.0, k));
				}
			}
		}
	}
	return tempOutput;
}

int main(int argc, char *argv[]) {
	extendedAxiWord 						inData;
	extendedAxiWord 						outData;
	stream<extendedAxiWord> 				inFIFO("inFIFO");
	stream<extendedAxiWord> 				outFIFO("outFIFO");

	stream<memCtrlWord> 		valueStoreMemRdCmd("valueStoreMemRdCmd");
	stream<ap_uint<512> > 		valueStoreMemRdData("valueStoreMemRdData");
	stream<memCtrlWord> 		valueStoreMemWrCmd("valueStoreMemWrCmd");
	stream<ap_uint<512> > 		valueStoreMemWrData("valueStoreMemWrData");
	
	stream<flashMemCtrlWord> 	flashValueStoreMemRdCmd("flashValueStoreMemRdCmd");
	stream<ap_uint<64> > 		flashValueStoreMemRdData("flashValueStoreMemRdData");
	stream<flashMemCtrlWord> 	flashValueStoreMemWrCmd("flashValueStoreMemWrCmd");
	stream<ap_uint<64> > 		flashValueStoreMemWrData("flashValueStoreMemWrData");

	stream<ap_uint<512> > 		hashTableMemRdData("hashTableMemRdData");
	stream<memCtrlWord> 		hashTableMemRdCmd("hashTableMemRdCmd");
	stream<ap_uint<512> > 		hashTableMemWrData("hashTableMemWrData");
	stream<memCtrlWord> 		hashTableMemWrCmd("hashTableMemWrCmd");

	stream<ap_uint<32> > 		addressReturnOut("addressReturnOut");
	stream<ap_uint<32> > 		addressAssignDramIn("addressAssignDramIn");
	stream<ap_uint<32> > 		addressAssignFlashIn("addressAssignFlashIn");
	
	ap_uint<1>					flushReq 	= 0;
	ap_uint<1>					flushAck 	= 0;
	ap_uint<1>					flushDone	= 0;

	std::ifstream 				inputFile;
	std::ofstream 				outputFile;
	std::string 				mdString, valueString;
	unsigned short int 			validInt = 0;
	unsigned short int 			tempValue = 16;
	static const char* const 	lut = "0123456789ABCDEF";
	unsigned int				skipCounter = 0;
	unsigned int				cycleCounter = 0;
	unsigned int				myCounter = 0;
	unsigned int				overflowCounter = 0;
	bool						idleCycle = false;

	if (argc != 3) {
		std::cout << "You need to provide two parameters (the input file name followed by the output file name)!" << std::endl;
		return -1;
	}
	inputFile.open(argv[1]);
	if (!inputFile) {
		std::cout << " Error opening input file!" << std::endl;
		return -1;
	}
	outputFile.open(argv[2]);
	if (!outputFile) {
		std::cout << " Error opening output file!" << std::endl;
		return -1;
	}

	do	{
		if (idleCycle == true) {
			if (cycleCounter == skipCounter) {
				cycleCounter = 0;
				idleCycle = false;
			}
			else
				cycleCounter++;
		}
		else if (idleCycle == false) {
			unsigned short int sopTemp, eopTemp, valueValidTemp, keyValidTemp, validInt;
			unsigned short int temp;
			std::string stringBuffer;
			getline(inputFile, stringBuffer);
			if (stringBuffer.size() > 0){
				vector<std::string> stringVector = parseLine(stringBuffer);
				if (stringVector[0] == "W") {
					skipCounter = atoi(stringVector[1].c_str());
					idleCycle = true;
				}
				else {
					inData.last = atoi(stringVector[2].c_str());
					inData.user = //0encodeApUint112(stringVector[0]);
					inData.data = encodeApUint64(stringVector[0]);
					inData.keep = encodeApUint8(stringVector[1]);
					inFIFO.write(inData);
					}
			}
		}
				// Call the memcached pipeline & DRAM model functions
				memcachedPipeline(inFIFO, outFIFO,
								  valueStoreMemRdCmd, valueStoreMemRdData, valueStoreMemWrCmd, valueStoreMemWrData,
								  flashValueStoreMemRdCmd, flashValueStoreMemRdData, flashValueStoreMemWrCmd, flashValueStoreMemWrData,
								  hashTableMemRdData, hashTableMemRdCmd, hashTableMemWrData, hashTableMemWrCmd,
								  addressReturnOut, addressAssignDramIn, addressAssignFlashIn,flushReq, flushAck, flushDone);
				//std::cout << "Pipeline Clear!" << std::endl;
				bramModelHash(hashTableMemRdCmd, hashTableMemRdData, hashTableMemWrCmd, hashTableMemWrData);
				//std::cout << hashTableMemRdData.empty() << std::endl;				//std::cout << "HT Model Clear!" << std::endl;
				bramModelValueStore(valueStoreMemRdCmd, valueStoreMemRdData, valueStoreMemWrCmd, valueStoreMemWrData);
				flashBramModelValueStore(flashValueStoreMemRdCmd, flashValueStoreMemRdData, flashValueStoreMemWrCmd, flashValueStoreMemWrData);
				dummyPCIeJoint(addressReturnOut, addressAssignFlashIn, addressAssignDramIn, flushReq, flushAck, flushDone);
				//std::cout << "VS Model Clear!" << std::endl;
				//std::cout << myCounter << std::endl;

				if (outFIFO.empty() == false) {
					outData = outFIFO.read();
					//std::string metadataOutput 	= decodeApUint112(outData.user);
					std::string dataOutput		= decodeApUint64(outData.data);
					std::string keepOutput		= decodeApUint8(outData.keep);
					//outputFile << metadataOutput << " " << dataOutput << " " << outData.last << " " << keepOutput << std::endl;
					outputFile << dataOutput << " " << keepOutput << " " << outData.last << std::endl;
				}
				simCycleCounter++;
			} while (simCycleCounter < totalSimCycles);
    return 0;
}
