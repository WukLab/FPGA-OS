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
#include <bitset>

void memWriteWithBuddy(stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd, stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData,
			  stream<memCtrlWord> &memWrCtrl, stream<ap_uint<512> > &memWrData, stream<decideResultWord> &memWr2out, stream<ap_uint<1> > &memWr2cc,
			  axis_buddy_alloc& alloc, axis_buddy_alloc_ret& alloc_ret) {
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static comp2decWord					htMemWriteInputStatusWord 	= {0, 0};
	hashTableInternalWord				inputWord 					= {0, 0, 0};
	static internalMdWord				htMemWriteInputWordMd		= {0, 0, 0, 0};
	decideResultWord					outputWord 					= {0, 0};
	memCtrlWord							outputWordMemCtrl			= {0, 0};
	ap_uint<512>						inputWordMem				= 0;
	static ap_uint<8>					memWr_opID					= 0;
	static ap_uint<3>					memWr_location 				= 0;
	static ap_uint<3>					memWr_replaceLocation		= 0;
	static ap_uint<noOfHashTableEntries>memWriteAddress 			= 0;
	static ap_uint<8>					memWr_keyLength				= 0;
	static ap_uint<16>					memWr_valueLength			= 0;
	static enum							mwState {MW_IDLE = 0, MW_EVAL, MW_SET_REST, MW_CONSUME, MW_BUDDY_WAIT, MW_FLUSH_WAIT, MW_FLUSH, MW_FLUSH_CONSUME_KEY, MW_INIT_MEM} memWrState;
	static bool							memWr_memInitialized		= false;
	/* --- START Buddy Allocator --- */
	static buddy_alloc_if					buddy_req				= {BUDDY_ALLOC, 0, 0};
	static buddy_alloc_ret_if				buddy_ret				= {0, 0};
	static bool						buddy_requested				= false;
	static int						buddy_counter				= 0;
	/* --- END Buddy Allocator --- */

	switch (memWrState)
	{
		case MW_IDLE:
		{
			//std::cout << "State: MW_IDLE" << std::endl;
			if (memWr_memInitialized == true) {
				if (!comp2memWrMd.empty() && !comp2memWrKeyStatus.empty()) {
					memWriteAddress = 0;
					comp2memWrKeyStatus.read(htMemWriteInputStatusWord);
					comp2memWrMd.read(htMemWriteInputWordMd);
#if 0
					if (htMemWriteInputWordMd.operation == 8) {
						memWrState = MW_FLUSH_WAIT;
						//outputWord.operation = htMemWriteInputWordMd.operation;
						//memWr2out.write(outputWord);
						memWr_flushReq 	= 1;
						memWr_flushDone	= 0; // Set the Flush Request signal and wait for acknowledgement from the host
					}
					else
#endif
						memWrState = MW_EVAL;
				}
			}
			else if (memWr_memInitialized == false) {
				memWr_memInitialized = true;
				memWrState = MW_INIT_MEM;
			}
			break;
		}
		case MW_EVAL:
		{
			std::cout << "State: MW_EVAL" << std::endl;
			//if (!comp2memWrMemData.empty() && (htMemWriteInputWordMd.operation != 1 ||
			//	(htMemWriteInputWordMd.operation == 1 && ((htMemWriteInputWordMd.valueLength < splitLength && !addressAssignDramIn.empty())
			//	 || (htMemWriteInputWordMd.valueLength >= splitLength && !addressAssignFlashIn.empty()))))) {
			if (!comp2memWrMemData.empty()) {
				comp2memWrMemData.read(inputWordMem);
				bool 		found 		= false;
				bool		replace		= false;
				outputWord.operation 	= htMemWriteInputWordMd.operation;
				memWr_keyLength			= htMemWriteInputWordMd.keyLength;
				memWr_valueLength		= htMemWriteInputWordMd.valueLength;
				if(htMemWriteInputWordMd.operation == 0)	{ 	// Get operation
					for (uint8_t i=noOfBins;i>0;--i) {
						if (htMemWriteInputStatusWord.bin[i-1].match == 1) {	// A bin containing this key has been found
							found 			= true;
							memWr_location	= i-1;
						}
					}
					if (found == false)	{				// Failed Get
						outputWord.status = 1;			// Mark the result as a failed one
						outputWord.valueLength = 0;
						memWr2out.write(outputWord);	// and write it into the output.
					}
					else if (found == true) {
						outputWord.address = inputWordMem.range(((bitsPerBin*memWr_location)+88)-1, (bitsPerBin*memWr_location)+56);
						outputWord.status = 0;
						outputWord.valueLength = inputWordMem.range(((bitsPerBin*memWr_location)+56)-1, (bitsPerBin*memWr_location)+40);
						memWr2out.write(outputWord);
					}
					memWr2cc.write(1);					// Pop the hash value from the CC filter.
					memWrState = MW_CONSUME;
				}
				else if (htMemWriteInputWordMd.operation == 1) {	// Set operation
					for (uint8_t i=noOfBins;i>0;--i) {
						if (htMemWriteInputStatusWord.bin[i-1].free == 1 && htMemWriteInputStatusWord.bin[i-1].match == 0)	{
							found = true;
							memWr_location = i-1;
						}
						else if (htMemWriteInputStatusWord.bin[i-1].free == 0 && htMemWriteInputStatusWord.bin[i-1].match == 1)	{
							replace = true;
							memWr_replaceLocation = i-1;
						}
					}

					if ((found == false && replace == false)) {
					//	|| (htMemWriteInputWordMd.valueLength >= splitLength && addressAssignFlashIn.empty()))) {	// Failed Set // Add stuff here
						outputWord.status = 1;
						memWr2out.write(outputWord);
						memWr2cc.write(1); // Pop the hash value from the CC filter.
						memWrState = MW_CONSUME;
					}
					else if (found == true)	{
						/* --- START Buddy Allocator --- */
						if (!replace) {
							buddy_req.opcode = BUDDY_ALLOC;
							buddy_req.addr = 0;
							buddy_req.order = order_base_2<16>(LENGTH_TO_ORDER(memWr_valueLength));
							alloc.write(buddy_req);
						}
						/* --- END Buddy Allocator --- */

						if (replace == true)
							memWr_location = memWr_replaceLocation;
						outputWordMemCtrl.count	= htMemWriteInputWordMd.keyLength/16;
						std::cout << "Count1: " << outputWordMemCtrl.count << std::endl;
						if (htMemWriteInputWordMd.keyLength > (outputWordMemCtrl.count*16))
							outputWordMemCtrl.count += 2;
						else
							outputWordMemCtrl.count += 1;
						std::cout << "Count2: " << outputWordMemCtrl.count
								<< " htMemWriteInputWordMd.keyLength: " << htMemWriteInputWordMd.keyLength << std::endl;
						//ap_uint<7> tempAddress = htMemWriteInputWordMd.metadata.range(noOfHashTableEntries + 4, 8);	// Plus 5 here is to shift the 8 LSBs of the address.
						ap_uint<32> tempAddress = htMemWriteInputWordMd.metadata;
						outputWordMemCtrl.address.range(noOfHashTableEntries - 1, 3) = tempAddress.range(6, 0);
						memWrCtrl.write(outputWordMemCtrl);
						outputWord.status = 0;
						inputWordMem.range(((bitsPerBin*memWr_location)+8)-1, bitsPerBin*memWr_location) = memWr_keyLength;
						inputWordMem.range(((bitsPerBin*memWr_location)+40)-1, (bitsPerBin*memWr_location)+8) = 0x18;
						inputWordMem.range(((bitsPerBin*memWr_location)+56)-1, (bitsPerBin*memWr_location)+40) = memWr_valueLength;
						ap_uint<32> addressPointer;		// Address pointer will hold the value store address of the data
						if (replace == true)			// If the value is to be replaced, then the address, which has already been assigned, can be reused
							addressPointer = inputWordMem.range(((bitsPerBin*memWr_location)+88)-1, (bitsPerBin*memWr_location)+56);
					//	else if (htMemWriteInputWordMd.valueLength < splitLength)	// If not and the value is smaller than the split length, a value from the DRAM pool is fetched
					//		addressPointer = addressAssignFlashIn.read();
						else {														// if the value is larger than the split length, then a value from the SSD pool is read
							while(alloc_ret.empty());
							buddy_ret = alloc_ret.read();
							if (buddy_ret.stat == SUCCESS)
								addressPointer = buddy_ret.addr >> 8;
							//std::cout << "ADDR: " << std::hex << buddy_ret.addr << " " << std::bitset<32>(buddy_ret.addr) << std::endl;
						}
						inputWordMem.range(((bitsPerBin*memWr_location)+88)-1, (bitsPerBin*memWr_location)+56) = addressPointer;
						memWrData.write(inputWordMem);
						outputWord.address = addressPointer;
						memWr2out.write(outputWord);
						memWrState = MW_SET_REST;
					}
				}
				else if (htMemWriteInputWordMd.operation == 4) {				// Delete operation
					for (uint8_t i=0;i<noOfBins;++i) {							// Check if a matching key has been found
						if (htMemWriteInputStatusWord.bin[i].match == 1) {
							found = true;
							memWr_location = i;
						}
					}
					if (found == false) {	// Failed Delete					// If not this operation has to fail
						outputWord.status = 1;									// mark it as failed
						memWr2out.write(outputWord);							// and write the output
					}
					else if (found == true)	{									// If the key was found then the operation is a success
						outputWordMemCtrl.count = 1;
						//ap_uint<7> tempAddress = htMemWriteInputWordMd.metadata.range(noOfHashTableEntries + 4, 8);
						ap_uint<32> tempAddress = htMemWriteInputWordMd.metadata;
						outputWordMemCtrl.address.range(noOfHashTableEntries - 1, 3) = tempAddress.range(6, 0);
						memWrCtrl.write(outputWordMemCtrl);
						/* --- START Buddy Allocator --- */
						buddy_req.opcode = BUDDY_FREE;
						buddy_req.addr = inputWordMem.range(((bitsPerBin*memWr_location)+87)-1, (bitsPerBin*memWr_location)+56);
						buddy_req.order = order_base_2<16>(LENGTH_TO_ORDER(inputWordMem.range(((bitsPerBin*memWr_location)+56)-1, (bitsPerBin*memWr_location)+40)));
						alloc.write(buddy_req);
						/* --- END Buddy Allocator --- */
						outputWord.status = 0;
						memWr2out.write(outputWord);
						inputWordMem.range(((bitsPerBin*memWr_location)+8)-1, bitsPerBin*memWr_location) = 0;
						inputWordMem.range(((bitsPerBin*memWr_location)+56)-1, (bitsPerBin*memWr_location)+40) = 0;
						memWrData.write(inputWordMem);
					}
					memWrState = MW_CONSUME;
					memWr2cc.write(1);					// Pop the hash value from the CC filter.
				}
			}
			break;
		}
		case MW_SET_REST:
		{
			std::cout << "State: MW_SET_REST" << std::endl;
			if (!comp2memWrKey.empty() && !comp2memWrMemData.empty()) {
				comp2memWrMemData.read(inputWordMem);
				comp2memWrKey.read(inputWord);
				inputWordMem.range((bitsPerBin*(memWr_location+1))-1, (bitsPerBin*memWr_location)) = inputWord.data;
				memWrData.write(inputWordMem);
				if (inputWord.EOP == 1) {
					memWr2cc.write(1); // Pop the hash value from the CC filter.
					memWrState = MW_IDLE;
				}
			}
			break;
		}
		case MW_FLUSH_WAIT:
		{
			std::cout << "State: MW_FLUSH_WAIT" << std::endl;
			//if (flushAck == 1)
			//	memWrState = MW_FLUSH;
			break;
		}
		case MW_FLUSH:
		{
			std::cout << "State: MW_FLUSH" << std::endl;
			memCtrlWord flushWord = {memWriteAddress, 1};
			memWriteAddress++;
			memWrCtrl.write(flushWord);
			memWrData.write(0);
			if (memWriteAddress == myPow(noOfHashTableEntries) - 1) {
				memWr2cc.write(1);
				//memWr_flushDone	= 1;
				//memWr_flushReq	= 0;
				outputWord.operation = htMemWriteInputWordMd.operation;
				memWr2out.write(outputWord);
				memWrState = MW_FLUSH_CONSUME_KEY;
			}
			break;
		}
		case MW_FLUSH_CONSUME_KEY:
		{
			std::cout << "State: MW_FLUSH_CONSUME_KEY" << std::endl;
			if (!comp2memWrKey.empty()) {
				comp2memWrKey.read(inputWord);
				memWrState = MW_IDLE;
			}
			break;
		}
		case MW_CONSUME:
		{
			std::cout << "State: MW_CONSUME" << std::endl;
			if (!comp2memWrKey.empty() && !comp2memWrMemData.empty())	{
				comp2memWrKey.read(inputWord);
				comp2memWrMemData.read(inputWordMem);
				if (inputWord.EOP == 1)
					memWrState = MW_IDLE;
			}
			break;
		}
		case MW_INIT_MEM:
		{
			memCtrlWord flushWord = {memWriteAddress, 1};
			memWriteAddress++;
			memWrCtrl.write(flushWord);
			memWrData.write(0);
			if (memWriteAddress == myPow(noOfHashTableEntries) - 1) {
				memWrState = MW_IDLE;
			}
			break;
		}
	}
	//flushReq = memWr_flushReq;
	//flushDone = memWr_flushDone;
}
