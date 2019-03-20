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
//#include "globals.hpp"
#include "arp_server.hpp"

#define NO_OF_BROADCASTS 2

/** @ingroup arp_server
 *
 */
void arp_pkg_receiver(stream<axiWord>&        	arpDataIn,
                      stream<arpReplyMeta>&   	arpReplyMetaFifo,
                      stream<arpTableEntry>&  	arpTableInsertFifo,
                      ap_uint<32>	      		regIpAddress) {
#pragma HLS PIPELINE II=1
  static uint16_t 		wordCount = 0;
  static ap_uint<16>	opCode;
  static ap_uint<32>	protoAddrDst;
  static ap_uint<32>	inputIP;
  static arpReplyMeta meta;
  
  axiWord currWord = {0, 0, 0};
  
  if (!arpDataIn.empty()) {
		arpDataIn.read(currWord);
		switch(wordCount) {
		//TODO DO MAC ADDRESS Filtering somewhere, should be done in/after mac
			case 0:
				//MAC_DST = currWord.data(47, 0);
				meta.srcMac(15, 0) = currWord.data(63, 48);
				break;
			case 1:
				meta.srcMac(47 ,16) = currWord.data(31, 0);
				meta.ethType 		= currWord.data(47, 32);
				meta.hwType 		= currWord.data(63, 48);
				break;
			case 2:
				meta.protoType 			= currWord.data(15, 0);
				meta.hwLen 				= currWord.data(23, 16);
				meta.protoLen 			= currWord.data(31, 24);
				opCode 					= currWord.data(47, 32);
				meta.hwAddrSrc(15,0) 	= currWord.data(63, 48);
				break;
			case 3:
				meta.hwAddrSrc(47, 16) 	= currWord.data(31, 0);
				meta.protoAddrSrc 		= currWord.data(63, 32);
				break;
			case 4:
				protoAddrDst(15, 0) = currWord.data(63, 48);
				break;
			case 5:
				protoAddrDst(31, 16) = currWord.data(15, 0);
				break;
			default:
				break;
		} //switch
		if (currWord.last == 1) {
			if ((opCode == REQUEST) && (protoAddrDst == regIpAddress))
				arpReplyMetaFifo.write(meta);
			arpTableInsertFifo.write(arpTableEntry(meta.hwAddrSrc, meta.protoAddrSrc, true));
			wordCount = 0;
		}
		else
			wordCount++;
	}
}

/** @ingroup arp_server
 *
 */
void arp_pkg_sender(stream<arpReplyMeta>&     	arpReplyMetaFifo,
                    stream<ap_uint<32> >&     	arpRequestMetaFifo,
                    stream<axiWord>&          	arpDataOut,
                    ap_uint<32>		      		regIpAddress,
                    ap_uint<48>					myMacAddress) {
#pragma HLS PIPELINE II=1
  enum arpSendStateType {ARP_IDLE, ARP_REPLY, ARP_SENTRQ};
  static arpSendStateType aps_fsmState = ARP_IDLE;
  
  static uint16_t			sendCount = 0;
  static arpReplyMeta		replyMeta;
  static ap_uint<32>		inputIP;
  
  axiWord sendWord = {0, 0xFF, 0};
  
  switch (aps_fsmState) {
   case ARP_IDLE:
   sendCount = 0;
    if (!arpReplyMetaFifo.empty()) {
      arpReplyMetaFifo.read(replyMeta);
      aps_fsmState = ARP_REPLY;
    }
    else if (!arpRequestMetaFifo.empty()) {
      arpRequestMetaFifo.read(inputIP);
      aps_fsmState = ARP_SENTRQ;
    }
    break;
  case ARP_SENTRQ:
		switch(sendCount) {
			case 0:
				sendWord.data.range(47, 0)  = BROADCAST_MAC;
				sendWord.data.range(63, 48) = myMacAddress.range(15, 0);
				break;
			case 1:
				sendWord.data.range(31, 0)  = myMacAddress.range(47, 16);
				sendWord.data.range(63, 32) = 0x01000608;
				break;
			case 2:
				sendWord.data.range(31, 0) = 0x04060008;							// Protocol Address Length, HW Address Length & IP Address
				sendWord.data.range(47, 32) = REQUEST;
				sendWord.data.range(63, 48) = myMacAddress.range(15, 0);
				break;
			case 3:
				sendWord.data.range(31, 0)  = myMacAddress.range(47, 16);
				sendWord.data.range(63, 32) = regIpAddress;//MY_IP_ADDR;
				break;
			case 4:
				sendWord.data.range(63, 48) = inputIP.range(15, 0);
				break;
			case 5:
				sendWord.data.range(15, 0)  = inputIP.range(31, 16);
				sendWord.keep = 0x03;
				sendWord.last = 1;
				aps_fsmState = ARP_IDLE;
				break;
		} //switch sendcount
		arpDataOut.write(sendWord);
		sendCount++;
		break;
  case ARP_REPLY:
		  switch(sendCount) {
			case 0:
				sendWord.data = (myMacAddress(15, 0), replyMeta.srcMac);
				break;
			case 1:
				sendWord.data = (replyMeta.hwType, replyMeta.ethType, myMacAddress(47, 16));
				break;
			case 2:
				sendWord.data = (myMacAddress(15, 0), REPLY, replyMeta.protoLen, replyMeta.hwLen, replyMeta.protoType);
				break;
			case 3:
				sendWord.data(31, 0)  = myMacAddress(47, 16);
				sendWord.data(63, 32) = regIpAddress;//MY_IP_ADDR, maybe use proto instead
				break;
			case 4:
				sendWord.data	= (replyMeta.protoAddrSrc(15, 0), replyMeta.hwAddrSrc); 
				break;
			case 5:
				sendWord.data(15, 0) = replyMeta.protoAddrSrc(31, 16);
				sendWord.keep = 0x03;
				sendWord.last = 1;
				aps_fsmState = ARP_IDLE;
				break;
			} //switch
			arpDataOut.write(sendWord);
			sendCount++;
			break;
  } //switch
}

