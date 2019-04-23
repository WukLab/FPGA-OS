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

#define ALIGN_UP(value, size)	(((value)+((size)-1)) / size * size)

#define BUF_SIZ			(4096*128)
#define READ_COUNT		300
#define KEY_SIZE		22
#define READ_SIZE		ALIGN_UP((KEY_SIZE + 24), 8)
/* make value size larger than 8 */
#define VALUE_SIZE		2048
#define WRITE_SIZE		ALIGN_UP((VALUE_SIZE + KEY_SIZE + 24), 8)

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

static int roundup(int size, int multiple)
{
	if (size % multiple == 0)
		return size;
	
	return (size / multiple) * multiple + 1;
}

static void prepare_const_key(char *key)
{
	key[0] = 0x3B;
	key[1] = 0xC6;
	key[2] = 0xE5;
	key[3] = 0xD7;
	key[4] = 0xCD;
	key[5] = 0x07;
	key[6] = 0x38;
	key[7] = 0x57;
	key[8] = 0x72;
	key[9] = 0x65;
	key[10] = 0x73;
	key[11] = 0x75;
	key[12] = 0x2D;
	key[13] = 0x65;
	key[14] = 0x6C;
	key[15] = 0x62;
	key[16] = 0x61;
	key[17] = 0x74;
	key[18] = 0x72;
	key[19] = 0x65;
	key[20] = 0x73;
	key[21] = 0x75;
}

static void prepare_kvs_read(char *buf, char *key)
{
	memset(buf, 0, READ_SIZE);
	buf[0] = 0x80;
	buf[1] = 0x00; // opcode
	buf[3] = (char)KEY_SIZE;
	buf[4] = 0x08;
	buf[11] = (char)KEY_SIZE;
	memcpy(buf + 24, key, KEY_SIZE);
}

static void prepare_multiple_kvs_read(char *buf, char *key, int size)
{
	int i;
	for (i = 0; i < size; i++) {
		prepare_kvs_read(buf + READ_SIZE*i, const_key);
	}
}

static void prepare_kvs_write(char *buf, char *key)
{
	int i;
	memset(buf, 0, WRITE_SIZE);
	buf[0] = 0x80;
	buf[1] = 0x01; // opcode
	buf[3] = (char)KEY_SIZE;
	buf[4] = 0x08;
	buf[10] = (char)((KEY_SIZE + VALUE_SIZE) / 256);
	buf[11] = (char)(KEY_SIZE + VALUE_SIZE);
	memcpy(buf + 32, key, KEY_SIZE);
	
	for (i = 0; i < 8; i++)
		buf[24 + i] = 0xAA;

	if (VALUE_SIZE <= 8)
		return;

	for (i = 0; i < VALUE_SIZE - 8; i++)
		buf[32 + KEY_SIZE + i] = i % 0xFF;
}

#define APP_ID	(0)
int main(int argc, char *argv[])
{
	char *sendbuf = NULL;
	char const_key[22];
	unsigned long addr = 0;
	/* pthread metadata declaration */
	struct to_pthread read_metadata;
	ssize_t rc;
	void *pthread_ret;
	pthread_t pcie_read_thread;
	int read_count = TOTAL_READ_COUNT;
	int i, j;

	posix_memalign((void **)&sendbuf, 4096 /*alignment */ , BUF_SIZ);
	if (!sendbuf) {
		fprintf(stderr, "Unable to allocate send buffer %lu.\n", BUF_SIZ);
		return -ENOMEM;
	}
	memset(sendbuf, 0, BUF_SIZ);

	addr = 0x0;

	prepare_const_key(const_key);
	
	//app_rdm_hdr_alloc(sendbuf, 4096, APP_ID);


#if 0
	prepare_kvs_write(sendbuf, const_key);
	for (i = 0; i < 128; i++)
		printf("buf[%d] = %x\n", i, sendbuf[i] & 0xff);
	dma_to_fpga(sendbuf, WRITE_SIZE);
#endif
#if 1
	for (i = 0; i < READ_COUNT; i++) {
		prepare_kvs_read(sendbuf + READ_SIZE*i, const_key);
	}
	
	for (i = 0; i < READ_SIZE * 2; i++)
		printf("buf[%d] = %x\n", i, sendbuf[i] & 0xff);
	for (i = READ_SIZE * (READ_COUNT - 1); i < READ_SIZE * (READ_COUNT + 1); i++)
		printf("buf[%d] = %x\n", i, sendbuf[i] & 0xff);

	//dma_to_fpga(sendbuf, READ_SIZE * READ_COUNT + WRITE_SIZE);
	dma_to_fpga(sendbuf, READ_SIZE * READ_COUNT);
#endif

	//pthread_join(pcie_read_thread, &pthread_ret);
	//free(sendbuf);
	//free(rcvbuf);
	return 0;
}
