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

#include <fcntl.h>
#include "../../include/uapi/pcie.h"

/*
 * dev_read: modified version of test_dma above
 * @buffer: align to page
 */
int dev_read(uint64_t addr, uint64_t size, uint64_t count, char *buffer)
{
	ssize_t rc;
	uint64_t i;
	struct timespec ts_start, ts_end;
	int fpga_fd = open(DEVICE_READ_DEFAULT, O_RDWR | O_NONBLOCK);
	long total_time = 0;
	float result;
	float avg_time = 0;

	if (fpga_fd < 0) {
                fprintf(stderr, "unable to open device %s, %d.\n",
                        DEVICE_READ_DEFAULT, fpga_fd);
		perror("open device");
                return -EINVAL;
        }

	for (i = 0; i < count; i++) {
		rc = clock_gettime(CLOCK_MONOTONIC, &ts_start);
		/* lseek & read data from AXI MM into buffer using SGDMA */
		rc = read_to_buffer(DEVICE_READ_DEFAULT, fpga_fd, buffer, size, addr);
		if (rc < 0)
			goto out;
		clock_gettime(CLOCK_MONOTONIC, &ts_end);

		/* subtract the start time from the end time */
		timespec_sub(&ts_end, &ts_start);
		total_time += ts_end.tv_nsec;
		/* a bit less accurate but side-effects are accounted for */
		if (verbose)
		fprintf(stdout,
			"#%lu: CLOCK_MONOTONIC %ld.%09ld sec. read %ld bytes\n",
			i, ts_end.tv_sec, ts_end.tv_nsec, size);

	}
	avg_time = (float)total_time/(float)count;
	result = ((float)size)*1000/avg_time;
	if (verbose)
	printf("** Avg time device %s, total time %ld nsec, avg_time = %f, size = %lu, BW = %f \n",
		DEVICE_READ_DEFAULT, total_time, avg_time, size, result);
	printf("** Average BW = %lu, %f\n", size, result);
	rc = 0;

out:
	close(fpga_fd);
	return rc;
}

/*
 * dev_write: modified version of test_dma above
 * @buffer: align to page
 */
int dev_write(uint64_t addr, uint64_t size, uint64_t count, char *buffer)
{
	uint64_t i;
	ssize_t rc;
	struct timespec ts_start, ts_end;
	int fpga_fd = open(DEVICE_WRITE_DEFAULT, O_RDWR);
	long total_time = 0;
	float result;
	float avg_time = 0;

	if (fpga_fd < 0) {
		fprintf(stderr, "unable to open device %s, %d.\n",
			DEVICE_WRITE_DEFAULT, fpga_fd);
		perror("open device");
		return -EINVAL;
	}

	for (i = 0; i < count; i++) {
		/* write buffer to AXI MM address using SGDMA */
		rc = clock_gettime(CLOCK_MONOTONIC, &ts_start);

		rc = write_from_buffer(DEVICE_WRITE_DEFAULT, fpga_fd, buffer, size, addr);
		if (rc < 0)
			goto out;

		rc = clock_gettime(CLOCK_MONOTONIC, &ts_end);
		/* subtract the start time from the end time */
		timespec_sub(&ts_end, &ts_start);
		total_time += ts_end.tv_nsec;
		/* a bit less accurate but side-effects are accounted for */
		if (verbose)
		fprintf(stdout,
			"#%lu: CLOCK_MONOTONIC %ld.%09ld sec. write %ld bytes\n",
			i, ts_end.tv_sec, ts_end.tv_nsec, size);

	}
	avg_time = (float)total_time/(float)count;
	result = ((float)size)*1000/avg_time;
	if (verbose)
	printf("** Avg time device %s, total time %ld nsec, avg_time = %f, size = %lu, BW = %f \n",
		DEVICE_WRITE_DEFAULT, total_time, avg_time, size, result);

	printf("** Average BW = %lu, %f\n",size, result);
	rc = 0;

out:
	close(fpga_fd);
	return rc;
}
