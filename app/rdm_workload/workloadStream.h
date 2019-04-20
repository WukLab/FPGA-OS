
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

#include "../../include/uapi/net_header.h"
#include "../../include/uapi/pcie.h"
#include "../../app/rdma/include/rdma.h"
#include "../../app/rdma/include/host_helper.h"

#define ROUND_UP(N, S) ((((N) + (S) - 1) / (S)) * (S))
#define LEGOFPGA_HEADER_SIZE 64

#define RDM_APP_ID (0)
#define BUF_SIZE 0x3ffff000

struct osdi_mem_workload_struct {
    // uint32_t batch_id;
    uint64_t time_stamp;
    uint64_t offset;
    uint32_t size;  // should be multiple of 4K pages or DEFAULT_PAGE_SIZE
    char mode;

    // above variables are provided by workload
    // below variables are calculated by this program
    uint32_t interarrival_time;
};

struct osdi_mem_workload_header {
    char mode;
    uint64_t offset;
    uint32_t size;  // should be multiple of 4K pages or DEFAULT_PAGE_SIZE
};

typedef struct osdi_mem_workload_struct workload_struct;
typedef struct osdi_mem_workload_header workload_header;

static void printHelp(char *name);
double diff_ns(struct timespec *start, struct timespec *end);
void myDump(char *desc, uint8_t *addr, int len);
int getWorkload(size_t **size_array_ptr, uint8_t ***packet_array_ptr,
                uint32_t **interarrival_array_ptr,
                workload_header **header_array_ptr, char *filename,
                int pad_size);
int deliverRequestPCIe(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       workload_header *header_array, int pad_size,
                       void *pcie_send_addr, void *pcie_recv_addr);
int deliverRequestRDMA(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       workload_header *header_array, int pad_size);
void *getPCIeRecvAddr(void);
void *getPCIeSendAddr(size_t required_size);
int deliverRequest(int request_num, size_t *size_array, uint8_t **packet_array,
                   uint32_t *interarrival_array, workload_header *header_array,
                   int pad_size, int interface);
#include "rdma_setup.h"
#endif
