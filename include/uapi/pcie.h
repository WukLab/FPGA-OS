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
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>

#define DEVICE_READ_DEFAULT "/dev/xdma0_c2h_0"
#define DEVICE_WRITE_DEFAULT "/dev/xdma0_h2c_0"
#define SIZE_DEFAULT (32)
#define COUNT_DEFAULT (1)

/*
 * man 2 write:
 * On Linux, write() (and similar system calls) will transfer at most
 * 	0x7ffff000 (2,147,479,552) bytes, returning the number of bytes
 *	actually transferred.  (This is true on both 32-bit and 64-bit
 *	systems.)
 */

#define RW_MAX_SIZE	0x7ffff000

static inline uint64_t getopt_integer(char *optarg)
{
	int rc;
	uint64_t value;

	rc = sscanf(optarg, "0x%lx", &value);
	if (rc <= 0)
		rc = sscanf(optarg, "%lu", &value);
	//printf("sscanf() = %d, value = 0x%lx\n", rc, value);

	return value;
}

static inline
ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = base;

	while (count < size) {
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

		if (offset) {
			rc = lseek(fd, offset, SEEK_SET);
			if (rc != offset) {
				fprintf(stderr, "%s, seek off 0x%lx != 0x%lx.\n",
					fname, rc, offset);
				perror("seek file");
				return -EIO;
			}
		}

		/* read data from file into memory buffer */
		rc = read(fd, buf, bytes);
		if (rc != bytes) {
			fprintf(stderr, "%s, R off 0x%lx, 0x%lx != 0x%lx.\n",
				fname, count, rc, bytes);
				perror("read file");
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	}

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				fname, count, size);
		return -EIO;
	}
	return count;
}

static inline
ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size,
			  uint64_t base)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = base;

	while (count < size) {
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

		if (offset) {
			rc = lseek(fd, offset, SEEK_SET);
			if (rc != offset) {
				fprintf(stderr, "%s, seek off 0x%lx != 0x%lx.\n",
					fname, rc, offset);
				perror("seek file");
				return -EIO;
			}
		}

		/* write data to file from memory buffer */
		rc = write(fd, buf, bytes);
		if (rc != bytes) {
			fprintf(stderr, "%s, W off 0x%lx, 0x%lx != 0x%lx.\n",
				fname, offset, rc, bytes);
				perror("write file");
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	}

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				fname, count, size);
		return -EIO;
	}
	return count;
}


/* Subtract timespec t2 from t1
 *
 * Both t1 and t2 must already be normalized
 * i.e. 0 <= nsec < 1000000000
 */
static inline int timespec_check(struct timespec *t)
{
	if ((t->tv_nsec < 0) || (t->tv_nsec >= 1000000000))
		return -1;
	return 0;

}

static inline
void timespec_sub(struct timespec *t1, struct timespec *t2)
{
	if (timespec_check(t1) < 0) {
		fprintf(stderr, "invalid time #1: %lld.%.9ld.\n",
			(long long)t1->tv_sec, t1->tv_nsec);
		return;
	}
	if (timespec_check(t2) < 0) {
		fprintf(stderr, "invalid time #2: %lld.%.9ld.\n",
			(long long)t2->tv_sec, t2->tv_nsec);
		return;
	}
	t1->tv_sec -= t2->tv_sec;
	t1->tv_nsec -= t2->tv_nsec;
	if (t1->tv_nsec >= 1000000000) {
		t1->tv_sec++;
		t1->tv_nsec -= 1000000000;
	} else if (t1->tv_nsec < 0) {
		t1->tv_sec--;
		t1->tv_nsec += 1000000000;
	}
}

/*
 * @buffer: align to page
 */
static inline
int dma_from_fpga(char *buffer, uint64_t size)
{
	ssize_t rc;
	uint64_t i;
	struct timespec ts_start, ts_end;
	int fpga_fd;
	long total_time = 0;
	float BW;
	float avg_time = 0;

	fpga_fd = open(DEVICE_READ_DEFAULT, O_RDWR | O_NONBLOCK);
	if (fpga_fd < 0) {
                fprintf(stderr, "unable to open device %s, %d.\n",
                        DEVICE_READ_DEFAULT, fpga_fd);
		perror("open device");
                return -EINVAL;
        }

	clock_gettime(CLOCK_MONOTONIC, &ts_start);

	rc = read_to_buffer(DEVICE_READ_DEFAULT, fpga_fd, buffer, size, 0);
	if (rc < 0)
		goto out;

	clock_gettime(CLOCK_MONOTONIC, &ts_end);
	timespec_sub(&ts_end, &ts_start);
	total_time = ts_end.tv_nsec;
	avg_time = (float)total_time;
	BW = ((float)size)*1000/avg_time;

	printf("** Avg time device %s, total time %ld nsec, avg_time = %f, size = %lu, BW = %f \n",
		DEVICE_READ_DEFAULT, total_time, avg_time, size, BW);

	rc = 0;
out:
	close(fpga_fd);
	return rc;
}

/*
 * @buffer: align to page
 * @size: size in bytes
 */
static inline
int dma_to_fpga(char *buffer, uint64_t size)
{
	ssize_t rc;
	struct timespec ts_start, ts_end;
	int fpga_fd;
	long total_time = 0;
	float BW;
	float avg_time = 0;

	fpga_fd = open(DEVICE_WRITE_DEFAULT, O_RDWR);
	if (fpga_fd < 0) {
		fprintf(stderr, "unable to open device %s, %d.\n",
			DEVICE_WRITE_DEFAULT, fpga_fd);
		perror("open device");
		return -EINVAL;
	}

	clock_gettime(CLOCK_MONOTONIC, &ts_start);

	rc = write_from_buffer(DEVICE_WRITE_DEFAULT, fpga_fd, buffer, size, 0);
	if (rc < 0)
		goto out;

	clock_gettime(CLOCK_MONOTONIC, &ts_end);
	timespec_sub(&ts_end, &ts_start);
	total_time = ts_end.tv_nsec;
	avg_time = (float)total_time;
	BW= ((float)size)*1000/avg_time;

	printf("** Avg time device %s, total time %ld nsec, avg_time = %f, size = %lu, BW = %f \n",
		DEVICE_WRITE_DEFAULT, total_time, avg_time, size, BW);
	rc = 0;

out:
	close(fpga_fd);
	return rc;
}

#endif /* _PCIE_H_ */
