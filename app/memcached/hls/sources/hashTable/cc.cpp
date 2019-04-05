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

/*
 * Inputs:
 * @in2cc is the key
 * @in2ccMd is some metadata such as operation
 * @hash2cc is the computed 32 bits hash value
 * @dec2cc: from memWriteWithBuddy(). Decision/results of this request.
 *
 * Outputs:
 * @cc2memRead: is the key
 * @cc2memReadMd: is the metadate
 * (pass through as in2cc)
 *
 * hashFilter is the table that saves _all_ in-flisht requests.
 * It can be used to check if there is any RAW dependency.
 * But it also limits how many in-flight request we can have.
 *
 * hashFilter is pushed when a request comes in and no dependency detected.
 * hashFilter is poped when TODO?
 */
void concurrencyControl(stream<hashTableInternalWord> &in2cc,
			stream<internalMdWord> &in2ccMd, stream<ap_uint<32> > &hash2cc,
                        stream<hashTableInternalWord> &cc2memRead,
			stream<internalMdWord> &cc2memReadMd, stream<ap_uint<1> > &dec2cc)
{
	// All functions called from this concurrencyControl()
	// will be inlined. So no need to write for those.
	#pragma HLS INLINE region
	#pragma HLS pipeline II=1 enable_flush

	static concurrencyFilter hashFilter;

	static enum concState {
		CC_IDLE = 0,
		CC_WAIT,
		CC_PUSH,
		CC_STREAM,
		CC_POP_IDLE,
		CC_POP_WAIT
	} ccState;
	static hashTableInternalWord ccInputWord = {0, 0, 0};
	static  internalMdWord ccInputWordMd = {0, 0, 0, 0};
	ap_uint<32> hashInputWord = 0;
	static ccWord ccCompareElement = {0, 0, 0, 0};

	switch(ccState)
	{
		case CC_IDLE:
			// This part of the code pops the filter if the
			// appropriate signal is detected in the dec2cc stream.
			// This has to take place in parallel with all other operations.
			if (dec2cc.empty() == false) {
				ccState = CC_POP_IDLE;
			} else if (in2ccMd.empty() == false && in2cc.empty() == false && hash2cc.empty() == false) {
				in2cc.read(ccInputWord);
				in2ccMd.read(ccInputWordMd);
				hash2cc.read(hashInputWord);

				// XXX hashInputWord is the computed hash value why -4?
				// All types of operations are pushed into this checking FIFO.
				ccCompareElement.address = hashInputWord.range(noOfHashTableEntries-4, 0);
				ccCompareElement.operation = ccInputWordMd.operation;

				// Assign 32b hash value
				// what a fucking shitty name.
				ccInputWordMd.metadata = hashInputWord;

				// TODO
				// Even if there is no conflict,
				// the hashFilter has to be large enough
				// to not block any incoming requests..
				if (hashFilter.compare(ccCompareElement) || hashFilter.full()) {
					ccState = CC_WAIT;
				} else {
					/*ccCompareElement.status = 1;
					hashFilter.push(ccCompareElement);
					cc2memReadMd.write(ccInputWordMd);
					cc2memRead.write(ccInputWord);
					if (ccInputWord.EOP != 1)
						ccState = CC_STREAM;*/
					ccState = CC_PUSH;
				}
			}
			break;

		case CC_WAIT:
			if (dec2cc.empty() == false)
				ccState = CC_POP_WAIT;
			else {
				// If the pipeline is to be stalled
				if (!hashFilter.full() && !hashFilter.compare(ccCompareElement))
					ccState = CC_PUSH;
			}
			break;

		case CC_PUSH:
			// This state pushes the saved stuff into the hashFilter
			// it will be checked by later requests
			//
			// Also push the key and metadata into another two streams.

			ccCompareElement.status = 1;
			hashFilter.push(ccCompareElement);

			cc2memRead.write(ccInputWord);
			cc2memReadMd.write(ccInputWordMd);

			if (ccInputWord.EOP != 1)
				ccState = CC_STREAM;
			else
				ccState = CC_IDLE;
			break;

		case CC_STREAM:
			if (in2cc.empty())
				break;
			in2cc.read(ccInputWord);
			cc2memRead.write(ccInputWord);
			if (ccInputWord.EOP == 1)
				ccState = CC_IDLE;
			break;

		/*
		 * XXX
		 * Okay, now I know stuff is pushed
		 * when a request comes in
		 * when it got pop'ed?
		 */
		case CC_POP_IDLE:
		{
			if (dec2cc.empty())
				break;
			ap_uint<1> pop = 0;
			dec2cc.read(pop);
			if (pop == 1)
				hashFilter.pop();
			ccState = CC_IDLE;
			break;
		}
		case CC_POP_WAIT:
		{
			if (dec2cc.empty())
				break;
			ap_uint<1> pop = 0;
			dec2cc.read(pop);
			if (pop == 1)
				hashFilter.pop();
			ccState = CC_WAIT;
			break;
		}
	}
}
