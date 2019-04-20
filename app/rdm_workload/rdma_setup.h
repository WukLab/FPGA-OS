#ifndef RDMA_SET_HEADER
#define RDMA_SET_HEADER

#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <infiniband/verbs.h>
#include <assert.h>
#include <string.h>
#include <libmemcached/memcached.h>
#include <pthread.h>
#include <sched.h>
#include <unistd.h>

#define MEMCACHED_IP "128.46.115.103"

#define CPE(val, msg, err_code)                    \
    if (val) {                                     \
        fprintf(stderr, msg);                      \
        fprintf(stderr, " Error %d \n", err_code); \
        exit(err_code);                            \
    }

#define RDMA_MAX_QP_NAME 120
#define RDMA_CQ_DEPTH 256
#define RDMA_QP_MAX_SGE 2
#define RDMA_MAX_INLINE 32
#define RDMA_RC_SL 0
#define RDMA_RESERVED_NAME_PREFIX "__RMDA_RESERVED_NAME_PREFIX"
#define RDMA_DEVICE_ID 1
#define RDMA_MACHINES 2
#define RDMA_PSN 3185

void die_printf(const char *fmt, ...);
int fast_rand(int input);
struct ib_inf {

    int device_id;
    /* Info about the device/port to use for this control block */
    struct ibv_context *ctx;
    int port_index;   /* User-supplied. 0-based across all devices */
    int dev_port_id;  /* 1-based within dev @device_id. Resolved by libhrd */
    int numa_node_id; /* NUMA node id */

    struct ibv_pd *pd; /* A protection domain for this control block */

    int role;  // SERVER, CLIENT and MEMORY

    int num_servers;
    int num_clients;
    int num_memorys;

    /* Connected QPs */
    int num_rc_qp_to_server;
    int num_rc_qp_to_client;
    int num_rc_qp_to_memory;
    int num_local_rcqps;
    int num_global_rcqps;
    struct ibv_qp **conn_qp;
    struct ibv_cq **conn_cq, *server_recv_cq;
    struct ib_qp_attr **all_rcqps;
};

struct ib_qp_attr {
    char name[RDMA_MAX_QP_NAME];

    /* Info about the RDMA buffer associated with this QP */
    uint64_t buf_addr;
    uint32_t buf_size;
    uint32_t rkey;
    int sl;

    int lid;
    int qpn;

    union ibv_gid remote_gid;
};

struct ib_mr_attr {
    uint64_t addr;
    uint32_t rkey;
};

uint16_t ib_get_local_lid(struct ibv_context *ctx, int dev_port_id);
int ib_connect_qp(struct ib_inf *inf, int qp_index, struct ib_qp_attr *dest);
struct ibv_device *ib_get_device(struct ib_inf *inf, int port);
void ib_create_rcqps(struct ib_inf *inf);
struct ib_inf *ib_setup(int port, int machine_id);
struct ib_qp_attr *memcached_get_published_qp(const char *qp_name);
int memcached_get_published(const char *key, void **value);
void memcached_publish_rcqp(struct ib_inf *inf, int num, const char *qp_name);
void memcached_publish(const char *key, void *value, int len);
memcached_st *memcached_create_memc(void);
int userspace_one_poll(struct ibv_cq *cq, int tar_mem);
inline int hrd_poll_cq(struct ibv_cq *cq, int num_comps, struct ibv_wc *wc);
int userspace_one_read(struct ibv_qp *qp, struct ibv_mr *local_mr,
                       int request_size, struct ib_mr_attr *remote_mr,
                       unsigned long long offset, int signal_flag);
int userspace_one_write(struct ibv_qp *qp, struct ibv_mr *local_mr,
                        int request_size, struct ib_mr_attr *remote_mr,
                        unsigned long long offset, int signal_flag);
int stick_this_thread_to_core(int core_id);
#endif
