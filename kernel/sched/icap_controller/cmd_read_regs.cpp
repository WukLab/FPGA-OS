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

/*
 * The following command sequence is described by
 * UG570 Chapter 10 on Readback Verification and CRC.
 *
 * The UG570 says we need to first write the first set of commands,
 * then read one word from the Register. At last, write the second
 * set of commands, which is the DESYNC.
 */

static unsigned int COMMAND_regs_1[] = {
	[0]	=	0xFFFFFFFF,	/* Ignored dummy word */
	[1]	=	0x000000BB,	/* Bus width sync word */
	[2]	=	0x11220044,	/* Bus width detect */
	[3]	=	0xFFFFFFFF,	/* Ignored dummy word */
	[4]	=	0xAA995566,	/* Sync Word */
	[5]	=	0x20000000,	/* NOOP */
	/*
	 * This can be changed to different registers
	 * 0x2800E001	STAT register 00111 -> 0000/1110
	 * 0x28018001	IDCODE register 01/100 -> 0001/1000
	 */
	[6]	=	0x28018001,	/* Type 1 READ words from ICAP */

	[7]	=	0x20000000,	/* NOOP */
	[8]	=	0x20000000,	/* NOOP */
	/*
	 * This step should be ICAP Read.
	 * The ICAP device will write one word from the STAT register
	 * to the configruation interface.
	 */
};

static unsigned int COMMAND_regs_desync[] = {
	0x30008001,	/* Type 1 Write 1 word to CMD */
	0x0000000D,	/* DESYNC command */
	0x20000000,	/* NOOP */
	0x20000000,	/* NOOP */
};

/*
 * VCU118 IDCODE: 14b31093
 */
struct icap_register_entry icap_register_table[] = {
	[ICAP_REG_CRC]		= { .addr = 0b00000,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_FAR]		= { .addr = 0b00001,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_FDRI]		= { .addr = 0b00010,	.rw = ICAP_REG_PERMISSION_W,  },
	[ICAP_REG_FDRO]		= { .addr = 0b00011,	.rw = ICAP_REG_PERMISSION_R,  },
	[ICAP_REG_CMD]		= { .addr = 0b00100,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_CTL0]		= { .addr = 0b00101,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_MASK]		= { .addr = 0b00110,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_STAT]		= { .addr = 0b00111,	.rw = ICAP_REG_PERMISSION_R,  },
	[ICAP_REG_LOUT]		= { .addr = 0b01000,	.rw = ICAP_REG_PERMISSION_W,  },
	[ICAP_REG_COR0]		= { .addr = 0b01001,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_MFWR]		= { .addr = 0b01010,	.rw = ICAP_REG_PERMISSION_W,  },
	[ICAP_REG_CBC]		= { .addr = 0b01011,	.rw = ICAP_REG_PERMISSION_W,  },
	[ICAP_REG_IDCODE]	= { .addr = 0b01100,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_AXSS]		= { .addr = 0b01101,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_COR1]		= { .addr = 0b01110,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_WBSTAR]	= { .addr = 0b10000,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_TIMER]	= { .addr = 0b10001,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_BOOTSTS]	= { .addr = 0b10110,	.rw = ICAP_REG_PERMISSION_R,  },
	[ICAP_REG_CTL1]		= { .addr = 0b11000,	.rw = ICAP_REG_PERMISSION_RW, },
	[ICAP_REG_BSP1]		= { .addr = 0b11111,	.rw = ICAP_REG_PERMISSION_RW, },
};

#define default_cmd_header	(0x28000001)
#define CMD_HEADER_INDEX	(6)

unsigned int cook_cmd(int reg_nr)
{
#pragma HLS INLINE
	struct icap_register_entry reg_entry;
	unsigned int new_cmd;

	reg_entry = icap_register_table[reg_nr];
	new_cmd = reg_entry.addr.to_uint() << ICAP_T1_REGADDR_SHIFT;
	new_cmd = default_cmd_header | new_cmd;

	return new_cmd;
}

void update_COMMAND_regs_1(unsigned int cmd)
{
#pragma HLS INLINE
	COMMAND_regs_1[CMD_HEADER_INDEX] = cmd;
}

/*
 * Reference: UG570 chapter 10.
 * - We must change from Write to Read after writing the first set of commands.
 * - To read other registers, we could change the address of the first Type I.
 * - This can NOT be used to read the configuration memory.
 */
