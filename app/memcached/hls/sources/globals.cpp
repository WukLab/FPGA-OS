#include "globals.h"

#if 0
accessFilter::accessFilter(){
	this->wrPtr = 0;
	this->rdPtr = 0;
	this->level = 0;
#pragma HLS array_partition variable=filterEntries complete
}

bool accessFilter::push(accessWord newElement) {
	if (this->level < accFilterEntries) {	// if the queue is not full
		this->filterEntries[this->wrPtr] = newElement;
		this->wrPtr == accFilterEntries-1 ? this->wrPtr = 0 : this->wrPtr++;
		this->level++;
		return true;
	}
	else return false;
}

bool accessFilter::pop() {
	this->filterEntries[this->rdPtr].address 	= 0;
	this->filterEntries[this->rdPtr].status 	= 0;
	this->rdPtr == accFilterEntries-1 ? this->rdPtr = 0 : this->rdPtr++;
	this->level--;
	return true;
}

bool accessFilter::compare(accessWord compareElement) {
//#pragma HLS INLINE off
	for (uint8_t i=0;i<accFilterEntries;++i) { 
	#pragma HLS UNROLL
		/*
		 * Address here is the value's DRAM address
		 * So this one is used to detect RAW for same Key (thus same value address)
		 */
		if (this->filterEntries[i].status == 1 &&
		    compareElement.address == this->filterEntries[i].address &&
		    (compareElement.operation == 0 && this->filterEntries[i].operation == 1)) {
		    	// Check three things:
			// 1) The entry must be valid.
			// 2) The addresses must match.
			// 3) The operation of the address stored in the filter must be a SET
			//
			// For the same Value address, check read-after-write.
			// If happen, stall.
			return true;	// If all these conditions are met then return true;
		}
	}
	return false;
}

bool accessFilter::full() {
	if (this->level == accFilterEntries)
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

bool concurrencyFilter::push(ccWord newElement)
{
#pragma HLS INLINE
	if (this->level < concFilterEntries) {
		// if the queue is not full
		this->filterEntries[this->wrPtr] = newElement;
		this->wrPtr == concFilterEntries-1 ? this->wrPtr = 0 : this->wrPtr++;
		this->level++;
		return true;
	}
	else return false;
}

bool concurrencyFilter::pop()
{
#pragma HLS INLINE
	this->filterEntries[this->rdPtr].address 	= 0;
	this->filterEntries[this->rdPtr].status 	= 0;
	this->rdPtr == concFilterEntries-1 ? this->rdPtr = 0 : this->rdPtr++;
	this->level--;
	return true;
}

bool concurrencyFilter::compare(ccWord compareElement)
{
	//#pragma HLS INLINE off

	// Go through all the entries in the filter
	for (uint8_t i = 0; i < concFilterEntries; i++) {
	#pragma HLS UNROLL
		// opcode=0 GET
		// opcode=1 SET
		// opcode=4 DEL/FLUSH?
		// opcode=8 DEL/FLUSH?
		//
		// address here is the portion of the 32b computer hash value
		// So this function is trying to detect SET/SET dependency
		//
		if ((this->filterEntries[i].status == 1 &&
		     compareElement.address == this->filterEntries[i].address &&
		     (this->filterEntries[i].operation == 1 || this->filterEntries[i].operation == 4)) ||
		     (this->filterEntries[i].operation == 8 && this->filterEntries[i].status == 1)) {
		     	// Check three things:
			// 1) The entry must be valid.
			// 2) The addresses must match.
			// 3) The operation of the address stored in the filter must be a SET
			// If all these conditions are met then return true;
			// 
			// Two SET to the same KEY will stall.
			// But read-after-write to the same KEY is not detected here
			// Detected in the accessFilter->compare()
			return true;
		}
	}
	return false;
}

bool concurrencyFilter::full() {
 if (this->level == concFilterEntries)
	 return true;
 else
	 return false;
}
#else
accessFilter::accessFilter(){
	this->wrPtr = 0;
	this->rdPtr = 0;
	this->level = 0;
#pragma HLS array_partition variable=filterEntries complete
}

bool accessFilter::push(accessWord newElement)
{
	return true;
}

bool accessFilter::pop() {
	return true;
}

bool accessFilter::compare(accessWord compareElement)
{
	return false;
}

bool accessFilter::full()
{
	return false;
}

concurrencyFilter::concurrencyFilter()
{
	this->wrPtr = 0;
	this->rdPtr = 0;
	this->level = 0;
#pragma HLS array_partition variable=filterEntries complete
}

bool concurrencyFilter::push(ccWord newElement)
{
	return true;
}

bool concurrencyFilter::pop()
{
	return true;
}

bool concurrencyFilter::compare(ccWord compareElement)
{
	return false;
}

bool concurrencyFilter::full()
{
	return false;
}
#endif

int myPow(const short int &exp) {
	int result = 1;
	for (int i=0;i<32;++i) {
		if (i<exp)
			result *= 2;
	}
	return result;
}

ap_uint<32> byteSwap32(ap_uint<32> inputVector) {
	return (inputVector.range(7,0), inputVector(15, 8), inputVector(23, 16), inputVector(31, 24));
}

ap_uint<16> byteSwap16(ap_uint<16> inputVector) {
	return (inputVector.range(7,0), inputVector(15, 8));
}
