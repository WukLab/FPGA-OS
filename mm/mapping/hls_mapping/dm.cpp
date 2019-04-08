/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include <fpga/kernel.h>
#include "top.hpp"
#include "dm.hpp"


#define MAPPING_TABLE_ADDRESS_BASE	(0x1000)

/*
 * I @mem_read_cmd: memory read commands from this IP
 * O @mem_read_data: internal read data buffer
 * O @dm_read_cmd: cooked requests sent to datamover
 * I @dm_read_data: data from datamover
 * I @dm_read_status: status from datamover
 */
void DRAM_rd_pipe(stream<struct mem_cmd> *mem_read_cmd,
		  stream<ap_uint<MEM_BUS_WIDTH> > *mem_read_data,
		  stream<struct dm_cmd> *dm_read_cmd,
		  stream<struct axis_mem> *dm_read_data,
		  stream<ap_uint<8> > *dm_read_status)
{
#pragma HLS pipeline II=1 enable_flush

	/*
	 * Read commands from internal FIFO,
	 * cook it and send over to datamover.
	 */
	if (!mem_read_cmd->empty() && !dm_read_cmd->full()) {
		struct mem_cmd in_cmd;
		struct dm_cmd out_cmd;

		in_cmd = mem_read_cmd->read();

		out_cmd.btt = in_cmd.length;
		out_cmd.type = DM_CMD_TYPE_INCR;
		out_cmd.dsa = 0;
		out_cmd.eof = 1;
		out_cmd.drr = 0;
		out_cmd.start_address = in_cmd.address + MAPPING_TABLE_ADDRESS_BASE;
		out_cmd.rsvd = 0;
		dm_read_cmd->write(out_cmd);
	}

	if (!dm_read_data->empty() && !mem_read_data->full()) {
		struct axis_mem in;

		in = dm_read_data->read();
		mem_read_data->write(in.data);
	}

	if (!dm_read_status->empty()) {
		ap_uint<8> status;
		status = dm_read_status->read();
	}
}

/*
 * I @mem_write_cmd: memory write commands from this IP
 * I @mem_write_data: internal write data buffer
 * O @dm_write_cmd: cooked requests sent to datamover
 * O @dm_write_data: data to datamover
 * I @dm_write_status: status from datamover
 */
void DRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		   stream<ap_uint<MEM_BUS_WIDTH> > *mem_write_data,
		   stream<struct dm_cmd> *dm_write_cmd,
		   stream<struct axis_mem> *dm_write_data,
		   stream<ap_uint<8> > *dm_write_status)
{
#pragma HLS PIPELINE II=1 enable_flush

	if (!mem_write_cmd->empty() && !dm_write_cmd->full()) {
		struct mem_cmd in_cmd;
		struct dm_cmd out_cmd;

		in_cmd = mem_write_cmd->read();

		out_cmd.btt = in_cmd.length;
		out_cmd.type = DM_CMD_TYPE_INCR;
		out_cmd.dsa = 0;
		out_cmd.eof = 1;
		out_cmd.drr = 0;
		out_cmd.start_address = in_cmd.address + MAPPING_TABLE_ADDRESS_BASE;
		out_cmd.rsvd = 0;
		dm_write_cmd->write(out_cmd);
	}

	if (!mem_write_data->empty() && !dm_write_data->full()) {
		struct axis_mem out = {
			.data = 0,
			.keep = 0xFFFFFFFFFFFFFFFF,
			.last = 1
		};
		mem_write_data->read(out.data);
		dm_write_data->write(out);
	}

	if (!dm_write_status->empty()) {
		ap_uint<8> status;
		status = dm_write_status->read();
	}
}
/*
 * I @mem_read_cmd: memory read commands from this IP
 * O @mem_read_data: internal read data buffer
 * O @dm_read_cmd: cooked requests sent to datamover
 * I @dm_read_data: data from datamover
 * I @dm_read_status: status from datamover
 */
void BRAM_rd_pipe(stream<struct mem_cmd> *mem_read_cmd,
		  stream<ap_uint<MEM_BUS_WIDTH> > *mem_read_data,
		  stream<struct dm_cmd> *dm_read_cmd,
		  stream<struct axis_mem> *dm_read_data,
		  stream<ap_uint<8> > *dm_read_status)
{
#pragma HLS pipeline II=1 enable_flush

	/*
	 * Read commands from internal FIFO,
	 * cook it and send over to datamover.
	 */
	if (!mem_read_cmd->empty() && !dm_read_cmd->full()) {
		struct mem_cmd in_cmd;
		struct dm_cmd out_cmd;

		in_cmd = mem_read_cmd->read();

		out_cmd.btt = 64;
		out_cmd.type = DM_CMD_TYPE_INCR;
		out_cmd.dsa = 0;
		out_cmd.eof = 1;
		out_cmd.drr = 0;
		out_cmd.start_address = in_cmd.address;
		out_cmd.rsvd = 0;
		dm_read_cmd->write(out_cmd);
	}

	if (!dm_read_data->empty() && !mem_read_data->full()) {
		struct axis_mem in;

		in = dm_read_data->read();
		mem_read_data->write(in.data);
	}

	if (!dm_read_status->empty()) {
		ap_uint<8> status;
		status = dm_read_status->read();
	}
}

/*
 * I @mem_write_cmd: memory write commands from this IP
 * I @mem_write_data: internal write data buffer
 * O @dm_write_cmd: cooked requests sent to datamover
 * O @dm_write_data: data to datamover
 * I @dm_write_status: status from datamover
 */
void BRAM_wr_pipe(stream<struct mem_cmd> *mem_write_cmd,
		   stream<ap_uint<MEM_BUS_WIDTH> > *mem_write_data,
		   stream<struct dm_cmd> *dm_write_cmd,
		   stream<struct axis_mem> *dm_write_data,
		   stream<ap_uint<8> > *dm_write_status)
{
#pragma HLS PIPELINE II=1 enable_flush

	if (!mem_write_cmd->empty() && !dm_write_cmd->full()) {
		struct mem_cmd in_cmd;
		struct dm_cmd out_cmd;

		in_cmd = mem_write_cmd->read();

		out_cmd.btt = 64;
		out_cmd.type = DM_CMD_TYPE_INCR;
		out_cmd.dsa = 0;
		out_cmd.eof = 1;
		out_cmd.drr = 0;
		out_cmd.start_address = in_cmd.address;
		out_cmd.rsvd = 0;
		dm_write_cmd->write(out_cmd);
	}

	if (!mem_write_data->empty() && !dm_write_data->full()) {
		struct axis_mem out = {
			.data = 0,
			.keep = 0xFFFFFFFFFFFFFFFF,
			.last = 1
		};
		mem_write_data->read(out.data);
		dm_write_data->write(out);
	}

	if (!dm_write_status->empty()) {
		ap_uint<8> status;
		status = dm_write_status->read();
	}
}
