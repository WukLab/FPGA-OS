/*
 * Copyright (c) 2019，Wuklab, UCSD.
 */
#ifndef _KERNEL_SCHED_ICAP_HLS_H_
#define _KERNEL_SCHED_ICAP_HLS_H_

/*
 * This is for Ultrascale+ family.
 * Other series might be different.
 */
#define ICAP_DATA_WIDTH	(32)

/* Active-Low ICAP input Enable */
#define ICAP_CSIB_ENABLE	(0)
#define ICAP_CSIB_DISABLE	(1)

/* Read active high, Write active low */
#define ICAP_RDWRB_READ		(1)
#define ICAP_RDWRB_WRITE	(0)

#endif /* _KERNEL_SCHED_ICAP_HLS_H_ */
