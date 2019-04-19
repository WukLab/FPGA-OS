#include "workloadStream.h"
enum INTERFACE_TYPE {
    INTERFACE_ETHERNET = 1,
    INTERFACE_PCIE = 2,
    INTERFACE_RDMA = 3
};
#define DEFAULT_REPLY_SIZE 4096

#define DEFAULT_PAGE_SIZE 4096

uint64_t MAX_REQUEST = 0xffffffffffffffff;
uint64_t IGNORE_REQUEST = 0;
uint64_t MAX_ACCESS_OFFSET = 0;
int MACHINE_ID = -1;

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

int debug_mode = 0;

static char *workload_file_name;

static void printHelp(char *name) {
    printf("\nUSAGE: %s [OPTIONS]\n", name);
    printf(
        "\t-w \tworkload data. "
        "(graphlab/0-mem-ec2-54-197-111-1.compute-1.amazonaws.com.merged)\n");
    printf("\t-n \tmax request num. \n");
    printf("\t-i \tignore first i lines. \n");
    printf("\t-I \tmachine id. \n");
    printf("\t-p \tpad_size. pad Bytes before payload\n");
    printf("\t-m \tmode. eth/pcie\n");
    printf("\t-v \tverbose mode\n");
    printf("\t--help             \tprint this message.\n");
    printf(
        "\t./workloadStream -w "
        "graphlab/0-mem-ec2-54-197-111-1.compute-1.amazonaws.com.merged -p 14 "
        "-m pcie -n 1000 -i 50000 -v\n");
    printf(
        "./workloadStream.o -w "
        "graphlab/0-mem-ec2-54-197-111-1.compute-1.amazonaws.com.merged -p 14 "
        "-m rdma -n 1000 -i 50000 -v -I 1\n");
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
    printf("\n %d", fast_rand(5));
}

int getWorkload(size_t **size_array_ptr, uint8_t ***packet_array_ptr,
                uint32_t **interarrival_array_ptr, char *filename,
                int pad_size) {
    size_t *size_array;
    uint8_t **packet_array;
    uint32_t *interarrival_array;
    int num_of_reqs = 0, num_of_ignore = 0;
    FILE *fp;
    char str_line[100];
    long long int _request_offset, _request_size, _batch_id, _time_stamp;
    long long int _last_time = 0;
    int i;
    int current_request = 0;
    workload_header *header_ptr;

    workload_struct *workload_array;

    fp = fopen(filename, "r");
    if (fp == NULL) {
        perror("Error opening file");
        return (-1);
    }

    // ignore first IGNORE_REQUEST
    num_of_ignore = 0;
    while (fgets(str_line, sizeof(str_line), fp) != NULL &&
           num_of_ignore < IGNORE_REQUEST) {
        num_of_ignore++;
    }

    // get number of request
    while (fgets(str_line, sizeof(str_line), fp) != NULL &&
           num_of_reqs < MAX_REQUEST) {
        num_of_reqs++;
    }
    fclose(fp);
    printf("total request num %d\n", num_of_reqs);
    workload_array = malloc(sizeof(workload_struct) * num_of_reqs);

    size_array = malloc(sizeof(size_t) * num_of_reqs);
    packet_array = malloc(sizeof(char *) * num_of_reqs);
    interarrival_array = malloc(sizeof(uint32_t) * num_of_reqs);

    fp = fopen(filename, "r");

    // ignore first IGNORE_REQUEST
    num_of_ignore = 0;
    while (fgets(str_line, sizeof(str_line), fp) != NULL &&
           num_of_ignore < IGNORE_REQUEST) {
        num_of_ignore++;
    }
    // get packet size
    while (fgets(str_line, sizeof(str_line), fp) != NULL &&
           current_request < num_of_reqs) {
        sscanf(str_line, "%llu %llu %lld %llu", &_batch_id, &_time_stamp,
               &_request_offset, &_request_size);
        if (_request_offset >= 0) {
            workload_array[current_request].mode = 'w';
            workload_array[current_request].offset = _request_offset;
        } else {
            workload_array[current_request].mode = 'r';
            workload_array[current_request].offset = -_request_offset;
        }
        workload_array[current_request].time_stamp = _time_stamp;
        workload_array[current_request].size =
            _request_size * DEFAULT_PAGE_SIZE;
        if (workload_array[current_request].size +
                workload_array[current_request].offset >
            MAX_ACCESS_OFFSET) {
            MAX_ACCESS_OFFSET = workload_array[current_request].size +
                                workload_array[current_request].offset;
        }
        if (_last_time == 0)
            _last_time = workload_array[current_request].time_stamp;
        if (current_request > 0)
            workload_array[current_request - 1].interarrival_time =
                workload_array[current_request].time_stamp - _last_time;
        _last_time = workload_array[current_request].time_stamp;

        current_request++;
    }
    fclose(fp);

    // record
    for (i = 0; i < num_of_reqs; i++) {
        size_array[i] =
            pad_size + sizeof(workload_header) + workload_array[i].size;
        interarrival_array[i] = workload_array[i].interarrival_time;
    }

    // alloc header space and pad size
    for (i = 0; i < num_of_reqs; i++) {
        // size_t alloc_size = ((size_array[i] + 8 - 1) / 8) * 8;
        size_t alloc_size = (pad_size + sizeof(workload_header));
        packet_array[i] = malloc(alloc_size);
    }

    // set packet content
    // this part should be modified in the future once rdm finalizes the header
    // format
    for (i = 0; i < num_of_reqs; i++) {
        header_ptr = (workload_header *)&packet_array[i][pad_size];
        header_ptr->mode = workload_array[i].mode;
        header_ptr->offset = workload_array[i].offset;
        header_ptr->size = workload_array[i].size;
    }

    *size_array_ptr = size_array;
    *packet_array_ptr = packet_array;
    *interarrival_array_ptr = interarrival_array;

    return num_of_reqs;
}

