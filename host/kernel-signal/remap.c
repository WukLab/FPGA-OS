/*
 * Copyright (c) 2019 Wuklab, UCSD. All rights reserved.
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

#include <net/sock.h>
#include <linux/netlink.h>
#include <linux/skbuff.h>
#define NETLINK_USER 31

/*
 * We are directly using physical memory reserved
 * via kernel command line `memmap`.
 * Make sure the region we use falls into that.
 */
unsigned long phys_base = 0x100000000;
unsigned long phys_size = 0x10000000;
unsigned long virt_base = 0;

#define RDM_COUNTER_OFFSET 81

/* please disable this line when you want to run real test with FPGA */
#define TEST_FUNCTION

struct sock *nl_sk = NULL;

void timespec_diff(struct timespec *start, struct timespec *stop,
                   struct timespec *result) {
    if ((stop->tv_nsec - start->tv_nsec) < 0) {
        result->tv_sec = stop->tv_sec - start->tv_sec - 1;
        result->tv_nsec = stop->tv_nsec - start->tv_nsec + 1000000000;
    } else {
        result->tv_sec = stop->tv_sec - start->tv_sec;
        result->tv_nsec = stop->tv_nsec - start->tv_nsec;
    }

    return;
}

static struct timespec *remap_get_ns(int nr_requests);
static struct timespec *remap_get_ns(int nr_requests) {
    unsigned long *counter;
    unsigned long saved, expected;
    struct timespec ts, ts_f;
    // char *p1, p2;
    struct timespec *ret = kmalloc(sizeof(struct timespec), GFP_KERNEL);

    #ifdef TEST_FUNCTION
    /* if you want to test functionality, enable this part, it would bypass your function*/
    struct timespec *test = kmalloc(sizeof(struct timespec), GFP_KERNEL);
    test->tv_sec = nr_requests * 100;
    test->tv_nsec = nr_requests;
    return test;
    #endif
    

    virt_base = (unsigned long)ioremap_cache(phys_base, phys_size);
    if (!virt_base) {
        pr_err("error: fail to ioremap range [%#lx - %#lx]\n", phys_base,
               phys_base + phys_size);
        // return -ENOMEM;
        return NULL;
    }

    pr_info("PA range: [%#18lx - %#18lx]\n", phys_base, phys_base + phys_size);
    pr_info("VA range: [%#18lx - %#18lx]\n", virt_base, virt_base + phys_size);

#define NR_BYTES_TO_DUMP (256)
    // memset((void *)virt_base, 0, 1024*1024*16+128);
    print_hex_dump(KERN_INFO, "RDM: ", DUMP_PREFIX_OFFSET, 32, 2,
                   (const void *)virt_base, NR_BYTES_TO_DUMP, false);

    counter = (unsigned long *)(virt_base + RDM_COUNTER_OFFSET);
    saved = *counter;
    expected = saved + nr_requests;

    getnstimeofday(&ts);
    printk("current: %lu expected: %lu ts: %ld %ld\n", saved, expected,
           ts.tv_sec, ts.tv_nsec);

#if 1
    while (1) {
        if (*counter <= (saved + 2)) getnstimeofday(&ts_f);

        if (*counter == expected) {
            getnstimeofday(&ts);
            break;
        }
        if (signal_pending(current)) {
            pr_info("signal pending. Killed.");
            break;
        }
        cpu_relax();
    }
#endif

    /*printk("expected: %lu actual: %lu\n", expected, *counter);
    printk("First packet time: %ld.%ld\n", ts_f.tv_sec, ts_f.tv_nsec);
    printk("End time:          %ld.%ld\n", ts.tv_sec, ts.tv_nsec);*/
    timespec_diff(&ts_f, &ts, ret);

    return ret;
}
static void remap_recv_msg(struct sk_buff *skb) {

    struct nlmsghdr *nlh;
    int pid;
    struct sk_buff *skb_out;
    int msg_size;
    int *nr_requests_ptr;
    int res;
    struct timespec *ret_ptr;
    
    #ifdef TEST_FUNCTION
    printk(KERN_INFO "Entering: %s\n", __FUNCTION__);
    #endif

    nlh = (struct nlmsghdr *)skb->data;
    // printk(KERN_INFO "Netlink received msg payload:%s\n", (char
    // *)nlmsg_data(nlh));
    nr_requests_ptr = (int *)nlmsg_data(nlh);

    #ifdef TEST_FUNCTION
    printk(KERN_INFO "Netlink received msg payload:%d\n", *nr_requests_ptr);
    #endif

    pid = nlh->nlmsg_pid; /*pid of sending process */

    ret_ptr = remap_get_ns(*nr_requests_ptr);
    //printk(KERN_INFO "%lld %lld\n", ret_ptr->tv_sec, ret_ptr->tv_nsec);

    msg_size = sizeof(struct timespec);

    skb_out = nlmsg_new(msg_size, 0);
    if (!skb_out) {
        printk(KERN_ERR "Failed to allocate new skb\n");
        return;
    }
    nlh = nlmsg_put(skb_out, 0, 0, NLMSG_DONE, msg_size, 0);
    NETLINK_CB(skb_out).dst_group = 0; /* not in mcast group */
    // strncpy(nlmsg_data(nlh), msg, msg_size);
    memcpy(nlmsg_data(nlh), ret_ptr, msg_size);

    res = nlmsg_unicast(nl_sk, skb_out, pid);

    if (res < 0) printk(KERN_INFO "Error while sending bak to user\n");
    kfree(ret_ptr);
}

static int remap_init(void) {
    printk("Entering: %s\n", __FUNCTION__);
    // This is for 3.6 kernels and above.
    struct netlink_kernel_cfg cfg = {.input = remap_recv_msg, };
    nl_sk = netlink_kernel_create(&init_net, NETLINK_USER, &cfg);
    if (!nl_sk) {
        printk(KERN_ALERT "Error creating socket.\n");
        return -10;
    }
    return 0;
};

static void remap_exit(void) {
    if (virt_base) iounmap((void __iomem *)virt_base);
    pr_info("Removed remap module.\n");
    netlink_kernel_release(nl_sk);
}

module_init(remap_init);
module_exit(remap_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Wuklab@UCSD");
