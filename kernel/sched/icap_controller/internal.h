/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */
#ifndef _KERNEL_SCHED_ICAP_HLS_H_
#define _KERNEL_SCHED_ICAP_HLS_H_

#include <fpga/icap.h>

enum COMMAND_FUNCTION_STATUS {
	CMD_DONE,
	CMD_WIP,
};

#define FSM_NEXT(_state, _next)	\
	do {			\
		_state = _next;	\
	} while (0)

extern struct icap_register_entry icap_register_table[];

unsigned int cook_cmd(int reg_nr);
void update_COMMAND_regs_1(unsigned int cmd);

int cmd_read_regs(hls::stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
		  hls::stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
		  volatile ap_uint<1> *CSIB_to_icap,
		  volatile ap_uint<1> *RDWRB_to_icap,
		  int reg_nr,
		  int *reg_data);

int cmd_read_bitstreams(hls::stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
			hls::stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
			volatile ap_uint<1> *CSIB_to_icap,
			volatile ap_uint<1> *RDWRB_to_icap,
			volatile int *O_nr_bytes,
			volatile int *frame_addr);

#endif /* _KERNEL_SCHED_ICAP_HLS_H_ */
