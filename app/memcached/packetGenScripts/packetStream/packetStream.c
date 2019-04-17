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

#define MY_DEST_MAC0 0x00
#define MY_DEST_MAC1 0x00
#define MY_DEST_MAC2 0x00
#define MY_DEST_MAC3 0x00
#define MY_DEST_MAC4 0x00
#define MY_DEST_MAC5 0x00

enum INTERFACE_TYPE {
    INTERFACE_ETHERNET = 1,
    INTERFACE_PCIE = 2
};
#define DEFAULT_IF "virbr0"
#define DEFAULT_REPLY_SIZE 4096

int debug_mode = 0;

static char *workload_file_name;

static void printHelp(char *name) {
    printf("\nUSAGE: %s [OPTIONS]\n", name);
    printf("\t-w \tpacket data. (ycsb_workload_packets.txt)\n");
    printf("\t-p \tpad_size. pad Bytes before payload\n");
    printf("\t-m \tmode. eth/pcie\n");
    printf("\t-v \tverbose mode\n");
    printf("\t--help             \tprint this message.\n");
    printf("\n");
}

double diff_ns(struct timespec *start, struct timespec *end) {
    double time;

    time = (end->tv_sec - start->tv_sec) * 1000 * 1000 * 1000;
    time += (end->tv_nsec - start->tv_nsec);

    return time;
}

void myDump(char *desc, uint8_t *addr, int len) {
    int i;
    uint8_t *pc = (uint8_t *)addr;

    if (desc != NULL) printf("%s", desc);

    for (i = 0; i < len; i++) {
        if ((i % 4) == 0) {
            printf("\n");
            printf(" %04x ", i);
        }
        printf(" %02x", pc[i]);
    }
    printf("\n");
}

int hexadecimalToDecimal(char *hexVal) {
    // int len = strlen(hexVal);
    int len = 2;

    // Initializing base value to 1, i.e 16^0
    int base = 1;
    int dec_val = 0;
    int i;

    // Extracting characters as digits from last character
    for (i = len - 1; i >= 0; i--) {
        // if character lies in '0'-'9', converting
        // it to integral 0-9 by subtracting 48 from
        // ASCII value.
        if (hexVal[i] >= '0' && hexVal[i] <= '9') {
            dec_val += (hexVal[i] - 48) * base;
            // incrementing base by power
            base = base * 16;
        }
        // if character lies in 'A'-'F' , converting
        // it to integral 10 - 15 by subtracting 55
        // from ASCII value
        else if (hexVal[i] >= 'A' && hexVal[i] <= 'F') {
            dec_val += (hexVal[i] - 55) * base;
            // incrementing base by power
            base = base * 16;
        }
    }
    return dec_val;
}

size_t sizeLineToSize(char *size_line) {
    if (!strcmp(size_line, "FF"))
        return 8;
    else if (!strcmp(size_line, "7F"))
        return 7;
    else if (!strcmp(size_line, "3F"))
        return 6;
    else if (!strcmp(size_line, "1F"))
        return 5;
    else if (!strcmp(size_line, "0F"))
        return 4;
    else if (!strcmp(size_line, "07"))
        return 3;
    else if (!strcmp(size_line, "03"))
        return 2;
    else if (!strcmp(size_line, "01"))
        return 1;
    else
        printf("Error size char %s\n", size_line);
    exit(1);
}

int getWorkload(size_t **size_array_ptr, uint8_t ***packet_array_ptr,
                char *filename, int pad_size) {
    size_t *size_array;
    uint8_t **packet_array;
    int num_of_reqs = 0;
    FILE *fp;
    char str_line[100], content_line[100], size_line[2];
    int available_line = 0;
    int current_packet = 0;
    int i;
    int base = 0;

    fp = fopen(filename, "r");
    if (fp == NULL) {
        perror("Error opening file");
        return (-1);
    }

    // get number of packets
    while (fgets(str_line, sizeof(str_line), fp) != NULL) {
        if (available_line == 0) {
            sscanf(str_line, "%d", &available_line);
            num_of_reqs++;
        } else {
            available_line--;
        }
    }
    fclose(fp);
    printf("total request num %d\n", num_of_reqs);

    size_array = malloc(sizeof(size_t) * num_of_reqs);
    packet_array = malloc(sizeof(char *) * num_of_reqs);

    fp = fopen(filename, "r");
    // get packet size
    available_line = 0;
    while (fgets(str_line, sizeof(str_line), fp) != NULL) {
        if (available_line == 0) {
            sscanf(str_line, "%d", &available_line);
            size_array[current_packet] = pad_size;
        } else {
            available_line--;
            sscanf(str_line, "%s %s", content_line, size_line);
            size_array[current_packet] += sizeLineToSize(size_line);
            // printf("%d:%d\n", current_packet, size_array[current_packet]);
            if (available_line == 0) current_packet++;
        }
    }
    fclose(fp);
    for (i = 0; i < num_of_reqs; i++) {
        size_t alloc_size = ((size_array[i] + 8 - 1) / 8) * 8;
        packet_array[i] = malloc(alloc_size);
        // printf("%d, %d\n", size_array[i], alloc_size);
    }
    fp = fopen(filename, "r");
    // get packet content
    available_line = 0;
    current_packet = 0;
    base = pad_size;
    while (fgets(str_line, sizeof(str_line), fp) != NULL) {
        if (available_line == 0) {
            sscanf(str_line, "%d", &available_line);
            base = pad_size;
        } else {
            available_line--;
            sscanf(str_line, "%s %s", content_line, size_line);
            for (i = 14; i >= 0; i = i - 2) {
                packet_array[current_packet][base] =
                    hexadecimalToDecimal(&content_line[i]);
                // printf("%x %s\n", packet_array[i][base], &content_line[i]);
                base++;
            }
            if (available_line == 0) current_packet++;
        }
    }
    fclose(fp);
    *size_array_ptr = size_array;
    *packet_array_ptr = packet_array;
    return num_of_reqs;
}

