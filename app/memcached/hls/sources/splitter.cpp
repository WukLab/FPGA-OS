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

void splitter(stream<pipelineWord> &valueSplitterIn, stream<pipelineWord> &valueSplitterOut2valueStoreFlash, stream<pipelineWord> &valueSplitterOut2valueStoreDram) {	// This modules routes request to either the VS attached to the DRAM or the one attached to the Flash, depending on their value length
	#pragma HLS INLINE off
	#pragma HLS pipeline II=1

	static bool 		is_validFlag 	= false;
	static ap_uint<1>	dramOrFlash		= 0;	// 0 = Flash, 1 = DRAM

	if (!valueSplitterIn.empty()) {
		pipelineWord inputWord = valueSplitterIn.read();
		if (inputWord.SOP == 1) {
			is_validFlag = true;
			if (inputWord.metadata.range(39, 8) > splitLength)
				dramOrFlash = 0;
			else
				dramOrFlash = 1;
		}
		if (is_validFlag) {
			if (dramOrFlash == 0)
				valueSplitterOut2valueStoreFlash.write(inputWord);
			else if (dramOrFlash == 1)
				valueSplitterOut2valueStoreDram.write(inputWord);
			if (inputWord.EOP == 1)
				is_validFlag = false;
		}
	}

}