int deliverRequestRDMA(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       int pad_size) {
    struct ib_inf *node_inf;
    node_inf = ib_setup(1, MACHINE_ID);
    struct ibv_mr *tmp_mr;
    struct ib_mr_attr mr_attr;
    void *check_space = malloc(MAX_ACCESS_OFFSET);
    char mem_mr_name[RDMA_MAX_QP_NAME];
    sprintf(mem_mr_name, "test_mr_key");
    tmp_mr = ibv_reg_mr(node_inf->pd, check_space, MAX_ACCESS_OFFSET,
                        IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_WRITE |
                            IBV_ACCESS_REMOTE_READ);
    mr_attr.addr = (uint64_t)tmp_mr->addr;
    mr_attr.rkey = tmp_mr->rkey;

    if (MACHINE_ID == 1) {
        memcached_publish(mem_mr_name, &mr_attr, sizeof(struct ib_mr_attr));
        printf("publish %s %llu %llu\n", mem_mr_name,
               (unsigned long long)mr_attr.addr,
               (unsigned long long)mr_attr.rkey);
        /*while(1)
        {
            printf("%s\n", check_space);
            sleep(1);
        }*/
        while (1)
            ;
    } else {
        stick_this_thread_to_core(2);
        struct ib_mr_attr *get_mr;
        int ret_len;
        do {
            ret_len = memcached_get_published(mem_mr_name, (void **)&get_mr);
        } while (ret_len <= 0);

        int each_request;

        struct timespec start, end;
        uint64_t page_num;
        double *time_diff, average_sum, per_page_sum;

        /* Send packet */
        time_diff = malloc(sizeof(double) * request_num);
        for (each_request = 0; each_request < request_num; each_request++) {
            // copy header into send_addr
            // issue request
            workload_header *hptr =
                (void *)packet_array[each_request] + pad_size;
            /*printf("%d:\t %lld %lld %lld %c\n", each_request,
                   (long long int)interarrival_array[each_request],
                   (long long int)hptr->offset, (long long int)hptr->size,
                   hptr->mode);*/
            clock_gettime(CLOCK_MONOTONIC, &start);
            // if it's a read request
            if (hptr->mode == 'r') {
                userspace_one_read(node_inf->conn_qp[0], tmp_mr, hptr->size,
                                   get_mr, hptr->offset);
                userspace_one_poll(node_inf->conn_cq[0], 1);
            } else if (hptr->mode == 'w') {  // if it's a write request
                userspace_one_write(node_inf->conn_qp[0], tmp_mr, hptr->size,
                                    get_mr, hptr->offset);
                userspace_one_poll(node_inf->conn_cq[0], 1);
            }

            // this part should be done once LEGOFPGA has interface
            clock_gettime(CLOCK_MONOTONIC, &end);
            time_diff[each_request] = diff_ns(&start, &end);

            // I found out that using usleep will slow the overall latency - I
            // am not sure why
            // since this is a latency test, I manually disable interarrival
            // sleep
            // usleep(interarrival_array[each_request]);
        }

        average_sum = 0;
        per_page_sum = 0;
        for (each_request = 0; each_request < request_num; each_request++) {
            page_num = (size_array[each_request] - pad_size -
                        sizeof(workload_header)) /
                       DEFAULT_PAGE_SIZE;
            average_sum += time_diff[each_request];
            per_page_sum += time_diff[each_request] / page_num;
        }

        printf("average latency: %f (ns)\n", average_sum / request_num);
        printf("per_page(per_request per_page) latency: %f (ns)\n",
               per_page_sum / request_num);
    }
    return 0;
}

