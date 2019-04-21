
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

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <assert.h>

#define MY_DEST_MAC0 0x00
#define MY_DEST_MAC1 0x00
#define MY_DEST_MAC2 0x00
#define MY_DEST_MAC3 0x00
#define MY_DEST_MAC4 0x00
#define MY_DEST_MAC5 0x00

#include "../../../../include/uapi/net_header.h"
#include "../../../../include/uapi/pcie.h"
#include "../../../../app/rdma/include/rdma.h"
#include "../../../../app/rdma/include/host_helper.h"

#define ROUND_UP(N, S) ((((N) + (S) - 1) / (S)) * (S))
#define LEGOFPGA_HEADER_SIZE 64

#define KVS_APP_ID (1)
#define BUF_SIZE 0x3ffff000

enum INTERFACE_TYPE {
    INTERFACE_ETHERNET = 1,
    INTERFACE_PCIE = 2
};
#define DEFAULT_IF "virbr0"
#define DEFAULT_REPLY_SIZE 4096
static void printHelp(char *name);
double diff_ns(struct timespec *start, struct timespec *end);
void myDump(char *desc, uint8_t *addr, int len);
int hexadecimalToDecimal(char *hexVal);
size_t sizeLineToSize(char *size_line);
int getWorkload(size_t **size_array_ptr, uint8_t ***packet_array_ptr,
                char *filename, int pad_size);
int deliverRequestPCIe(int request_num, size_t *size_array,
                       uint8_t **packet_array, void *pcie_send_addr,
                       void *pcie_recv_addr);
int deliverRequestEthernet(int request_num, size_t *size_array,
                           uint8_t **packet_array);
void *getPCIeRecvAddr(void);
void *getPCIeSendAddr(size_t required_size);
int deliverRequest(int request_num, size_t *size_array, uint8_t **packet_array,
                   int interface);
