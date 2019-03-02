
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

#include "../include/rdma.h"
#include "../../../include/uapi/net_header.h"

#define MY_DEST_MAC0	0x01
#define MY_DEST_MAC1	0x02
#define MY_DEST_MAC2	0x03
#define MY_DEST_MAC3	0x04
#define MY_DEST_MAC4	0x05
#define MY_DEST_MAC5	0x06

//#define DEFAULT_IF	"wlx24050ff6fc10"
#define DEFAULT_IF	"eno1"
#define BUF_SIZ		1024

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

int main(int argc, char *argv[])
{
	int sockfd, i, tx_len;
	struct ifreq if_idx;
	struct ifreq if_mac;
	char sendbuf[BUF_SIZ];
	char recvbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	struct iphdr *iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));
	struct sockaddr_ll socket_address;
	char ifName[IFNAMSIZ];
	unsigned long addr;
	
	/* Get interface name */
	if (argc > 1)
		strcpy(ifName, argv[1]);
	else
		strcpy(ifName, DEFAULT_IF);

	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
	    perror("socket");
	}

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	    perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	    perror("SIOCGIFHWADDR");

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MY_DEST_MAC0;
	socket_address.sll_addr[1] = MY_DEST_MAC1;
	socket_address.sll_addr[2] = MY_DEST_MAC2;
	socket_address.sll_addr[3] = MY_DEST_MAC3;
	socket_address.sll_addr[4] = MY_DEST_MAC4;
	socket_address.sll_addr[5] = MY_DEST_MAC5;

	/*
	 * Cook the buffer
	 */
	memset(sendbuf, 0, BUF_SIZ);

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

	addr = 0x100;

	/* Write */
	printf("Write\n");
	tx_len = 300;
	app_rdma_prepare_write(sendbuf, tx_len, addr);
	if (sendto(sockfd, sendbuf, tx_len, 0,
		   (struct sockaddr *)&socket_address,
		   sizeof(struct sockaddr_ll)) < 0)
		printf("Send failed\n");

	/* READ */
#if 1
	printf("Read\n");
	tx_len = APP_RDMA_DATA_OFFSET;
	app_rdma_prepare_read(sendbuf, addr, 64);
	if (sendto(sockfd, sendbuf, tx_len, 0,
		   (struct sockaddr *)&socket_address,
		   sizeof(struct sockaddr_ll)) < 0)
		printf("Send failed\n");

	if (recvfrom(sockfd, recvbuf, BUF_SIZ, 0,
		   (struct sockaddr *)&socket_address,
		   NULL))
		printf("Recv failed\n");

#define NR_BYTES_PER_LINE 32
	for (i = 0; i < tx_len; i++) {
		if (i % NR_BYTES_PER_LINE == 0)
			printf("[%4d - %4d] ", i, i  + NR_BYTES_PER_LINE - 1);
		printf("%02x ", recvbuf[i]);
		if ((i+1) % NR_BYTES_PER_LINE == 0 && i > 0)
			printf("\n");
	}
#endif


	return 0;
}
