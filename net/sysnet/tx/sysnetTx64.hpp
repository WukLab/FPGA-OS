#ifndef _SYSNETTX64_H_
#define _SYSNETTX64_H_

#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"


#define FIFO_WIDTH	64
#define NUM_APPS    2


template <int N >
struct my_axis {
	ap_uint<N>				data;
	ap_uint<1>				last;
	ap_uint<1>				tuser;
	ap_uint<N/8> 			tkeep;
	//ap_uint<N/8>			ifg_delay;
};


void tx_func(hls::stream<struct my_axis<FIFO_WIDTH> > *input0,
	      hls::stream<struct my_axis<FIFO_WIDTH> > *input1,
		  hls::stream<struct my_axis<FIFO_WIDTH> > *output);


#endif /* _SYSNETTX64_H_ */
