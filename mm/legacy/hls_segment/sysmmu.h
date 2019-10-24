/*
 * Copyright (c) 2019, WukLab, UCSD.
 */

#ifndef _SYSMMU_H_
#define _SYSMMU_H_

#include <fpga/axis_sysmmu.h>

void
sysmmu_data_hanlder(hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out,
		    hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out);
void
sysmmu_ctrl_hanlder(hls::stream<sysmmu_ctrl_if>& ctrlpath, hls::stream<ap_uint<1> >& ctrl_stat);

void sysmmu_data_read(hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out);
void sysmmu_data_write(hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out);

ap_uint<1> insert(sysmmu_ctrl_if& ctrl);
ap_uint<1> del(sysmmu_ctrl_if& ctrl);
void check_read(hls::stream<sysmmu_indata>& rd_in, hls::stream<sysmmu_outdata>& rd_out);
void check_write(hls::stream<sysmmu_indata>& wr_in, hls::stream<sysmmu_outdata>& wr_out);

#endif /* _SYSMMU_H_ */