int cmd_read_regs(stream<ap_uint<ICAP_DATA_WIDTH> > *from_icap,
		  stream<ap_uint<ICAP_DATA_WIDTH> > *to_icap,
		  volatile ap_uint<1> *CSIB_to_icap,
		  volatile ap_uint<1> *RDWRB_to_icap,
		  int reg_nr, int *reg_data)
{
#pragma HLS INLINE
#pragma HLS PIPELINE
	enum CMD_READ_REGS_STATE {
		READ_REGS_IDLE,
		READ_REGS_WRITE_1,
		READ_REGS_WRITE_1_TRANSITION,
		READ_REGS_READ,
		READ_REGS_READ_TRANSITION,
		READ_REGS_WRITE_DESYNC,
	};
	static enum CMD_READ_REGS_STATE state = READ_REGS_IDLE;
	static int nr_1 = 0, nr_2 = 0;
	ap_uint<ICAP_DATA_WIDTH> data;
	struct icap_register_entry reg_entry = { 0 };
	static int nr_bytes_read = 0;

	if (unlikely(reg_nr >= NR_ICAP_REG)) {
		HLS_BUG();
		return CMD_DONE;
	}

	reg_entry = icap_register_table[reg_nr];
	if (unlikely(reg_entry.rw == ICAP_REG_PERMISSION_W))
		return CMD_DONE;

	switch (state) {
	case READ_REGS_IDLE: {
		unsigned int cmd;
		nr_1 = 0;
		nr_2 = 0;
		nr_bytes_read = 0;

		cmd = cook_cmd(reg_nr);
		update_COMMAND_regs_1(cmd);

		/* Assert Write prior enableing CSIB */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_WRITE;
		FSM_NEXT(state, READ_REGS_WRITE_1);
		break;
	}
	case READ_REGS_WRITE_1:
		if (nr_1 < ARRAY_SIZE(COMMAND_regs_1)) {
			/* Enable CSIB AND enable Write. */
			*CSIB_to_icap = ICAP_CSIB_ENABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;

			data = COMMAND_regs_1[nr_1];
			to_icap->write(data);
			nr_1++;
		} else {
			/* Last cycle. Disable CSIB first */
			*CSIB_to_icap = ICAP_CSIB_DISABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;
			FSM_NEXT(state, READ_REGS_WRITE_1_TRANSITION);
		}
		break;
	case READ_REGS_WRITE_1_TRANSITION:
		/* Enable Read model with CSIB disabled. */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		FSM_NEXT(state, READ_REGS_READ);
		break;
	case READ_REGS_READ: {
		*CSIB_to_icap = ICAP_CSIB_ENABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;

		if (from_icap->read_nb(data)) {
			/*
			 * XXX
			 * - Assume 0 is a valid output value.
			 *   It seems for most register reads, this is true.
			 * - However, during on-chip testing, I found the O from
			 *   ICAP is ffffffd9, sometimes ffffffdb... and this is
			 *   in the middle of this. Better to be able know this.
			 * This is true for VCU118 at least.
			 */
			nr_bytes_read++;
			if (data.to_int() == 0 ||
			    data.to_int() == 0xFFFFFFD9 ||
			    data.to_int() == 0xFFFFFFDB) {
				if (nr_bytes_read <= 5)
					break;
			}

			*reg_data = data.to_int();
			FSM_NEXT(state, READ_REGS_READ_TRANSITION);
		} else {
			/* Nothing was read */
			break;
		}
		break;
	}
	case READ_REGS_READ_TRANSITION:
		/*
		 * It seems something will happen if we change from READ to WRITE
		 * while CSIB is enabled. Thus we have this stage to first
		 * disable CSIB. Next cycle we toggle both.
		 */
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		FSM_NEXT(state, READ_REGS_WRITE_DESYNC);
		break;
	case READ_REGS_WRITE_DESYNC:
#if 1
		if (nr_2 < ARRAY_SIZE(COMMAND_regs_desync)) {
			*CSIB_to_icap = ICAP_CSIB_ENABLE;
			*RDWRB_to_icap = ICAP_RDWRB_WRITE;

			data = COMMAND_regs_desync[nr_2];
			to_icap->write(data);
			nr_2++;
		} else {
			/* We are done. Disable ICAP. */
			*CSIB_to_icap = ICAP_CSIB_DISABLE;
			*RDWRB_to_icap = ICAP_RDWRB_READ;
			FSM_NEXT(state, READ_REGS_IDLE);
			return CMD_DONE;
		}
		break;
#else
		*CSIB_to_icap = ICAP_CSIB_DISABLE;
		*RDWRB_to_icap = ICAP_RDWRB_READ;
		FSM_NEXT(state, READ_REGS_IDLE);
		return CMD_DONE;
#endif
	default:
		HLS_BUG();
		break;
	};

	/*
	 * This HLS is not software programming.
	 * Here, CMD_WIP is returned every cycle except the cycle
	 * when we reach READ_REGS_WRITE_DESYNC. It's weird. I know.
	 * But think it in a hardware way, this is physical logic.
	 */
	return CMD_WIP;
}
