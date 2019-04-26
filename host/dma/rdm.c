/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <pthread.h>

#include "../../include/uapi/net_header.h"
#include "../../include/uapi/pcie.h"
#include "../../app/rdma/include/rdma.h"
#include "../../app/rdma/include/host_helper.h"

#define BUF_SIZ		(4096*16)

struct to_pthread {
	unsigned long addr;
	unsigned long len;
	unsigned long count;
	char* buf;
};

static void *pcie_read(void *metadata)
{
	/*
	 * do not free buffer
	 */
	struct to_pthread* desc = (struct to_pthread*)metadata;
	//for(int i = 0; i < desc->count; i++) {
		printf("Reading....");
		dma_from_fpga(desc->buf, desc->len);
		printf("complete one read request\n");
	//}
	pthread_exit(0);
}

#define APP_ID	(0)
int main(int argc, char *argv[])
{
	char *sendbuf = NULL;
	unsigned long addr = 0;
	/* pthread metadata declaration */
	struct to_pthread read_metadata;
	ssize_t rc;
	void *pthread_ret;
	pthread_t pcie_read_thread;
	int i, write_size, read_size;

	posix_memalign((void **)&sendbuf, 4096 /*alignment */ , BUF_SIZ);
	if (!sendbuf) {
		fprintf(stderr, "Unable to allocate send buffer %lu.\n", BUF_SIZ);
		return -ENOMEM;
	}
	memset(sendbuf, 0, BUF_SIZ);

	addr = 0x0;

	/*
	 * For RDM packet format, please check app/rdma/README.md
	 * Both alloc and read packets are 128B.
	 * They only have headers.
	 */
	//app_rdm_hdr_alloc(sendbuf, 4096, APP_ID);
#if 0
	write_size = 4096;
	for (i = 0; i < write_size; i ++)
		sendbuf[i] = i % 255;
	app_rdm_hdr_write(sendbuf, addr, write_size, APP_ID);
	dma_to_fpga(sendbuf, write_size);
#endif

	//read_size = 128;
	//app_rdm_hdr_read(sendbuf, addr, read_size, APP_ID);
	//dma_to_fpga(sendbuf, 128);

	//pthread_join(pcie_read_thread, &pthread_ret);
	//free(sendbuf);
	//free(rcvbuf);
	return 0;
}
