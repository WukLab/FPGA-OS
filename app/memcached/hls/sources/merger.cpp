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

void merger(stream<pipelineWord> &flash2valueMerger, stream<pipelineWord> &dram2valueMerger, stream<pipelineWord> &valueMerger2responseFormatter) {	// This modules recombines the results from the flash and DRAM value stores into one strea and sends them on to the response formatter
#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INLINE off
#pragma HLS pipeline II=1

	static enum mState{M_IDLE = 0, M_STREAM} mergerState;
	static ap_uint<1>	dramOrFlash		= 0;	// 0 = Flash, 1 = DRAM

	switch (mergerState) {
	case M_IDLE:
		if (!flash2valueMerger.empty()) {
			valueMerger2responseFormatter.write(flash2valueMerger.read());
			dramOrFlash = 0;
			mergerState = M_STREAM;
		}
		else if (!dram2valueMerger.empty()) {
			valueMerger2responseFormatter.write(dram2valueMerger.read());
			dramOrFlash = 1;
			mergerState = M_STREAM;
		}
		break;
	case M_STREAM:
		pipelineWord outputWord = {0, 0, 0};
		if (dramOrFlash == 0 && !flash2valueMerger.empty()) {
			flash2valueMerger.read(outputWord);
			valueMerger2responseFormatter.write(outputWord);
			if (outputWord.EOP == 1)
				mergerState = M_IDLE;
		}
		else if (dramOrFlash == 1 && !dram2valueMerger.empty()) {
			dram2valueMerger.read(outputWord);
			valueMerger2responseFormatter.write(outputWord);
			if (outputWord.EOP == 1)
				mergerState = M_IDLE;
		}
		break;
	}
}
