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


void memRead(stream<hashTableInternalWord> &cc2memRead, stream<internalMdWord> &cc2memReadMd, stream<memCtrlWord> &memRdCtrl, stream<hashTableInternalWord> &memRd2comp, stream<internalMdWord> &memRd2compMd) {

	#pragma HLS INLINE off
	#pragma HLS pipeline II=1 enable_flush

	memCtrlWord				memData 	= {0, 0};
	hashTableInternalWord	inData		= {0, 0, 0};
	internalMdWord			inDataMd 	= {0, 0, 0};
	static enum 			mrState {MEMRD_IDLE, MEMRD_STREAM} memRdState;

	switch (memRdState)	{
		case MEMRD_IDLE:
		{
			if (!cc2memReadMd.empty() && !cc2memRead.empty()) {
				cc2memReadMd.read(inDataMd);
				cc2memRead.read(inData);

				if (inDataMd.operation != 8) {
					//ap_uint<7> tempAddress = inDataMd.metadata.range(noOfHashTableEntries + 4, 8);
					ap_uint<32> tempAddress = inDataMd.metadata;
					memData.address.range(noOfHashTableEntries - 1, 3)  = tempAddress.range(6, 0);
					memData.count	= inDataMd.keyLength/16;
					if (inDataMd.keyLength > (memData.count*16))
						memData.count += 2;
					else
						memData.count += 1;
					memRdCtrl.write(memData);
				}
				if (inDataMd.keyLength <= 16) {
					ap_uint<64*words2aggregate> tempData = 0;
					tempData.range((inDataMd.keyLength*8) - 1, 0) = inData.data.range((inDataMd.keyLength*8) - 1, 0);
					inData.data = tempData;
				}
				memRd2comp.write(inData);
				memRd2compMd.write(inDataMd);
				if (inData.EOP == 0)
					memRdState = MEMRD_STREAM;
			}
			break;
		}
		case MEMRD_STREAM:
		{
			cc2memRead.read(inData);
			memRd2comp.write(inData);
			if (inData.EOP == 1)
				memRdState = MEMRD_IDLE;
			break;
		}
	}
}
