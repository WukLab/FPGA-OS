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

void dummyPCIeJoint(stream<ap_uint<32> > &inData, stream<ap_uint<32> > &outDataFlash, stream<ap_uint<32> > &outDataDram,
					ap_uint<1> flushReq, ap_uint<1> &flushAck, ap_uint<1> flushDone) {
					
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE ap_none register port=flushReq 
	#pragma HLS INTERFACE ap_none register port=flushAck
	#pragma HLS INTERFACE ap_none register port=flushDone
	#pragma HLS pipeline II=1
	
	/*#pragma HLS INTERFACE port=inData			axis
	#pragma HLS INTERFACE port=outDataFlash		axis
	#pragma HLS INTERFACE port=outDataDram		axis*/

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
	
	#pragma HLS STREAM variable=freeAddressArrayDram depth=64
	#pragma HLS STREAM variable=freeAddressArrayFlash depth=32
	//                     0                1              2             3               4                   5                6               7                 8                9                A
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
			pcie_flushAck 	= 0;
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
					flushFlag 	= false;
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
			//}
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
				pcie_flushAck 	= 1;
				flushFlag 		= true;
				pcieState 		= PCI_INIT_DRAM;
			}
			break;
		case PCI_WAITFORDONE:
			if (flushDone == 1)
				pcieState 	= PCI_IDLE;
			break;
	}
	flushAck = pcie_flushAck;
}

