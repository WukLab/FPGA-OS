/*
 * This file is part of the Xilinx DMA IP Core driver tools for Linux
 *
 * Copyright (c) 2016-present,  Xilinx, Inc.
 * All rights reserved.
 *
 * This source code is licensed under both the BSD-style license (found in the
 * LICENSE file in the root directory of this source tree) and the GPLv2 (found
 * in the COPYING file in the root directory of this source tree).
 * You may select, at your option, one of the above-listed licenses.
 */

#ifndef _PCIE_H_
#define _PCIE_H_

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/types.h>

#define DEVICE_READ_DEFAULT "/dev/xdma0_c2h_0"
#define DEVICE_WRITE_DEFAULT "/dev/xdma0_h2c_0"
#define SIZE_DEFAULT (32)
#define COUNT_DEFAULT (1)

static int verbose = 0;

uint64_t getopt_integer(char *optarg);

void timespec_sub(struct timespec *t1, struct timespec *t2);

ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);

ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);

int dev_read(uint64_t addr, uint64_t size, uint64_t count, char *buffer);

int dev_write(uint64_t addr, uint64_t size, uint64_t count, char *buffer);

#endif /* _PCIE_H_ */