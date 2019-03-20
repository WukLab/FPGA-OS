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

accessFilter::accessFilter(){
	this->wrPtr = 0;
	this->rdPtr = 0;
	this->level = 0;
#pragma HLS array_partition variable=filterEntries complete
}

bool accessFilter::push(accessWord newElement)
{
	if (this->level < concFilterEntries) // if the queue is not full
	{
		this->filterEntries[this->wrPtr] = newElement;
		this->wrPtr == concFilterEntries-1 ? this->wrPtr = 0 : this->wrPtr++;
		this->level++;
		return true;
	}
	else return false;
}

bool accessFilter::pop()
{
	this->filterEntries[this->rdPtr].address 	= 0;
	this->filterEntries[this->rdPtr].status 	= 0;
	this->rdPtr == concFilterEntries-1 ? this->rdPtr = 0 : this->rdPtr++;
	this->level--;
	return true;
}

bool accessFilter::compare(accessWord compareElement)
{
	//#pragma HLS INLINE off
	for (uint8_t i=0;i<concFilterEntries;++i)	// Go through all the entries in the filter
	{
		if (this->filterEntries[i].status == 1 && compareElement.address == this->filterEntries[i].address && (compareElement.operation == 1 && this->filterEntries[i].operation == 0)) // Check three things: 1) The entry must be valid. 2) The addresses must match. 3) The operation of the address stored in the filter must be a SET
			return true;	// If all these conditions are met then return true;
	}
	return false;
}

bool accessFilter::full() {
	if (this->level == concFilterEntries)
		return true;
	else
		return false;
}

concurrencyFilter::concurrencyFilter(){
	this->wrPtr = 0;
	this->rdPtr = 0;
	this->level = 0;
#pragma HLS array_partition variable=filterEntries complete
}

bool concurrencyFilter::push(decideResultWord newElement)
{
	if (this->level < concFilterEntries) // if the queue is not full
	{
		this->filterEntries[this->wrPtr] = newElement;
		this->wrPtr == concFilterEntries-1 ? this->wrPtr = 0 : this->wrPtr++;
		this->level++;
		return true;
	}
	else return false;
}

bool concurrencyFilter::pop()
{
	this->filterEntries[this->rdPtr].address 	= 0;
	this->filterEntries[this->rdPtr].status 	= 0;
	this->rdPtr == concFilterEntries-1 ? this->rdPtr = 0 : this->rdPtr++;
	this->level--;
	return true;
}

bool concurrencyFilter::compare(decideResultWord compareElement)
{
	//#pragma HLS INLINE off
	for (uint8_t i=0;i<concFilterEntries;++i)	// Go through all the entries in the filter
	{
		if (this->filterEntries[i].status == 1 && compareElement.address == this->filterEntries[i].address && this->filterEntries[i].operation == 1) // Check three things: 1) The entry must be valid. 2) The addresses must match. 3) The operation of the address stored in the filter must be a SET
			return true;	// If all these conditions are met then return true;
	}
	return false;
}

bool concurrencyFilter::full() {
 if (this->level == concFilterEntries)
	 return true;
 else
	 return false;
}

int myPow(const short int &exp)
{
	int result = 1;
	for (int i=0;i<32;++i)
	{
		if (i<exp)
			result *= 2;
	}
	return result;
}
