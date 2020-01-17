/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <string.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>
#include <hls_stream.h>
#include <fpga/kernel.h>
#include <fpga/icap.h>
#include <uapi/compiler.h>
#include "internal.h"

using namespace hls;

static unsigned int COMMAND_iprog[] = {
	0xFFFFFFFF,	/* Ignored dummy word */
	0xAA995566,	/* Sync Word */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x30020001,	/* Packet I. Opcode=Write, Register=WBSTAR	10000 */
	0x00000000,	/*	Warm boot start address 0 */
	0x20000000,	/* NOOP */
	0x30008001,	/* Packet I. Opcode=Write, Register=CMD		00100 */
	0x0000000F,	/*	IPROG command */
};

static int cmd_iprog(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
		     stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
		     volatile ap_uint<1> *CSIB_to_icap,
		     volatile ap_uint<1> *RDWRB_to_icap)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	enum CMD_IPROG_STATE {
		IPROG_IDLE,
		IPROG_WRITE_1,
	};
	static enum CMD_IPROG_STATE state = IPROG_IDLE;
	static int nr;
	ap_uint<ICAP_DATA_WIDTH> data;

	switch (state) {
	case IPROG_IDLE:
		nr = 0;
		state = IPROG_WRITE_1;
		break;
	case IPROG_WRITE_1:
		*CSIB_to_icap = ICAP_CSIB_ENABLE;
		*RDWRB_to_icap = ICAP_RDWRB_WRITE;

		if (nr < ARRAY_SIZE(COMMAND_iprog)) {
			data = COMMAND_iprog[nr];
			to_icap->write(data);
			nr++;
		} else
			FSM_NEXT(state, IPROG_IDLE);
		break;
	};

	if (state == IPROG_IDLE)
		return CMD_DONE;
	else
		return CMD_WIP;
}

/*
 * Description about ICAPE3 Pin (UG570):
 * AVAIL (O):	ICAP available
 * CSIB (I):	Active-Low ICAP input enable
 * I[31:0]:	Configuration data input bus to ICAP
 * O[31:0]:	Configuration data output bus from ICAP. If no data is beging
 *		read, contains current status.
 * PRDONE (O):	PR Complete. Default is high. Goes Low when FDRI packet is seen,
 *		and goes back High when DESYNC is seen and EOS is High.
 * PRERROR (O):	PR error. Default is Low. Goes High when partial configuration
 * 		bitstream error is detected. Can be reset by loading RCRC command.
 * RDWRB (I):	Read (Active High) or Write (Active Low) Select input.
 */
void icap_controller_hls(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
			 stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
			 volatile ap_uint<1> *AVAIL_from_icap,
			 volatile ap_uint<1> *PRDONE_from_icap,
			 volatile ap_uint<1> *PRERROR_from_icap,
			 volatile ap_uint<1> *CSIB_to_icap,
			 volatile ap_uint<1> *RDWRB_to_icap,
			 volatile ap_uint<1> *start_test,
			 volatile ap_uint<1> *reset_test,
			 volatile int *frame_addr,
			 volatile int *O_nr_bytes)
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_ctrl_none port=return

#pragma HLS INTERFACE axis both port=from_icap
#pragma HLS INTERFACE axis both port=to_icap
#pragma HLS INTERFACE ap_none port=AVAIL_from_icap
#pragma HLS INTERFACE ap_none port=PRDONE_from_icap
#pragma HLS INTERFACE ap_none port=PRERROR_from_icap
#pragma HLS INTERFACE ap_ovld port=CSIB_to_icap
#pragma HLS INTERFACE ap_ovld port=RDWRB_to_icap

#pragma HLS INTERFACE ap_none port=start_test
#pragma HLS INTERFACE ap_none port=reset_test
#pragma HLS INTERFACE ap_none port=frame_addr
#pragma HLS INTERFACE ap_none port=O_nr_bytes

	enum icap_controller_hls_state {
		IDLE_ICAP_INACTIVE,
		IDLE_ICAP_ACTIVE,
		STATE_OP_START,
		STATE_DONE,
	};
	static enum icap_controller_hls_state state;

	static int test_cmd = 0;
	static int register_addr;
	static int _nr_test = 0;

	switch (state) {
	case IDLE_ICAP_INACTIVE: {
		ap_uint<1> avail;
		ap_uint<1> _start_test, _reset_test;

		_start_test = *start_test;
		if (_start_test.to_uint() == 0) {
			FSM_NEXT(state, IDLE_ICAP_INACTIVE);
			break;
		}

		_reset_test = *reset_test;
		if (_reset_test.to_uint() == 1)
			_nr_test = 0;

#if 1
		/*
		 * Just for testing
		 */
		if (_nr_test == 0) {
			test_cmd = 0;
			register_addr = ICAP_REG_IDCODE;
			_nr_test++;
		} else if (_nr_test == 1) {
			test_cmd = 2;
			//test_cmd = 0;
			//register_addr = ICAP_REG_STAT;
			_nr_test++;
		} else if (_nr_test == 2) {
			test_cmd = 0;
			register_addr = ICAP_REG_IDCODE;
			_nr_test++;
		} else {
			FSM_NEXT(state, IDLE_ICAP_INACTIVE);
			break;
		}
#endif

		avail = *AVAIL_from_icap;
		if (avail.to_int() == 0)
			FSM_NEXT(state, IDLE_ICAP_INACTIVE);
		else if (avail.to_uint() == 1)
			FSM_NEXT(state, IDLE_ICAP_ACTIVE);

		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		break;
	}
	case IDLE_ICAP_ACTIVE: {
		ap_uint<1> avail;

		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;

		avail = *AVAIL_from_icap;
		if (avail.to_int() == 0) {
			FSM_NEXT(state, IDLE_ICAP_INACTIVE);
			break;
		}

		FSM_NEXT(state, STATE_OP_START);
		break;
	}

	case STATE_OP_START: {
		int ret = CMD_DONE;
		int reg_data = 0;

		/*
		 * This is more like a use case demonstration.
		 */
		switch (test_cmd) {
		case 0: {
			ret = cmd_read_regs(from_icap, to_icap,
					    CSIB_to_icap, RDWRB_to_icap,
					    register_addr, &reg_data);
			break;
		}
		case 1:
			ret = cmd_iprog(from_icap, to_icap,
					CSIB_to_icap, RDWRB_to_icap);
			break;
		case 2:
			ret = cmd_read_bitstreams(from_icap, to_icap,
						  CSIB_to_icap, RDWRB_to_icap,
						  O_nr_bytes, frame_addr);
			break;
		default:
			ret = CMD_DONE;
			break;
		}
		if (ret == CMD_DONE)
			FSM_NEXT(state, STATE_DONE);
		break;
	}
	case STATE_DONE:
		/* Disable the ICAP */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		FSM_NEXT(state, IDLE_ICAP_INACTIVE);
		break;
	default:
		HLS_BUG();
		break;
	}
}
