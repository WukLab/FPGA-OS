/*
 * Some generic host side helpers to setup packet.
 * Check README.md for packet format details.
 */
#ifndef _APP_RDMA_HELPER_H_
#define _APP_RDMA_HELPER_H_

#include <uapi/net_header.h>

/*
 * FAT NOTE:
 *
 * Both RDM read and write should use the virtual address
 * returned by RDM alloc. Otherwise the access might fail.
 * (Unless you are using based_addr = 0, and somehow hit
 * on the AddrMap's BRAM hashtable.)
 *
 * About WRITE packet length:
 * Since each packet has a fixed 128B header, if you wish to
 * WRITE, say N bytes, to FPGA DRAM, you will need to prepare
 * a buffer equals or larger than (N+128).
 */

static inline void
app_rdm_hdr_write(void *buf, unsigned int app_id,
		  unsigned long base_addr, unsigned long length)
{
	struct app_rdma_header *app;
	struct lego_header *lego;
	int i, data_length;

	/* Frist 64B used by eth/ip/udp/lego headers. */
	lego = buf + LEGO_HEADER_OFFSET;
	lego->app_id = app_id;

	/* Second 64B used by RDM headers */
	app = buf + APP_HEADER_OFFSET;
	app->opcode = APP_RDMA_OPCODE_WRITE;
	app->address = base_addr;
	app->length = length;
}

static inline void
app_rdm_hdr_read(void *buf, unsigned int app_id,
		 unsigned long base_addr, unsigned long length)
{
	struct lego_header *lego;
	struct app_rdma_header *app;

	/* Frist 64B used by eth/ip/udp/lego headers. */
	lego = buf + LEGO_HEADER_OFFSET;
	lego->app_id = app_id;

	/* Second 64B used by RDM headers */
	app = buf + APP_HEADER_OFFSET;
	app->opcode = APP_RDMA_OPCODE_READ;
	app->address = base_addr;
	app->length = length;
}

static inline void
app_rdm_hdr_alloc(void *buf, unsigned int app_id, unsigned long alloc_size)
{
	struct lego_header *lego;
	struct app_rdma_header *app;

	/* Frist 64B used by eth/ip/udp/lego headers. */
	lego = buf + LEGO_HEADER_OFFSET;
	lego->app_id = app_id;

	/* Second 64B used by RDM headers */
	app = buf + APP_HEADER_OFFSET;
	app->opcode = APP_RDMA_OPCODE_ALLOC;
	app->address = 0;
	app->length = alloc_size;
}

#endif /* _APP_RDMA_HELPER_H_ */
