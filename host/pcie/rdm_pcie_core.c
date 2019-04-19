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
#include "../include/app_rdma.h"
#include "../../include/uapi/pcie.h"

#define MY_DEST_MAC0	0x01
#define MY_DEST_MAC1	0x02
#define MY_DEST_MAC2	0x03
#define MY_DEST_MAC3	0x04
#define MY_DEST_MAC4	0x05
#define MY_DEST_MAC5	0x06

//#define DEFAULT_IF	"wlx24050ff6fc10"
#define DEFAULT_IF	"eno1"
#define BUF_SIZ		4096

/* Check README.md for packet format */
void app_rdma_prepare_write(void *buf, int tx_len, unsigned long addr)
{
	struct lego_header *lego;
	struct app_rdma_header *app;
	char *data;
	int i, data_length;

	/* 64B for all eth/ip/udp/lego headers. System-level */
	lego = buf + LEGO_HEADER_OFFSET;
	lego->app_id = 0;

	/* 64B app-level, we control */
	app = buf + APP_HEADER_OFFSET;
	app->opcode = APP_RDMA_OPCODE_WRITE;
	app->address = addr;

	data_length = tx_len - APP_RDMA_DATA_OFFSET;
	app->length = data_length;

	data = buf + APP_RDMA_DATA_OFFSET;
	for (i = 0; i < data_length; i ++) {
		data[i] = i + 1;
	}
}

void app_rdma_prepare_read(void *buf, unsigned long address, unsigned long length)
{
	struct lego_header *lego;
	struct app_rdma_header *app;
	char *data;
	int i;

	/* 64B for all eth/ip/udp/lego headers. System-level */
	lego = buf + LEGO_HEADER_OFFSET;
	lego->app_id = 0;

	/* 64B app-level, we control */
	app = buf + APP_HEADER_OFFSET;
	app->opcode = APP_RDMA_OPCODE_READ;
	app->address = address;
	app->length = length;
}

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
		dev_read(desc->addr, desc->len, desc->count, desc->buf);
		printf("complete one read request\n");
	//}
	pthread_exit(0);
}


int main(int argc, char *argv[])
{
	char *sendbuf = NULL, *rcvbuf = NULL;
	int tx_len;
	struct ifreq if_idx;
	struct ifreq if_mac;
	struct ether_header *eh = NULL;
	struct iphdr *iph = NULL;
	char ifName[IFNAMSIZ];
	unsigned long addr = 0;

	/* pthread metadata declaration */
	struct to_pthread read_metadata;
	ssize_t rc;
	void *pthread_ret;
	pthread_t pcie_read_thread;

	/* Get interface name */
	verbose = 1;
	if (argc > 1)
		strcpy(ifName, argv[1]);
	else
		strcpy(ifName, DEFAULT_IF);

	posix_memalign((void **)&sendbuf, 4096 /*alignment */ , BUF_SIZ);
	if (!sendbuf) {
		fprintf(stderr, "Unable to allocate send buffer %lu.\n", BUF_SIZ);
		return -ENOMEM;
	}

	posix_memalign((void **)&rcvbuf, 4096 /*alignment */ , BUF_SIZ);
	if (!rcvbuf) {
		fprintf(stderr, "Unable to allocate rcv buffer %lu.\n", BUF_SIZ);
		free(sendbuf);
		return -ENOMEM;
	}

	/* create a second thread which polls read data */
	read_metadata.addr = addr;
	read_metadata.len = BUF_SIZ;
	read_metadata.count = 1;
	read_metadata.buf = rcvbuf;
	if(rc = pthread_create(&pcie_read_thread, NULL, pcie_read, (void *)&read_metadata)) {
		fprintf(stderr, "Error creating pthread\n");
		free(sendbuf);
		free(rcvbuf);
		return rc;
	}

	/* assign pointer to header */
	eh = (struct ether_header *) sendbuf;
	iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));



	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);

	/*
	 * Cook the buffer
	 */
	memset(sendbuf, 0, BUF_SIZ);
	memset(rcvbuf, 0, BUF_SIZ);

	/* Ethernet header */
	eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = MY_DEST_MAC0;
	eh->ether_dhost[1] = MY_DEST_MAC1;
	eh->ether_dhost[2] = MY_DEST_MAC2;
	eh->ether_dhost[3] = MY_DEST_MAC3;
	eh->ether_dhost[4] = MY_DEST_MAC4;
	eh->ether_dhost[5] = MY_DEST_MAC5;
	/* Ethertype field */
	eh->ether_type = htons(ETH_P_IP);

	addr = 0x0;

#if 1
	/* Write */
	printf("Write\n");
	app_rdma_prepare_write(sendbuf, BUF_SIZ, addr);
	dev_write(addr, BUF_SIZ, 1, sendbuf);

#endif

	/* READ */
	printf("Read\n");
	app_rdma_prepare_read(sendbuf, addr, BUF_SIZ);
	dev_write(addr, APP_RDMA_DATA_OFFSET, 1, sendbuf);

	pthread_join(pcie_read_thread, &pthread_ret);

	free(sendbuf);
	free(rcvbuf);
	return 0;
}
