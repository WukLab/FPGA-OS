/*
 * Copyright (c) 2019, WukLab, Purdue University.
 */

#ifndef _SYSMMU_H_
#define _SYSMMU_H_

#include <fpga/axis_sysmmu.h>

struct sysmmu_indata {
	/*
	 * physical memory datapath input interface, only for permission check
	 *
	 * pid: 	application id
	 * in_addr:	address in
	 * in_len:	axi transfer burst length
	 * in_size:	axi transfer burst size
	 */
	ap_uint<PID_WIDTH>	pid;
	ap_uint<PA_WIDTH>	in_addr;
	ap_uint<8>		in_len;
	ap_uint<3>		in_size;
};

struct sysmmu_outdata {
	/*
	 * physical memory datapath output interface, only for permission check
	 *
	 * out_addr: physical address out
	 * drop: 1 if error occurs, 0 if success
	 */
	ap_uint<PA_WIDTH>	out_addr;
	ap_uint<1>		drop;
};

struct sysmmu_entry{
	ap_uint<1>		valid;
	ap_uint<1>		rw;
	ap_uint<PID_WIDTH>	pid;
};

void sysmmu_data_hanlder(struct sysmmu_indata& rd_in, struct sysmmu_outdata* rd_out,
			 struct sysmmu_indata& wr_in, struct sysmmu_outdata* wr_out);
void sysmmu_ctrl_hanlder(hls::stream<struct sysmmu_ctrl_if>& ctrlpath, ap_uint<1>* stat);

void sysmmu_data_read(struct sysmmu_indata& rd_in, struct sysmmu_outdata* rd_out);
void sysmmu_data_write(struct sysmmu_indata& wr_in, struct sysmmu_outdata* wr_out);

ap_uint<1> insert(struct sysmmu_ctrl_if& ctrl);
ap_uint<1> del(struct sysmmu_ctrl_if& ctrl);
ap_uint<1> check_read(struct sysmmu_indata& rd_in);
ap_uint<1> check_write(struct sysmmu_indata& wr_in);



#endif /* _SYSMMU_H_ */
