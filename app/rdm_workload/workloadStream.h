
#ifndef WORKSTREAM_HEADER
#define WORKSTREAM_HEADER
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <time.h>
#include <getopt.h>
#include <errno.h>
#include <linux/types.h>
#include <stdlib.h>

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

static void printHelp(char *name);
double diff_ns(struct timespec *start, struct timespec *end);
void myDump(char *desc, uint8_t *addr, int len);
int getWorkload(size_t **size_array_ptr, uint8_t ***packet_array_ptr,
                uint32_t **interarrival_array_ptr, char *filename,
                int pad_size);
int deliverRequestPCIe(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       int pad_size, void *pcie_send_addr,
                       void *pcie_recv_addr);
int deliverRequestRDMA(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       int pad_size);
void *getPCIeRecvAddr(void);
void *getPCIeSendAddr(size_t required_size);
int deliverRequest(int request_num, size_t *size_array, uint8_t **packet_array,
                   uint32_t *interarrival_array, int pad_size, int interface);
#include "rdma_setup.h"
#endif