int deliverRequestPCIe(int request_num, size_t *size_array,
                       uint8_t **packet_array, void *pcie_send_addr,
                       void *pcie_recv_addr) {
    int each_packet;

    char reply[DEFAULT_REPLY_SIZE];
    void *base = pcie_send_addr;
    struct timespec start, end;
    double time_diff;
    int *check_counter_addr = (int *)pcie_recv_addr;

    memset(reply, 0, DEFAULT_REPLY_SIZE);

    /* Construct the Ethernet header */
    for (each_packet = 0; each_packet < request_num; each_packet++) {

        // set LEGOFPGA header here

        /* dump network frame */
        if (debug_mode) {
            printf("===== %d =====\n", each_packet);
            myDump(NULL, packet_array[each_packet], size_array[each_packet]);
        }
    }

    clock_gettime(CLOCK_MONOTONIC, &start);
    /* Send packet */
    for (each_packet = 0; each_packet < request_num; each_packet++) {
        memcpy(base, packet_array[each_packet], size_array[each_packet]);
        base = base + size_array[each_packet];
    }
    /* this part is for debugging */

    if (debug_mode) {
        base = pcie_send_addr;
        for (each_packet = 0; each_packet < request_num; each_packet++) {
            myDump(NULL, base, size_array[each_packet]);
            base = base + size_array[each_packet];
        }
    }

    if (debug_mode) {
        int count = 0;
        while (*check_counter_addr != request_num && count <= 10) {
            printf("%d\n", *check_counter_addr);
            count++;
        }
    } else {
        while (*check_counter_addr != request_num)
            ;
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    time_diff = diff_ns(&start, &end);

    printf("finish %d request in %f ns \n", each_packet, time_diff);
    return 0;
}

int deliverRequestEthernet(int request_num, size_t *size_array,
                           uint8_t **packet_array) {
    int each_packet;
    int sockfd;
    struct ifreq if_idx;
    struct ifreq if_mac;
    struct ether_header *eh;
    struct sockaddr_ll socket_address;
    char ifName[IFNAMSIZ];

    char reply[DEFAULT_REPLY_SIZE];

    memset(reply, 0, DEFAULT_REPLY_SIZE);

    /* Get interface name */
    strcpy(ifName, DEFAULT_IF);

    /* Open RAW socket to send on */
    if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
        perror("socket");
    }

    /* Get the index of the interface to send on */
    memset(&if_idx, 0, sizeof(struct ifreq));
    strncpy(if_idx.ifr_name, ifName, IFNAMSIZ - 1);
    if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0) perror("SIOCGIFINDEX");
    /* Get the MAC address of the interface to send on */
    memset(&if_mac, 0, sizeof(struct ifreq));
    strncpy(if_mac.ifr_name, ifName, IFNAMSIZ - 1);
    if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0) perror("SIOCGIFHWADDR");

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

    /* Construct the Ethernet header */
    for (each_packet = 0; each_packet < request_num; each_packet++) {
        eh = (struct ether_header *)packet_array[each_packet];

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

        /* dump network frame */
        if (debug_mode) {
            printf("===== %d =====\n", each_packet);
            myDump(NULL, packet_array[each_packet], size_array[each_packet]);
        }
    }

    /* Send packet */
    for (each_packet = 0; each_packet < request_num; each_packet++) {
        if (sendto(sockfd, packet_array[each_packet], size_array[each_packet],
                   0, (struct sockaddr *)&socket_address,
                   sizeof(struct sockaddr_ll)) < 0)
            printf("Send failed %d\n", each_packet);
        // rec_items = recvfrom(sockfd, reply, DEFAULT_REPLY_SIZE, 0, NULL,
        // NULL);
    }

    printf("finish %d request\n", each_packet);
    return 0;
}

