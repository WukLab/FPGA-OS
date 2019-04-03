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
#include <pthread.h>
#include <atomic>

#define totalSimCycles    5000//00    // Defines how many additional C simulation cycles will be executed after the input file has been read in. Used to make sure all the request traverse the entire pipeline.

unsigned int    simCycleCounter;

using namespace std;

void memAccessHash(stream<extMemCtrlWord> &aggregateMemCmdHashTable, stream<ap_uint<512> > &hashTableMemRdData, stream<ap_uint<512> > &hashTableMemWrData)  {
    static ap_uint<512> memArrayHashTable[noOfMemLocations] = {0};

    static enum mState {MEM_IDLE = 0, MEM_ACCESS} memStateHashTable;
    static extMemCtrlWord inputWordHashTable = {0, 0, 0};

    switch(memStateHashTable) {
    case    MEM_IDLE:
        if (!aggregateMemCmdHashTable.empty()) {
            aggregateMemCmdHashTable.read(inputWordHashTable);
            memStateHashTable = MEM_ACCESS;
        }
        break;
    case    MEM_ACCESS:
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
            if (memArrayHashTable[inputWordHashTable.address])
        	    std::cout << std::hex << "Table Entry: 0x" <<  memArrayHashTable[inputWordHashTable.address] << " Count: " << inputWordHashTable.count << std::endl;
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
    static ap_uint<512> memArrayValueStore[noOfMemLocations * 100] = {0};

    static enum mState {MEM_IDLE = 0, MEM_ACCESS} memStateValueStore;
    static extMemCtrlWord inputWordValueStore = {0, 0, 0};

    switch(memStateValueStore) {
    case    MEM_IDLE:
        if (!aggregateMemCmd.empty()) {
            aggregateMemCmd.read(inputWordValueStore);
            memStateValueStore = MEM_ACCESS;
        }
        break;
    case    MEM_ACCESS:
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
            std::cout << std::hex << "ADDR: " << inputWordValueStore.address << " Data: 0x" <<  memArrayValueStore[inputWordValueStore.address] << std::endl;
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

vector<string> parseLine(string stringBuffer)
{
    vector<string> tempBuffer;
    bool found = false;

    while (stringBuffer.find(" ") != string::npos)    // Search for spaces delimiting the different data words
    {
        string temp = stringBuffer.substr(0, stringBuffer.find(" "));                            // Split the the string
        stringBuffer = stringBuffer.substr(stringBuffer.find(" ")+1, stringBuffer.length());    // into two
        tempBuffer.push_back(temp);        // and store the new part into the vector. Continue searching until no more spaces are found.
    }
    tempBuffer.push_back(stringBuffer);    // and finally push the final part of the string into the vector when no more spaces are present.
    return tempBuffer;
}

using namespace hls;
string decodeApUint64(ap_uint<64> inputNumber) {
    string                         outputString    = "0000000000000000";
    unsigned short int            tempValue         = 16;
    static const char* const    lut             = "0123456789ABCDEF";
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
    string                         outputString    = "0000000000000000000000000000";
    unsigned short int            tempValue         = 16;
    static const char* const    lut             = "0123456789ABCDEF";
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
    string                         outputString    = "00";
    unsigned short int            tempValue         = 16;
    static const char* const    lut             = "0123456789ABCDEF";
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
    unsigned short int    tempValue = 16;
    static const char* const    lut = "0123456789ABCDEF";

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
    unsigned short int    tempValue = 16;
    static const char* const    lut = "0123456789ABCDEF";

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
    unsigned short int    tempValue = 16;
    static const char* const    lut = "0123456789ABCDEF";

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

static std::atomic<bool> buddy_run (true);
static stream<struct buddy_alloc_if> alloc;
static stream<struct buddy_alloc_ret_if> alloc_ret;

static void *buddy_allocator_thread(void *unused)
{
	int counter = 0;
	char* dram = new char[SIM_DRAM_SIZE]();
	buddy_alloc_ret_if buddy_ret = {0,0};

	while (buddy_run) {
		if (!alloc.empty()) {
			counter++;
			//std::cout << "[TB] Allocation Count: " << counter << std::endl;
			buddy_allocator(alloc, alloc_ret, dram);
			//std::cout << "[TB] Allocation Request Done" << std::endl;
		}
	}
	return NULL;
}

int main(int argc, char *argv[]) {
    extendedAxiWord             inData;
    extendedAxiWord             outData;
    stream<extendedAxiWord>     inFIFO("inFIFO");
    stream<extendedAxiWord>     outFIFO("outFIFO");

    stream<memCtrlWord>         valueStoreMemRdCmd("valueStoreMemRdCmd");
    stream<ap_uint<512> >       valueStoreMemRdData("valueStoreMemRdData");
    stream<memCtrlWord>         valueStoreMemWrCmd("valueStoreMemWrCmd");
    stream<ap_uint<512> >       valueStoreMemWrData("valueStoreMemWrData");

    stream<flashMemCtrlWord>    flashValueStoreMemRdCmd("flashValueStoreMemRdCmd");
    stream<ap_uint<64> >        flashValueStoreMemRdData("flashValueStoreMemRdData");
    stream<flashMemCtrlWord>    flashValueStoreMemWrCmd("flashValueStoreMemWrCmd");
    stream<ap_uint<64> >        flashValueStoreMemWrData("flashValueStoreMemWrData");

    stream<ap_uint<512> >       hashTableMemRdData("hashTableMemRdData");
    stream<memCtrlWord>         hashTableMemRdCmd("hashTableMemRdCmd");
    stream<ap_uint<512> >       hashTableMemWrData("hashTableMemWrData");
    stream<memCtrlWord>         hashTableMemWrCmd("hashTableMemWrCmd");

    std::ifstream               inputFile;
    std::ofstream               outputFile;
    std::string                 mdString, valueString;
    unsigned short int          validInt = 0;
    unsigned short int          tempValue = 16;
    static const char* const    lut = "0123456789ABCDEF";
    unsigned int                skipCounter = 0;
    unsigned int                cycleCounter = 0;
    unsigned int                overflowCounter = 0;
    bool                        idleCycle = false;

    pthread_t buddy_thread;

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

    /* create a second thread which executes buddy */
    if(pthread_create(&buddy_thread, NULL, buddy_allocator_thread, NULL)) {
	    fprintf(stderr, "Error creating thread\n");
	    return -1;
    }

    do {
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
                    std::cout << "[TB] " << stringVector[0] << " | " << stringVector[1] << " | " << stringVector[2] << std::endl;
                    inFIFO.write(inData);
                    }
            }
        }

        memcachedBuddy(inFIFO, outFIFO,
		       valueStoreMemRdCmd, valueStoreMemRdData,
		       valueStoreMemWrCmd, valueStoreMemWrData,
		       hashTableMemRdData, hashTableMemRdCmd,
		       hashTableMemWrData, hashTableMemWrCmd,
		       alloc, alloc_ret);

        bramModelHash(hashTableMemRdCmd, hashTableMemRdData, hashTableMemWrCmd, hashTableMemWrData);
        bramModelValueStore(valueStoreMemRdCmd, valueStoreMemRdData, valueStoreMemWrCmd, valueStoreMemWrData);

        //if (simCycleCounter % 10 == 0)
        //	printf("SimCounter: %d\n", simCycleCounter);

        if (outFIFO.empty() == false) {
            outData = outFIFO.read();
            std::string dataOutput        = decodeApUint64(outData.data);
            std::string keepOutput        = decodeApUint8(outData.keep);
            outputFile << dataOutput << " " << keepOutput << " " << outData.last << std::endl;
        }
        simCycleCounter++;
    } while (simCycleCounter < totalSimCycles);
    buddy_run = false;

    return 0;
}
