/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

#ifndef _LEGO_FPGA_KERNEL_H_
#define _LEGO_FPGA_KERNEL_H_

#ifdef __SYNTHESIS__
# define PR(fmt, ...)	do { } while (0)
#else
# ifdef ENABLE_PR
#  define PR(fmt, ...)	printf("[%s:%d] " fmt, __func__, __LINE__, ##__VA_ARGS__)
# else
#  define PR(fmt, ...)	do { } while (0)
# endif
#endif

#endif /* _LEGO_FPGA_KERNEL_H_ */
