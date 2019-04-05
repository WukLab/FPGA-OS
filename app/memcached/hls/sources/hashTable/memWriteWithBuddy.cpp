#include "../globals.h"
#include <bitset>

unsigned int dummy_allocator(void)
{
#pragma HLS INLINE
	static unsigned int __base = 0x100000;
	static unsigned int __step = 0x100;
	static int __nr = 0;

	return __base + (__step * __nr++);
}

/*
 * @comp2memWrKey: the new request's key
 * @comp2memWrMd: the new request's metadata
 * @comp2memWrKeyStatus: the comparison status array from ht_compare()
 * @comp2memWrMemData: the DRAM content of the hash bucket (HEAD+saved_keys)
 *
 * @memWr2cc: send requests to CC to pop this request out from hashFilter
 */
void memWriteWithBuddy(stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd,
		       stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData,
		       stream<memCtrlWord> &memWrCtrl, stream<ap_uint<512> > &memWrData,
		       stream<decideResultWord> &memWr2out, stream<ap_uint<1> > &memWr2cc,
		       stream<struct buddy_alloc_if>& alloc,
		       stream<struct buddy_alloc_ret_if>& alloc_ret)
{
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum mwState {
		MW_IDLE = 0, MW_EVAL, MW_SET_REST, MW_CONSUME,
		MW_BUDDY_WAIT, MW_FLUSH_WAIT, MW_FLUSH,
		MW_FLUSH_CONSUME_KEY, MW_INIT_MEM
	} memWrState;

	static comp2decWord		htMemWriteInputStatusWord = {0, 0};
	hashTableInternalWord		inputWord 		= {0, 0, 0};
	static internalMdWord		htMemWriteInputWordMd	= {0, 0, 0, 0};
	decideResultWord		outputWord 		= {0, 0};
	memCtrlWord			outputWordMemCtrl	= {0, 0};
	ap_uint<512>			inputWordMem		= 0;
	static ap_uint<8>		memWr_opID		= 0;
	static ap_uint<3>		memWr_location 		= 0;
	static ap_uint<3>		memWr_replaceLocation	= 0;
	static ap_uint<noOfHashTableEntries>memWriteAddress 	= 0;
	static ap_uint<8>		memWr_keyLength		= 0;
	static ap_uint<16>		memWr_valueLength	= 0;
	static bool			memWr_memInitialized	= false;

	// Buddy Allocator
	static buddy_alloc_if		buddy_req		= {BUDDY_ALLOC, 0, 0};
	static buddy_alloc_ret_if	buddy_ret		= {0, 0};

	bool found 		= false;
	bool replace		= false;

	switch (memWrState)
	{
		case MW_IDLE:
		{
			if (memWr_memInitialized == true) {
				if (!comp2memWrMd.empty() && !comp2memWrKeyStatus.empty()) {
					memWriteAddress = 0;
					comp2memWrKeyStatus.read(htMemWriteInputStatusWord);
					comp2memWrMd.read(htMemWriteInputWordMd);

					memWrState = MW_EVAL;
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
				}
			} else if (memWr_memInitialized == false) {
				memWr_memInitialized = true;
				memWrState = MW_INIT_MEM;
			}
			break;
		}
		case MW_EVAL:
		{
			PR("State: MW_EVAL\n");

			if (comp2memWrMemData.empty())
				break;

			// Read the DRAM content of the hash bucket
			comp2memWrMemData.read(inputWordMem);

			found = false;
			replace = false;

			// Metadata of the new request, read during MW_IDLE
			outputWord.operation 	= htMemWriteInputWordMd.operation;
			memWr_keyLength		= htMemWriteInputWordMd.keyLength;
			memWr_valueLength	= htMemWriteInputWordMd.valueLength;

			if (htMemWriteInputWordMd.operation == 0) {
				//
				// OPCODE=0, GET
				//
				for (uint8_t i = noOfBins ; i > 0; i--) {
					// A bin containing this key has been found?
					if (htMemWriteInputStatusWord.bin[i-1].match == 1) {
						found = true;
						memWr_location = i-1;
					}
				}

				if (found == false) {			// Failed Get
					outputWord.status = 1;		// Mark the result as a failed one
					outputWord.valueLength = 0;
					memWr2out.write(outputWord);	// and write it into the output.
				} else if (found == true) {
					// For each 128b hash entry metadata
					// 	32b (87, 56) Value Address
					// 	16b (55, 40) Value Length
					// 	8b  (7, 0)   Key Length
					outputWord.status = 0;
					outputWord.address = inputWordMem.range((bitsPerBin * memWr_location) + 88 - 1,
										(bitsPerBin * memWr_location) + 56);
					outputWord.valueLength = inputWordMem.range((bitsPerBin * memWr_location) + 56 - 1,
										    (bitsPerBin * memWr_location) + 40);
					memWr2out.write(outputWord);
				}

				// Pop the hash value from the CC filter.
				memWr2cc.write(1);
				memWrState = MW_CONSUME;
			} else if (htMemWriteInputWordMd.operation == 1) {
				//
				// OPCODE=1, SET
				//
				for (uint8_t i = noOfBins; i > 0; i--) {
					if (htMemWriteInputStatusWord.bin[i-1].free == 1 ||
					    htMemWriteInputStatusWord.bin[i-1].match == 1) {
					    	// Create a new entry for the new comer
						found = true;
						memWr_location = i-1;
					}

					if (htMemWriteInputStatusWord.bin[i-1].match == 1) {
						// Override an existing matched key
						replace = true;
						memWr_replaceLocation = i-1;
					}
				}

				if ((found == false && replace == false)) {
					//
					// SET failed: Either no left entries
					// or no matched keys found
					//
					outputWord.status = 1;
					memWr2out.write(outputWord);

					// Pop the hash value from the CC filter.
					memWr2cc.write(1);
					memWrState = MW_CONSUME;
				} else if (found == true) {
					//
					// SET succeed
					//	- Either a matched key found or there is a empty space
					//	- Update the HEAD 512bits, write it back to DRAM
					//	- Pass results out
					//

					if (replace == false) {
						// Send request to Buddy Allocator
						buddy_req.opcode = BUDDY_ALLOC;
						buddy_req.addr = 0;
						buddy_req.order = order_base_2<16>(LENGTH_TO_ORDER(memWr_valueLength));
						alloc.write(buddy_req);
					} else {
						memWr_location = memWr_replaceLocation;
					}

					outputWordMemCtrl.count	= htMemWriteInputWordMd.keyLength/16;
					if (htMemWriteInputWordMd.keyLength > (outputWordMemCtrl.count*16))
						outputWordMemCtrl.count += 2;
					else
						outputWordMemCtrl.count += 1;

					// metadata is the computed hash value
					ap_uint<32> tempAddress = htMemWriteInputWordMd.metadata;

					//
					// NOTE: Write Key metadata out (the whole 512bits)
					// Looks like no matter its new or a match,
					// always rewrite the all keys' medatadata.
					// Even though only one bin is changed.
					//
					outputWordMemCtrl.address.range(noOfHashTableEntries - 1, 3) = tempAddress.range(6, 0);
					memWrCtrl.write(outputWordMemCtrl);

					// For each 128b hash entry metadata
					// 	32b (87, 56) Value Address
					// 	16b (55, 40) Value Length
					// 	8b  (7, 0)   Key Length
					inputWordMem.range(((bitsPerBin*memWr_location)+8)-1, bitsPerBin*memWr_location) = memWr_keyLength;
					inputWordMem.range(((bitsPerBin*memWr_location)+40)-1, (bitsPerBin*memWr_location)+8) = 0x18;
					inputWordMem.range(((bitsPerBin*memWr_location)+56)-1, (bitsPerBin*memWr_location)+40) = memWr_valueLength;

					// Now get the DRAM address of the value
					// - Replace: reuse the previous saved address
					// - New: ask Buddy to allocate one.
					ap_uint<32> addressPointer;
					if (replace == true) {
						addressPointer = inputWordMem.range((bitsPerBin*memWr_location)+88-1,
										    (bitsPerBin*memWr_location)+56);
					} else {
#if 0
						// FIXME
						while(alloc_ret.empty())
							;
						buddy_ret = alloc_ret.read();

						// Succeed
						if (buddy_ret.stat == 0)
							addressPointer = buddy_ret.addr >> 8;
						PR("ADDR: %#lx\n", addressPointer);
#else
						if (!alloc_ret.empty())
							buddy_ret = alloc_ret.read();
						addressPointer = dummy_allocator();
#endif
					}
					inputWordMem.range(((bitsPerBin*memWr_location)+88)-1, (bitsPerBin*memWr_location)+56) = addressPointer;

					// The new 512b hash HEAD
					// with only one entry changed.
					memWrData.write(inputWordMem);

					// Pass results down the pipeline
					outputWord.status = 0;
					outputWord.address = addressPointer;
					memWr2out.write(outputWord);

					memWrState = MW_SET_REST;
				}
			} else if (htMemWriteInputWordMd.operation == 4) {
				//
				// OPCODE=4, DELETE
				// NOT USED!
				//

				// Check if a matching key has been found
				for (uint8_t i=0;i<noOfBins;++i) {
					if (htMemWriteInputStatusWord.bin[i].match == 1) {
						found = true;
						memWr_location = i;
					}
				}

				// Failed Delete
				if (found == false) {
					outputWord.status = 1;
					memWr2out.write(outputWord);
				} else if (found == true) {
					// If the key was found then the operation is a success
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
				// Pop the hash value from the CC filter.
				memWr2cc.write(1);
				memWrState = MW_CONSUME;
			}
			break;
		}

		case MW_SET_REST:
		{
			//
			// This state will run if and only if
			// we got a succeed SET operation.
			// This state will write the new request's KEY into DRAM
			//
			PR("State: MW_SET_REST\n");
			if (!comp2memWrKey.empty() && !comp2memWrMemData.empty()) {
				// Read the new request's key from pipeline
				comp2memWrKey.read(inputWord);

				// Read the saved keys from DRAM
				comp2memWrMemData.read(inputWordMem);

				// Update 128bits out of the 512bits
				inputWordMem.range((bitsPerBin*(memWr_location+1))-1, (bitsPerBin*memWr_location)) = inputWord.data;

				// Write it back to DRAM
				memWrData.write(inputWordMem);

				if (inputWord.EOP == 1) {
					// Pop the hash value from the CC filter.
					memWr2cc.write(1);
					memWrState = MW_IDLE;
				}
			}
			break;
		}

		case MW_FLUSH_WAIT:
		{
			PR("State: MW_FLUSH_WAIT\n");
			//if (flushAck == 1)
			//	memWrState = MW_FLUSH;
			break;
		}
		case MW_FLUSH:
		{
			PR("State: MW_FLUSH\n");
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
			PR("State: MW_FLUSH_CONSUME_KEY\n");
			if (!comp2memWrKey.empty()) {
				comp2memWrKey.read(inputWord);
				memWrState = MW_IDLE;
			}
			break;
		}
		case MW_CONSUME:
		{
			PR("State: MW_CONSUME\n");
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
#if 0
			memCtrlWord flushWord = {memWriteAddress, 1};
			memWriteAddress++;
			memWrCtrl.write(flushWord);
			memWrData.write(0);
			if (memWriteAddress == myPow(noOfHashTableEntries) - 1) {
				memWrState = MW_IDLE;
			}
#else
			memWrState = MW_IDLE;
#endif
			break;
		}
	}
	//flushReq = memWr_flushReq;
	//flushDone = memWr_flushDone;
}
