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
#include <linux/ctype.h>
#include <linux/string.h>
#include <linux/module.h>
#include <linux/parser.h>
#include <linux/kernel.h>
#include <linux/seq_file.h>

/*
 * We are directly using physical memory reserved
 * via kernel command line `memmap`.
 * Make sure the region we use falls into that.
 */
unsigned long phys_base = 0x100000000;
unsigned long phys_size = 0x10000000;
unsigned long virt_base = 0;

static int remap_init(void)
{
	virt_base = (unsigned long)ioremap_cache(phys_base, phys_size);
	if (!virt_base) {
		pr_err("error: fail to ioremap range [%#lx - %#lx]\n",
			phys_base, phys_base + phys_size);
		return -ENOMEM;
	}

	pr_info("PA range: [%#18lx - %#18lx]\n",
		phys_base, phys_base + phys_size);
	pr_info("VA range: [%#18lx - %#18lx]\n",
		virt_base, virt_base + phys_size);

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
