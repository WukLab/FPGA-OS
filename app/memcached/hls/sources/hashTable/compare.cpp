#include "../globals.h"

/*
 * This function tries to compare the new request's key with the saved keys
 * in the same hash bucket that new request's key maps to.
 * The commands to read the memory was sent by memRead() before us.
 *
 * @memRd2comp: the new request's key
 * @memRd2compMd: operation etc
 * @memRdData: the memory content of the hash bucket that new request's key maps to
 *
 * @comp2memWrKey: pass down the new request's key
 * @comp2memWrMd: pass down the new request's metadata
 * @comp2memWrKeyStatus: pass down the comparison status array
 * @comp2memWrMemData: pass down the DRAM content of the hash bucket
 */
void ht_compare(stream<hashTableInternalWord> &memRd2comp, stream<internalMdWord> &memRd2compMd,
		stream<ap_uint<512> > &memRdData,
		stream<hashTableInternalWord> &comp2memWrKey, stream<internalMdWord> &comp2memWrMd,
		stream<comp2decWord> &comp2memWrKeyStatus, stream<ap_uint<512> > &comp2memWrMemData)
{
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	static enum cState {CMP_IDLE = 0, CMP_HEAD, CMP_COMPARE, CMP_STREAM} cmpState;
	static uint8_t cmp_keyLength = 0;
	static hashTableInternalWord cmp_inData = {0, 0, 0};
	static internalMdWord cmp_inDataMd = {0, 0, 0, 0 };
	static comp2decWord statusOutput = {0, 0};
	static bool cmpResult = true;
	ap_uint<512> memInput = 0;

	switch(cmpState) {
	case CMP_IDLE:
		// Read request metadata
		if (memRd2compMd.empty())
			break;

		memRd2compMd.read(cmp_inDataMd);
		cmp_keyLength = cmp_inDataMd.keyLength;

		if (cmp_inDataMd.operation == 8)
			cmpState = CMP_STREAM;
		else
			cmpState = CMP_HEAD;

		// Reset states
		for (uint8_t i = 0; i < noOfBins; i++) {
			statusOutput.bin[i].free = 0;
			statusOutput.bin[i].match = 0;
		}
		break;

	case CMP_HEAD:
		if (memRdData.empty())
			break;

		// The first word (512 bits) from the memory just contains the metadata,
		// which is the key length of each key:
		//	  0   - 127	KeyLen_1 + Value_Len + Value_Addr
		//	  128 - 255	KeyLen_2
		//	  256 - 383	KeyLen_3
		//	  384 - 511	KeyLen_4
		//
		// Note the cmd for DRAM read was sent by memRead() before.
		memRdData.read(memInput);

		// First, go through all the bins of the first key data word,
		// and check if the Key Length of the new request matches any
		// save ones:
		for (uint8_t i = 0; i < noOfBins; i++) {
			// If its 0, then the bin is empty
			if (memInput.range((bitsPerBin*i)+7, (bitsPerBin*i)) == 0)
				statusOutput.bin[i].free = 1;
			else if (memInput.range((bitsPerBin*i)+7, (bitsPerBin*i)) == cmp_keyLength)
				statusOutput.bin[i].match = 1;
		}

		// Stream the DRAM saved key lengths down
		comp2memWrMemData.write(memInput);
		cmpState = CMP_COMPARE;
		break;

	case CMP_COMPARE:
		if (!memRdData.empty() && !memRd2comp.empty()) {
			// Read the saved keys from DRAM
			memRdData.read(memInput);

			// Read new request's key
			memRd2comp.read(cmp_inData);
#if DEBUG_PRINT
			if (memInput != 0) {
				std::cout << "memRead: " << std::hex << memInput << " request: " << cmp_inData.data << std::endl;
			}
#endif

			// For the first 512bits:
			//	  0   - 127	Key_1 (0-127)
			//	  128 - 255	Key_2 (0-127)
			//	  256 - 383	Key_3 (0-127)
			//	  384 - 511	Key_4 (0-127)
			// and so on..
			for (uint8_t i = 0; i < noOfBins; i++) {
				// If this part of the key does not match the input data
				if (memInput.range((bitsPerBin*(i+1))-1, (bitsPerBin*i)) != cmp_inData.data) {
					// set the flag to 0
					statusOutput.bin[i].match = 0;
				}
			}

			comp2memWrMemData.write(memInput);	// Stream the memory data word down the pipeline
			comp2memWrKey.write(cmp_inData);	// Stream the input key on

			// Adjust the key length (minus 128bits)
			if (cmp_keyLength > (8*words2aggregate))
				cmp_keyLength -= (8*words2aggregate);
			else
				cmp_keyLength = 0;

			// Check if the key comparison is complete. If so,
			if (cmp_keyLength == 0)	{
				comp2memWrMd.write(cmp_inDataMd); 		// write the metadata to the next state
				comp2memWrKeyStatus.write(statusOutput);	// write the status flags to the next stage
				cmpState = CMP_IDLE;				// and move back to idle
			}
			// if there is more to compare, read the next input key word and stay in this state
		}
		break;
	case CMP_STREAM:
		if (!memRd2comp.empty()) {
			comp2memWrKey.write(memRd2comp.read());

			// Adjust the key length (minus 128bits)
			if (cmp_keyLength > (8 * words2aggregate))
				cmp_keyLength -= (8 * words2aggregate);
			else
				cmp_keyLength = 0;

			// Check if the key comparison is complete. If so,
			if (cmp_keyLength == 0)	{
				comp2memWrMd.write(cmp_inDataMd);		// write the metadata to the next state
				comp2memWrKeyStatus.write(statusOutput);	// write the status flags to the next stage
				cmpState = CMP_IDLE;				// and move back to idle
			}
		}
		break;
	}
}