void *getPCIeRecvAddr(void) {
    // Once Yutong completes the setup of PCIe,
    // this function should return a virtual address points to a counter.

    // FPGA side will keep updating this counter
    // and host-side will terminate the whole program
    // once the counter is identical to the number of sent request.

    // Currently, I used a regular malloc to get this address
    // Shin-Yeh Tsai 041619
    void *ret_addr = malloc(sizeof(unsigned long long int));
    memset(ret_addr, 0, sizeof(unsigned long long int));
    if (ret_addr == NULL) {
        printf("generate recv addr error\n");
        exit(1);
    }
    return ret_addr;
}

void *getPCIeSendAddr(size_t required_size) {
    // Once Yutong completes the setup of PCIe,
    // this function should return a virtual address points to DMA address.

    // FPGA side will keep reading this address to get operations
    // and host-side will write data into this address

    // Currently, I used a regular malloc to get this address
    // Shin-Yeh Tsai 041619
    void *ret_addr = malloc(required_size);
    memset(ret_addr, 0, required_size);
    if (ret_addr == NULL) {
        printf("generate send addr error\n");
        exit(1);
    }
    return ret_addr;
}

int deliverRequest(int request_num, size_t *size_array, uint8_t **packet_array,
                   int interface) {
    int ret = -1;
    void *pcie_recv_addr, *pcie_send_addr;
    uint64_t total_size;
    int per_request;
    switch (interface) {
        case INTERFACE_ETHERNET:
            ret = deliverRequestEthernet(request_num, size_array, packet_array);
            break;
        case INTERFACE_PCIE:
            total_size = 0;
            for (per_request = 0; per_request < request_num; per_request++) {
                total_size += size_array[per_request];
            }
            pcie_recv_addr = getPCIeRecvAddr();
            pcie_send_addr = getPCIeSendAddr(total_size);
            ret = deliverRequestPCIe(request_num, size_array, packet_array,
                                     pcie_send_addr, pcie_recv_addr);
            break;
        default:
            printf("interface %d is not implemented yet\n", interface);
            exit(1);
    }
    return ret;
}

int main(int argc, char *argv[]) {
    int request_num;
    size_t *size_array;
    uint8_t **packet_array;

    int pad_size = -1;
    int opt;
    int option_index = 0;
    char *deliver_mode = NULL;
    // parse parameters
    static struct option long_options[] = {
        {"workload_file_name", required_argument, 0, 'w'},
        {"mode (pcie/eth)", required_argument, 0, 'm'},
        {"pad_size", required_argument, 0, 'p'},
        {"mode", required_argument, 0, 'p'},
        {"debug", required_argument, 0, 'v'},
        {"help", no_argument, 0, 'h'},
        {NULL, 0, 0, 0}};

    while ((opt = getopt_long(argc, argv, "vhw:p:m:", long_options,
                              &option_index)) >= 0) {
        switch (opt) {
            case 0:
                break;
            case 'w':
                workload_file_name = optarg;
                break;
            case 'm':
                deliver_mode = optarg;
                break;
            case 'p':
                pad_size = atoi(optarg);
                break;
            case 'v':
                debug_mode = 1;
                break;
            case 'h':
                printHelp(argv[0]);
                return 0;
                break;
            default:
                printHelp(argv[0]);
                return -1;
        }
    }  // finished parameter parsing
    if (workload_file_name == NULL || pad_size == -1 || deliver_mode == NULL) {
        printf("check help\n");
        exit(1);
    }
    if (pad_size < sizeof(struct ether_header)) {
        printf("pad_size: %d should at least %lu\n", pad_size,
               sizeof(struct ether_header));
        exit(1);
    }

    printf("workload_file_name is %s\n", workload_file_name);
    printf("pad_size is %d B\n", pad_size);

    // parse workload
    request_num =
        getWorkload(&size_array, &packet_array, workload_file_name, pad_size);

    // deliver request
    if (strcmp(deliver_mode, "eth") == 0)
        deliverRequest(request_num, size_array, packet_array,
                       INTERFACE_ETHERNET);
    else if (strcmp(deliver_mode, "pcie") == 0)
        deliverRequest(request_num, size_array, packet_array, INTERFACE_PCIE);
    else {
        printf("error mode %s\n", deliver_mode);
        printHelp(deliver_mode);
    }

    return 0;
}