int deliverRequestPCIe(int request_num, size_t *size_array,
                       uint8_t **packet_array, uint32_t *interarrival_array,
                       int pad_size, void *pcie_send_addr,
                       void *pcie_recv_addr) {
    int each_request;

    char reply[DEFAULT_REPLY_SIZE];
    void *base = pcie_send_addr;
    struct timespec start, end;
    uint64_t page_num;
    double *time_diff, average_sum, per_page_sum;
    int *check_counter_addr = (int *)pcie_recv_addr;

    memset(reply, 0, DEFAULT_REPLY_SIZE);

    /* Construct the Ethernet header */
    for (each_request = 0; each_request < request_num; each_request++) {

        // set LEGOFPGA header here

        /* dump network frame */
        if (debug_mode) {
            printf("===== %d =====\n", each_request);
            // myDump(NULL, packet_array[each_request],
            // size_array[each_request]);
            myDump(NULL, packet_array[each_request],
                   pad_size + sizeof(workload_header));
        }
    }

    /* Send packet */
    time_diff = malloc(sizeof(double) * request_num);
    for (each_request = 0; each_request < request_num; each_request++) {
        // copy header into send_addr
        clock_gettime(CLOCK_MONOTONIC, &start);
        memcpy(base, packet_array[each_request],
               pad_size + sizeof(workload_header));
        if (debug_mode) {
            workload_header *hptr = base + pad_size;
            printf("%d:\t %lld %lld %lld %c\n", each_request,
                   (long long int)interarrival_array[each_request],
                   (long long int)hptr->offset, (long long int)hptr->size,
                   hptr->mode);
            *check_counter_addr = each_request + 1;
        }
        // issue request
        //[TODO]
        // this part should be done once LEGOFPGA has interface
        while (*check_counter_addr != each_request + 1)  // wait for the reply
        {
            ;
        }
        clock_gettime(CLOCK_MONOTONIC, &end);
        time_diff[each_request] = diff_ns(&start, &end);

        // I manually disable interarrival time here since the interarrival time
        // is too long to do microbenchmark
        // and this is a blocking call. Therefore, interarrival time doesn't
        // make any difference
        usleep(interarrival_array[each_request]);
    }

    average_sum = 0;
    per_page_sum = 0;
    for (each_request = 0; each_request < request_num; each_request++) {
        page_num =
            (size_array[each_request] - pad_size - sizeof(workload_header)) /
            DEFAULT_PAGE_SIZE;
        average_sum += time_diff[each_request];
        per_page_sum += time_diff[each_request] / page_num;
    }

    printf("average latency: %f (ns)\n", average_sum / request_num);
    printf("per_page(per_request per_page) latency: %f (ns)\n",
           per_page_sum / request_num);
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
                   uint32_t *interarrival_array, int pad_size, int interface) {
    int ret = -1;
    void *pcie_recv_addr, *pcie_send_addr;
    uint64_t max_size;
    int per_request;
    switch (interface) {
        case INTERFACE_PCIE:
            max_size = 0;
            for (per_request = 0; per_request < request_num; per_request++) {
                if (max_size < size_array[per_request])
                    max_size = size_array[per_request];
            }
            pcie_recv_addr = getPCIeRecvAddr();
            pcie_send_addr = getPCIeSendAddr(max_size);
            ret = deliverRequestPCIe(request_num, size_array, packet_array,
                                     interarrival_array, pad_size,
                                     pcie_send_addr, pcie_recv_addr);
            break;
        case INTERFACE_RDMA:
            ret = deliverRequestRDMA(request_num, size_array, packet_array,
                                     interarrival_array, pad_size);
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
    uint32_t *interarrival_array;

    int pad_size = -1;
    int opt;
    int option_index = 0;
    char *deliver_mode = NULL;
    // parse parameters
    static struct option long_options[] = {
        {"workload_file_name", required_argument, 0, 'w'},
        {"max request", required_argument, 0, 'n'},
        {"ignore request", required_argument, 0, 'i'},
        {"machine id", required_argument, 0, 'I'},
        {"mode (pcie/eth)", required_argument, 0, 'm'},
        {"pad_size", required_argument, 0, 'p'},
        {"mode", required_argument, 0, 'p'},
        {"debug", required_argument, 0, 'v'},
        {"help", no_argument, 0, 'h'},
        {NULL, 0, 0, 0}};

    while ((opt = getopt_long(argc, argv, "vhw:p:m:n:i:I:", long_options,
                              &option_index)) >= 0) {
        switch (opt) {
            case 0:
                break;
            case 'w':
                workload_file_name = optarg;
                break;
            case 'n':
                MAX_REQUEST = atoi(optarg);
                break;
            case 'i':
                IGNORE_REQUEST = atoi(optarg);
                break;
            case 'I':
                MACHINE_ID = atoi(optarg);
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
    request_num = getWorkload(&size_array, &packet_array, &interarrival_array,
                              workload_file_name, pad_size);
    printf("request num:%d max_offset:%llu\n", request_num,
           (unsigned long long)MAX_ACCESS_OFFSET);

    // deliver request
    if (strcmp(deliver_mode, "eth") == 0)
        deliverRequest(request_num, size_array, packet_array,
                       interarrival_array, pad_size, INTERFACE_ETHERNET);
    else if (strcmp(deliver_mode, "pcie") == 0)
        deliverRequest(request_num, size_array, packet_array,
                       interarrival_array, pad_size, INTERFACE_PCIE);
    else if (strcmp(deliver_mode, "rdma") == 0)
        deliverRequest(request_num, size_array, packet_array,
                       interarrival_array, pad_size, INTERFACE_RDMA);
    else {
        printf("error mode %s\n", deliver_mode);
        printHelp(deliver_mode);
    }

    return 0;
}
