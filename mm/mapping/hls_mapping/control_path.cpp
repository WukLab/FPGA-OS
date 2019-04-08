/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>
#include "top.hpp"
#include "dm.hpp"

/*
 * I @s_req: control requests
 * O @out_ctl: reply results
 * O @read_cmd: commands to do memory read
 * I @read_data: data of memory read.
 * O @write_cmd: commands for memory write
 * O @write_data: data to write
 */
void control_path(stream<struct paging_request_ctl> *s_req,
		  stream<struct paging_reply> *out_ctl,
		  stream<struct mem_cmd> *read_cmd,
		  stream<ap_uint<512> > *read_data,
		  stream<struct mem_cmd> *write_cmd,
		  stream<ap_uint<512> > *write_data)
{
#pragma HLS PIPELINE
	struct paging_request_ctl ctl;
	struct paging_reply reply;
	struct mem_cmd _read_cmd, _write_cmd;

	if (s_req->empty())
		return;

	ctl = s_req->read();
	out_ctl->write(reply);

	_read_cmd.address = 0x55;
	_read_cmd.length = 0x100;
	read_cmd->write(_read_cmd);

	_write_cmd.address = 0x66;
	_write_cmd.length = 0x100;
	write_cmd->write(_write_cmd);
	ap_uint<512> data;
	write_data->write(data);
}
