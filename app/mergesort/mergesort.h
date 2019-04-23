#ifndef _MERGESORT_H_
#define _MERGESORT_H_

#define SCRATCH_ARRAY_SIZE 4096 // Number of integers loaded and sorted in BRAM at a time
#define va_arr_ptr 0x00002000

void merge (ap_uint<32> scratch_arr[], int l, int m, int r);

#endif /* _MERGESORT_H_ */