/** @ingroup arp_server
 *
 */
void arp_table(stream<arpTableEntry> &arpTableInsertFifo, stream<ap_uint<32> > &macIpEncode_req, stream<arpTableReply> &macIpEncode_rsp, stream<ap_uint<32> > &arpRequestMetaFifo,
			   stream<rtlMacLookupRequest>	&macLookup_req, stream<rtlMacLookupReply> &macLookup_resp, stream<rtlMacUpdateRequest> &macUpdate_req, stream<rtlMacUpdateReply> &macUpdate_resp) {
	#pragma HLS PIPELINE II=1

	static enum aState {ARP_IDLE, ARP_UPDATE, ARP_LOOKUP} arpState;
	static ap_uint<32>	at_inputIP;
	
	switch(arpState) {
	case ARP_IDLE:
		if (!arpTableInsertFifo.empty()) {
			arpTableEntry queryResult = arpTableInsertFifo.read();
			macUpdate_req.write(rtlMacUpdateRequest(queryResult.ipAddress, queryResult.macAddress, 0));
			arpState = ARP_UPDATE;
		}
		if (!macIpEncode_req.empty()) {
			at_inputIP = macIpEncode_req.read();
			if (at_inputIP == 0xFFFFFFFF) {	// If the destination is the IP broadcast address
				macIpEncode_rsp.write(arpTableReply(BROADCAST_MAC, 1));	// Immediately return
				arpState = ARP_IDLE;
			}
			else {
				macLookup_req.write(rtlMacLookupRequest(at_inputIP)); //Create the request format
				arpState = ARP_LOOKUP;
			}
		}
		break;
	case ARP_UPDATE:
		if(!macUpdate_resp.empty()) {
			macUpdate_resp.read();	// Consume the reply without actually acting on it
			arpState = ARP_IDLE;
		}
		break;
	case ARP_LOOKUP:
		if(!macLookup_resp.empty()) {
			rtlMacLookupReply tempReply = macLookup_resp.read();
			macIpEncode_rsp.write(arpTableReply(tempReply.value, tempReply.hit));
			if (!tempReply.hit) // If the result is not found then fire a MAC request
				arpRequestMetaFifo.write(at_inputIP); // send ARP request
			arpState = ARP_IDLE;
		}
		break;
	}
}

/** @ingroup arp_server
 *
 */
