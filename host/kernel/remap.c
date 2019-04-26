/*
 * Copyright (c) 2019 Wuklab, Purdue University. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#include <linux/mm.h>
#include <linux/time.h>
#include <linux/slab.h>
#include <linux/sched/signal.h>
#include <linux/ctype.h>
#include <linux/string.h>
#include <linux/module.h>
#include <linux/parser.h>
#include <linux/kernel.h>
#include <linux/signal.h>
#include <linux/seq_file.h>

/*
 * We are directly using physical memory reserved
 * via kernel command line `memmap`.
 * Make sure the region we use falls into that.
 */
unsigned long phys_base = 0x100000000;
unsigned long phys_size = 0x10000000;
unsigned long virt_base = 0;

//unsigned long nr_requests = 1000000;
unsigned long nr_requests = 300;

#define RDM_COUNTER_OFFSET	16
#define OPCODE_OFFSET		1
#define ERROR_CODE_OFFSET	24

static int remap_init(void)
{
	unsigned long *counter;
	unsigned long *retcode;
	char *opcode;
	unsigned long wr_err_counter = 0, rd_err_counter = 0;
	unsigned long saved, expected, last_count;
	struct timespec ts, ts_f;
	//char *p1, p2;

	virt_base = (unsigned long)ioremap_nocache(phys_base, phys_size);
	if (!virt_base) {
		pr_err("error: fail to ioremap range [%#lx - %#lx]\n",
			phys_base, phys_base + phys_size);
		return -ENOMEM;
	}

	pr_info("PA range: [%#18lx - %#18lx]\n",
		phys_base, phys_base + phys_size);
	pr_info("VA range: [%#18lx - %#18lx]\n",
		virt_base, virt_base + phys_size);

#define NR_BYTES_TO_DUMP	(128)
	//memset((void *)virt_base, 0, 1024*1024*16+128);
	print_hex_dump(KERN_INFO, "RDM: ", DUMP_PREFIX_OFFSET,
		       32, 1, (const void *)virt_base, NR_BYTES_TO_DUMP, false);

	counter = (unsigned long *)(virt_base + RDM_COUNTER_OFFSET);

#if 1
	retcode = (unsigned long *)(virt_base + ERROR_CODE_OFFSET);
	opcode = (char *)(virt_base + OPCODE_OFFSET);
#endif

	saved = *counter;
	last_count = *counter;
	expected = saved + nr_requests;

	getnstimeofday(&ts);
	printk("counter: %lu expected: %lu ts: %ld %ld\n",
		saved, expected, ts.tv_sec, ts.tv_nsec);

#if 1
	while (1) {
		if (*counter <= (saved+2))
			getnstimeofday(&ts_f);

		if (*counter == expected) {
			getnstimeofday(&ts);
			break;
		}

#if 1
		if (*retcode == 0x313020524F525245) {
			if (last_count != *counter) {
				if (*opcode == 0)
					rd_err_counter++;
				if (*opcode == 1)
					wr_err_counter++;
				last_count = *counter;
			}
		}
#endif
		if (signal_pending(current)) {
			pr_info("signal pending. Killed.");
			break;
		}
		cpu_relax();
	}
#endif

	printk("expected: %lu actual: %lu\n", expected, *counter);
	printk("First packet time: %ld.%ld\n", ts_f.tv_sec, ts_f.tv_nsec);
	printk("End time:          %ld.%ld\n", ts.tv_sec, ts.tv_nsec);
	printk("Read Error:           %lu\n", rd_err_counter);
	printk("Write Error:          %lu\n", wr_err_counter);

	return 0;
}

static void remap_exit(void)
{
	if (virt_base)
		iounmap((void __iomem *)virt_base);
	pr_info("Removed remap module.\n");
}

module_init(remap_init);
module_exit(remap_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Wuklab@Purdue");
