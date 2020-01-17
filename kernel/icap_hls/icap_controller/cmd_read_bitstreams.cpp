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

#define NR_WORDS_PER_FRAME_7SERIES			(101)
#define NR_WORDS_PER_FRAME_ULTRASCALE			(123)
#define NR_WORDS_PER_FRAME_ULTRASCALE_PLUS		(93)

#define NR_OVERHEAD_WORDS_PER_READ_7SERIES		(0)
#define NR_OVERHEAD_WORDS_PER_READ_ULTRASCALE		(10)
#define NR_OVERHEAD_WORDS_PER_READ_ULTRASCALE_PLUS	(25)

#define NR_WORDS_READ_ONE_FRAME_ULTRASCLAE_PLUS		\
	(NR_WORDS_PER_FRAME_ULTRASCALE_PLUS * 2 +	\
	 NR_OVERHEAD_WORDS_PER_READ_ULTRASCALE_PLUS )

using namespace hls;

static unsigned int COMMAND_readback_1[] = {
/* Step 1 */
	0xFFFFFFFF,	/* Ignored dummy word */
	0x000000BB,	/* Bus width sync word */
	0x11220044,	/* Bus width detect */
	0xFFFFFFFF,	/* Ignored dummy word */
	0xAA995566,	/* Sync Word */

/* Step 2 */
	0x20000000,	/* NOOP */

/* Step 3 */
#if  1
	0x3000C001,	/* Write to MASK */
	0x00800000,	/*   CAPTURE bit[23] */
	0x30030001,	/* Write to CTL1 */
	0x00800000,	/*   CAPTURE bit[23] */
#endif

/* Step 4 */
	0x30008001,	/* Write to CMD register */
	0x00000007,	/*	RCRC command */
	0x20000000,	/* NOOP */

/* Step 5 */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */

/* Step 6 */
	0x30008001,	/* Write to CMD register */
	0x00000004,	/*	RCFG command */
	0x20000000,	/* NOOP */

/*
 * Step 7
 */
	0x30002001,	/* Write to FAR */
	//0x00002000,	/* FAR Address */
	//0x00051e0c,
	[22] = 0x0004f70c,

/*
 * Step 8
 * Header type: 010
 * Opcode: 01
 * -> 0x48000000 | nr_words
 */
	0x28006000,	/* Type I Read words from FDRO */
	//0x48000100,	/* Type II Read XXXX words from FDRO */
	0x48000000 | NR_WORDS_READ_ONE_FRAME_ULTRASCLAE_PLUS,

/* Step 9 */
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,
	0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000, 0x20000000,

/*
 * Step 10: Read data from FDRO register
 * The number of data packets is specified at Step 8
 */
};

static unsigned int COMMAND_readback_2[] = {
#if  1
	0x3000C001,	/* Write to MASK */
	0x00800000,	/*   CAPTURE bit[23] */
	0x30030001,	/* Write to CTL1 */
	0x00000000,	/*   CAPTURE bit[23] */
#endif

/* Step 11 */
	0x20000000,

/* Step 12 */
	0x30008001,	/* Write to CMD register */
	0x00000005,	/*	START command */
	0x20000000,	/* NOOP */

/* Step 13 */
	0x30008001,	/* Write to CMD register */
	0x00000007,	/*	RCRC command */
	0x20000000,	/* NOOP */

/* Step 14 */
	0x30008001,	/* Write to CMD register */
	0x0000000D,	/*	DESYNC command */

/* Step 15 */
	0x20000000,
	0x20000000,
};

int cmd_read_bitstreams(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
			stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
			volatile ap_uint<1> *CSIB_to_icap,
			volatile ap_uint<1> *RDWRB_to_icap,
			volatile int *O_nr_bytes,
			volatile int *frame_addr)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	enum CMD_READBACK_STATE {
		READBACK_IDLE,
		READBACK_WRITE_1,
		READBACK_WRITE_1_TRANSITION,
		READBACK_READ,
		READBACK_WRITE_2,
	};

	static enum CMD_READBACK_STATE state = READBACK_IDLE;
	static int nr_1 = 0, nr_2 = 0;
	ap_uint<ICAP_DATA_WIDTH> data;

	static int nr_to_read = NR_WORDS_READ_ONE_FRAME_ULTRASCLAE_PLUS;

	switch (state) {
	case READBACK_IDLE:
		nr_1 = 0;
		nr_2 = 0;

		COMMAND_readback_1[22] = *frame_addr;

		/* Assert Write prior enableing CSIB */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_WRITE;
		FSM_NEXT(state, READBACK_WRITE_1);
		break;
	case READBACK_WRITE_1: {
		if (nr_1 < ARRAY_SIZE(COMMAND_readback_1)) {
		/* Enable CSIB AND enable Write. */
			*CSIB_to_icap = ICAP_CSIB_ENABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;

			data = COMMAND_readback_1[nr_1];
			to_icap->write(data);
			nr_1++;
		} else {
			/* Last cycle. Disable CSIB first */
			*CSIB_to_icap = ICAP_CSIB_DISABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;
			FSM_NEXT(state, READBACK_WRITE_1_TRANSITION);
		}
		break;
	}
	case READBACK_WRITE_1_TRANSITION:
		/*
		 * Enable Read model with CSIB disabled.
		 * Basically back the DISABLE mode.
		 */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		FSM_NEXT(state, READBACK_READ);
		break;	
	case READBACK_READ: {
		int reg_data, ret;

		/* We need to read via the FDRO register */
		ret = cmd_read_regs(from_icap, to_icap, CSIB_to_icap, RDWRB_to_icap,
				    ICAP_REG_FDRO, &reg_data);
		if (ret == CMD_DONE) {
			if (nr_to_read == 0) {
				FSM_NEXT(state, READBACK_WRITE_2);
				break;
			}
			nr_to_read--;
			*O_nr_bytes = (NR_WORDS_READ_ONE_FRAME_ULTRASCLAE_PLUS - nr_to_read);
		}
		break;
	}
	case READBACK_WRITE_2: {
		if (nr_2 < ARRAY_SIZE(COMMAND_readback_2)) {
			*CSIB_to_icap = ICAP_CSIB_ENABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;

			data = COMMAND_readback_2[nr_2];
			to_icap->write(data);
			nr_2++;
		} else {
			/* We are done. Disable ICAP. */
			*CSIB_to_icap = ICAP_CSIB_DISABLE;
			*RDWRB_to_icap = ICAP_RDWRB_READ;

			FSM_NEXT(state, READBACK_IDLE);
			return CMD_DONE;
		}
		break;
	}
	default:
		HLS_BUG();
		break;
	};

	/*
	 * This HLS is not software programming.
	 * Here, CMD_WIP is returned every cycle except the cycle
	 * when we reach READ_REGS_WRITE_2. It's weird. I know.
	 * But think it in a hardware way, this is physical logic.
	 */
	return CMD_WIP;
}
