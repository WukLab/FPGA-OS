/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */

#include <string.h>
#include <fpga/kernel.h>
#include <uapi/compiler.h>
#include <ap_int.h>
#include <ap_axi_sdata.h>
#include <hls_stream.h>
#include "internal.h"

using namespace hls;

enum icap_controller_hls_state {
	IDLE_ICAP_INACTIVE,
	IDLE_ICAP_ACTIVE,

	STATE_OP_START,
	STATE_OP_STREAM,

	STATE_DONE,
};

static unsigned int COMMAND_stat[] = {
	0xFFFFFFFF,	/* Ignored */
	0xAA995566,	/* Sync Word */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x2800E001,	/* Packet I. Opcode=Read, Register=STAT		00111 */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
};

static unsigned int COMMAND_iprog[] = {
	0xFFFFFFFF,	/* Ignored */
	0xAA995566,	/* Sync Word */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x30020001,	/* Packet I. Opcode=Write, Register=WBSTAR	10000 */
	0x00000000,	/*	Warm boot start address 0 */
	0x20000000,	/* NOOP */
	0x30008001,	/* Packet I. Opcode=Write, Register=CMD		00100 */
	0x0000000F,	/*	IPROG command */
};

#define NEXT(_state, _next)	\
	do {			\
		_state = _next;	\
	} while (0)

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
			 volatile ap_uint<1> *RDWRB_to_icap)
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

	static enum icap_controller_hls_state state;

	ap_uint<ICAP_DATA_WIDTH> in;
	static int command_cnt = 0;
	ap_uint<1> prdone, prerror;

	switch (state) {
	case IDLE_ICAP_INACTIVE: {
		ap_uint<1> avail;

		avail = *AVAIL_from_icap;
		if (avail.to_int() == 0)
			NEXT(state, IDLE_ICAP_INACTIVE);
		else if (avail.to_uint() == 1)
			NEXT(state, IDLE_ICAP_ACTIVE);

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
			NEXT(state, IDLE_ICAP_INACTIVE);
			break;
		}
		NEXT(state, STATE_OP_START);
		break;
	}

	case STATE_OP_START: {
		*CSIB_to_icap = ICAP_CSIB_ENABLE;

		/*
		 * XXX
		 * If we want to write some commands/bitstream into ICAP, we should use write?
		 * If we want to first write some commands then readback some status/bitstream,
		 * what shall we do? Write first then read? Or just Write?
		 */
		*RDWRB_to_icap = ICAP_RDWRB_READ;

		NEXT(state, STATE_OP_STREAM);
		command_cnt = 0;
		break;
	}

	case STATE_OP_STREAM: {
#if 0
		prdone = *PRDONE_from_icap;
		prerror = *PRERROR_from_icap;

		/* Check if the ICAP has reported error */
		if (prdone.to_int() == 0 || prerror.to_int() == 1) {
			NEXT(state, IDLE_ICAP_INACTIVE);
			break;
		}
#endif

		/* Enable Write mode */
		*CSIB_to_icap = ICAP_CSIB_ENABLE;
		*RDWRB_to_icap = ICAP_RDWRB_WRITE;

		/* Send command cycle by cycle */
		if (command_cnt < ARRAY_SIZE(COMMAND_stat)) {
			ap_uint<ICAP_DATA_WIDTH> data;

			data = COMMAND_stat[command_cnt];
			to_icap->write(data);
			command_cnt++;
		} else {
			NEXT(state, STATE_DONE);
		}
		break;
	}

	case STATE_DONE: {
		/* Enable Read mode */
		*CSIB_to_icap = ICAP_CSIB_ENABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;

		if (!from_icap->empty()) {
			in = from_icap->read();
		}

		NEXT(state, STATE_DONE);
		break;
	}

	default:
		/* Should never reach here */
		HLS_BUG();
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		state = IDLE_ICAP_INACTIVE;
		break;
	}
}
