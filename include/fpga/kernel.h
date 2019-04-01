/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _LEGO_FPGA_KERNEL_H_
#define _LEGO_FPGA_KERNEL_H_

#ifdef __SYNTHESIS__
# define PR(fmt, ...)	do { } while (0)
#else
# define PR(fmt, ...)	printf(fmt, ##__VA_ARGS__)
#endif

#endif /* _LEGO_FPGA_KERNEL_H_ */