void arp_server(  stream<axiWord>&          	arpDataIn,
                  stream<ap_uint<32> >&     	macIpEncode_req,
				  stream<axiWord>&          	arpDataOut,
				  stream<arpTableReply>&    	macIpEncode_rsp,
				  stream<rtlMacLookupRequest>	&macLookup_req,
				  stream<rtlMacLookupReply>		&macLookup_resp,
				  stream<rtlMacUpdateRequest>	&macUpdate_req,
				  stream<rtlMacUpdateReply>		&macUpdate_resp,
				  ap_uint<32>					regIpAddress,
				  ap_uint<48>					myMacAddress)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS DATAFLOW

	/*#pragma HLS INTERFACE port=arpDataIn 		axis
	#pragma HLS INTERFACE port=arpDataOut 		axis
	#pragma HLS INTERFACE port=macIpEncode_req 	axis
	#pragma HLS INTERFACE port=macIpEncode_rsp 	axis
	#pragma HLS INTERFACE port=macLookup_req 	axis
	#pragma HLS INTERFACE port=macLookup_resp 	axis
	#pragma HLS INTERFACE port=macUpdate_req 	axis
	#pragma HLS INTERFACE port=macUpdate_resp 	axis*/
	
	#pragma  HLS resource core=AXI4Stream variable=arpDataIn 		metadata = "-bus_bundle arpDataIn"
	#pragma  HLS resource core=AXI4Stream variable=arpDataOut 		metadata = "-bus_bundle arpDataOut"
	#pragma  HLS resource core=AXI4Stream variable=macIpEncode_req 	metadata = "-bus_bundle macIpEncode_req"
	#pragma  HLS resource core=AXI4Stream variable=macIpEncode_rsp 	metadata = "-bus_bundle macIpEncode_rsp"
	#pragma	 HLS resource core=AXI4Stream variable = macLookup_req	metadata = "-bus_bundle macLookup_req"
	#pragma	 HLS resource core=AXI4Stream variable = macLookup_resp	metadata = "-bus_bundle macLookup_resp"
	#pragma	 HLS resource core=AXI4Stream variable = macUpdate_req	metadata = "-bus_bundle macUpdate_req"
	#pragma	 HLS resource core=AXI4Stream variable = macUpdate_resp	metadata = "-bus_bundle macUpdate_resp"
	#pragma  HLS INTERFACE ap_none register port=regIpAddress
	#pragma  HLS INTERFACE ap_stable port=myMacAddress

  	#pragma HLS DATA_PACK variable=macIpEncode_rsp
	#pragma HLS DATA_PACK variable=macLookup_req
	#pragma HLS DATA_PACK variable=macLookup_resp
	#pragma HLS DATA_PACK variable=macUpdate_req
	#pragma HLS DATA_PACK variable=macUpdate_resp

  static stream<arpReplyMeta>     arpReplyMetaFifo("arpReplyMetaFifo");
  #pragma HLS STREAM variable=arpReplyMetaFifo depth=4
  #pragma HLS DATA_PACK variable=arpReplyMetaFifo
  
  static stream<ap_uint<32> >   arpRequestMetaFifo("arpRequestMetaFifo");
  #pragma HLS STREAM variable=arpRequestMetaFifo depth=4
  //#pragma HLS DATA_PACK variable=arpRequestMetaFifo

  static stream<arpTableEntry>    arpTableInsertFifo("arpTableInsertFifo");
  #pragma HLS STREAM variable=arpTableInsertFifo depth=4
  #pragma HLS DATA_PACK variable=arpTableInsertFifo
  static ap_uint<32> intIpAddress[NO_OF_BROADCASTS];

  //broadcaster<ap_uint<32> >(regIpAddress, intIpAddress);
  //arp_pkg_receiver(arpDataIn, arpReplyMetaFifo, arpTableInsertFifo, intIpAddress[0]);
  //arp_pkg_sender(arpReplyMetaFifo, arpRequestMetaFifo, arpDataOut, intIpAddress[1]);

  arp_pkg_receiver(arpDataIn, arpReplyMetaFifo, arpTableInsertFifo, regIpAddress);
  arp_pkg_sender(arpReplyMetaFifo, arpRequestMetaFifo, arpDataOut, regIpAddress, myMacAddress);
  arp_table(arpTableInsertFifo, macIpEncode_req, macIpEncode_rsp, arpRequestMetaFifo,
		  macLookup_req, macLookup_resp, macUpdate_req, macUpdate_resp);
}
