#include "rdma_setup.h"

#define QP_NUM 4

int fast_rand(int input) { return input; }

void die_printf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    exit(1);
}
__thread memcached_st *memc = NULL;

memcached_st *memcached_create_memc(void) {
    memcached_server_st *servers = NULL;
    memcached_st *memc = memcached_create(NULL);
    memcached_return rc;

    memc = memcached_create(NULL);
    char *registry_ip = MEMCACHED_IP;

    /* We run the memcached server on the default memcached port */
    servers = memcached_server_list_append(servers, registry_ip,
                                           MEMCACHED_DEFAULT_PORT, &rc);
    rc = memcached_server_push(memc, servers);
    CPE(rc != MEMCACHED_SUCCESS, "Couldn't add memcached server.\n", -1);

    return memc;
}

void memcached_publish(const char *key, void *value, int len) {
    assert(key != NULL && value != NULL && len > 0);
    memcached_return rc;

    if (memc == NULL) {
        memc = memcached_create_memc();
    }

    rc = memcached_set(memc, key, strlen(key), (const char *)value, len,
                       (time_t)0, (uint32_t)0);
    if (rc != MEMCACHED_SUCCESS) {
        char *registry_ip = MEMCACHED_IP;
        fprintf(stderr,
                "\tHRD: Failed to publish key %s. Error %s. "
                "Reg IP = %s\n",
                key, memcached_strerror(memc, rc), registry_ip);
        exit(-1);
    }
}

void memcached_publish_rcqp(struct ib_inf *inf, int num, const char *qp_name) {
    assert(inf != NULL);
    assert(num >= 0 && num < inf->num_local_rcqps);

    assert(qp_name != NULL && strlen(qp_name) < RDMA_MAX_QP_NAME - 1);
    assert(strstr(qp_name, RDMA_RESERVED_NAME_PREFIX) == NULL);

    int len = strlen(qp_name);
    int i;
    for (i = 0; i < len; i++) {
        if (qp_name[i] == ' ') {
            fprintf(stderr, "Space not allowed in QP name\n");
            exit(-1);
        }
    }
    struct ib_qp_attr qp_attr;
    memcpy(qp_attr.name, qp_name, len);
    qp_attr.name[len] = 0; /* Add the null terminator */
    // qp_attr.buf_addr = (uint64_t)inf->rcqp_buf[num];
    // qp_attr.rkey = (uint32_t)inf->rcqp_buf_mr[num]->rkey;
    qp_attr.lid =
        ib_get_local_lid(inf->conn_qp[num]->context, inf->dev_port_id);
    qp_attr.qpn = inf->conn_qp[num]->qp_num;
    qp_attr.sl = RDMA_RC_SL;

    memcached_publish(qp_attr.name, &qp_attr, sizeof(struct ib_qp_attr));
}

int memcached_get_published(const char *key, void **value) {
    assert(key != NULL);
    if (memc == NULL) {
        memc = memcached_create_memc();
    }
    memcached_return rc;
    size_t value_length;
    uint32_t flags;

    *value = memcached_get(memc, key, strlen(key), &value_length, &flags, &rc);

    if (rc == MEMCACHED_SUCCESS) {
        return (int)value_length;
    } else if (rc == MEMCACHED_NOTFOUND) {
        assert(*value == NULL);
        return -1;
    } else {
        char *registry_ip = MEMCACHED_IP;
        fprintf(stderr,
                "Error finding value for key \"%s\": %s. "
                "Reg IP = %s\n",
                key, memcached_strerror(memc, rc), registry_ip);
        exit(-1);
    }
    /* Never reached */
    assert(false);
}

struct ib_qp_attr *memcached_get_published_qp(const char *qp_name) {
    struct ib_qp_attr *ret;
    assert(qp_name != NULL && strlen(qp_name) < RDMA_MAX_QP_NAME - 1);
    assert(strstr(qp_name, RDMA_RESERVED_NAME_PREFIX) == NULL);

    int len = strlen(qp_name);
    int i;
    int ret_len;
    for (i = 0; i < len; i++) {
        if (qp_name[i] == ' ') {
            fprintf(stderr, "Space not allowed in QP name\n");
            exit(-1);
        }
    }
    do {
        ret_len = memcached_get_published(qp_name, (void **)&ret);
    } while (ret_len <= 0);
    /*
     * The registry lookup returns only if we get a unique QP for @qp_name, or
     * if the memcached lookup succeeds but we don't have an entry for @qp_name.
     */
    assert(ret_len == sizeof(struct ib_qp_attr) || ret_len == -1);

    return ret;
}

uint16_t ib_get_local_lid(struct ibv_context *ctx, int dev_port_id) {
    assert(ctx != NULL && dev_port_id >= 1);

    struct ibv_port_attr attr;
    if (ibv_query_port(ctx, dev_port_id, &attr)) {
        die_printf(
            "HRD: ibv_query_port on port %d of device %s failed! Exiting.\n",
            dev_port_id, ibv_get_device_name(ctx->device));
        assert(0);
    }

    return attr.lid;
}

struct ibv_device *ib_get_device(struct ib_inf *inf, int port) {
    struct ibv_device **dev_list;
    struct ibv_context *ctx;
    struct ibv_device_attr device_attr;
    struct ibv_port_attr port_attr;
    int i;
    int num_devices;
    dev_list = ibv_get_device_list(&num_devices);
    if (num_devices == 0)  // assuming we only have one device now, need to
                           // modify this part later
        die_printf("%s: num_devices==0\n", __func__);
    if (num_devices <= inf->device_id)
        die_printf("%s: device_id:%d overflow available num_devices:%d\n",
                   __func__, inf->device_id, num_devices);
    i = inf->device_id;
    {
        ctx = ibv_open_device(dev_list[i]);
        if (ibv_query_device(ctx, &device_attr))
            die_printf("%s: failed to query device %d\n", __func__, i);

        printf("running on %s\n", ibv_get_device_name(dev_list[i]));
        if (device_attr.phys_port_cnt < port)
            die_printf("%s: port not enough %d:%d\n", __func__, port,
                       device_attr.phys_port_cnt);
        if (ibv_query_port(ctx, port, &port_attr))
            die_printf("%s: can't query port %d\n", __func__, port);
        inf->device_id = i;
        inf->dev_port_id = port;
        return dev_list[i];
    }
    return NULL;
}

int ib_connect_qp(struct ib_inf *inf, int qp_index, struct ib_qp_attr *dest)
    /*
       1.change conn_qp to RTS
       */
{
    struct ibv_qp_attr attr = {.qp_state = IBV_QPS_RTR,
                               .path_mtu = IBV_MTU_4096,
                               .dest_qp_num = dest->qpn,
                               .rq_psn = RDMA_PSN,
                               .max_dest_rd_atomic = 10,
                               .min_rnr_timer = 12,
                               .ah_attr = {.is_global = 0,
                                           .dlid = dest->lid,
                                           .sl = dest->sl,
                                           .src_path_bits = 0,
                                           .port_num = inf->port_index}};
    if (ibv_modify_qp(inf->conn_qp[qp_index], &attr,
                      IBV_QP_STATE | IBV_QP_AV | IBV_QP_PATH_MTU |
                          IBV_QP_DEST_QPN | IBV_QP_RQ_PSN |
                          IBV_QP_MAX_DEST_RD_ATOMIC | IBV_QP_MIN_RNR_TIMER)) {
        fprintf(stderr, "[%s] Failed to modify QP to RTR\n", __func__);
        return 1;
    }
    attr.qp_state = IBV_QPS_RTS;
    attr.timeout = 14;
    attr.retry_cnt = 7;
    attr.rnr_retry = 7;
    attr.sq_psn = RDMA_PSN;
    attr.max_rd_atomic = 16;
    attr.max_dest_rd_atomic = 16;
    if (ibv_modify_qp(inf->conn_qp[qp_index], &attr,
                      IBV_QP_STATE | IBV_QP_TIMEOUT | IBV_QP_RETRY_CNT |
                          IBV_QP_RNR_RETRY | IBV_QP_SQ_PSN |
                          IBV_QP_MAX_QP_RD_ATOMIC)) {
        fprintf(stderr, "[%s] Failed to modify QP to RTS\n", __func__);
        return 2;
    }
    return 0;
}

void ib_create_rcqps(struct ib_inf *inf) {
    int i;
    assert(inf->conn_qp != NULL && inf->conn_cq != NULL && inf->pd != NULL &&
           inf->ctx != NULL);
    assert(inf->num_local_rcqps >= 1 && inf->dev_port_id >= 1);
    for (i = 0; i < inf->num_local_rcqps; i++) {
        inf->conn_cq[i] = ibv_create_cq(inf->ctx, RDMA_CQ_DEPTH, NULL, NULL, 0);
        assert(inf->conn_cq[i] != NULL);
        struct ibv_qp_init_attr create_attr;
        memset(&create_attr, 0, sizeof(struct ibv_qp_init_attr));
        create_attr.send_cq = inf->conn_cq[i];
        create_attr.recv_cq = inf->conn_cq[i];
        create_attr.qp_type = IBV_QPT_RC;

        create_attr.cap.max_send_wr = RDMA_CQ_DEPTH;
        create_attr.cap.max_recv_wr = RDMA_CQ_DEPTH;
        create_attr.cap.max_send_sge = RDMA_QP_MAX_SGE;
        create_attr.cap.max_recv_sge = RDMA_QP_MAX_SGE;
        create_attr.cap.max_inline_data = RDMA_MAX_INLINE;
        create_attr.sq_sig_all = 0;

        inf->conn_qp[i] = ibv_create_qp(inf->pd, &create_attr);
        assert(inf->conn_qp[i] != NULL);

        struct ibv_qp_attr init_attr;
        memset(&init_attr, 0, sizeof(struct ibv_qp_attr));
        init_attr.qp_state = IBV_QPS_INIT;
        init_attr.pkey_index = 0;
        init_attr.port_num = inf->dev_port_id;
        init_attr.qp_access_flags = IBV_ACCESS_REMOTE_WRITE |
                                    IBV_ACCESS_REMOTE_READ |
                                    IBV_ACCESS_REMOTE_ATOMIC;
        if (ibv_modify_qp(inf->conn_qp[i], &init_attr,
                          IBV_QP_STATE | IBV_QP_PKEY_INDEX | IBV_QP_PORT |
                              IBV_QP_ACCESS_FLAGS)) {
            fprintf(stderr, "Failed to modify conn QP to INIT\n");
            exit(-1);
        }
    }
}

struct ib_inf *ib_setup(int port, int machine_id) {
    struct ib_inf *inf = malloc(sizeof(struct ib_inf));
    struct ibv_device *ib_dev;
    int cumulative_id;
    int i, j;
    int total_machines = RDMA_MACHINES;
    int total_qp_count = 0;

    inf->device_id = RDMA_DEVICE_ID;

    /* Fill in the control block */
    inf->port_index = port;
    inf->num_rc_qp_to_server = QP_NUM;
    inf->num_rc_qp_to_client = QP_NUM;

    inf->num_local_rcqps = QP_NUM;
    inf->num_global_rcqps = QP_NUM * total_machines;

    /* Get the device to use. This fills in cb->device_id and cb->dev_port_id */
    ib_dev = ib_get_device(inf, port);
    CPE(!ib_dev, "IB device not found", 0);

    /* Use a single device context and PD for all QPs */
    inf->ctx = ibv_open_device(ib_dev);
    CPE(!inf->ctx, "Couldn't get context", 0);

    inf->pd = ibv_alloc_pd(inf->ctx);
    CPE(!inf->pd, "Couldn't allocate PD", 0);

    /* Create an array in cb for holding work completions */
    inf->all_rcqps = (struct ib_qp_attr **)malloc(inf->num_global_rcqps *
                                                  sizeof(struct ib_qp_attr *));

    /*
     * Create connected QPs and transition them to RTS.
     * Create and register connected QP RDMA buffer.
     */
    if (inf->num_local_rcqps >= 1) {
        inf->conn_qp = (struct ibv_qp **)malloc(inf->num_local_rcqps *
                                                sizeof(struct ibv_qp *));
        inf->conn_cq = (struct ibv_cq **)malloc(inf->num_local_rcqps *
                                                sizeof(struct ibv_cq *));
        assert(inf->conn_qp != NULL && inf->conn_cq != NULL);
        ib_create_rcqps(inf);
    }

    for (i = 0; i < inf->num_local_rcqps; i++) {
        char srv_name[RDMA_MAX_QP_NAME];
        sprintf(srv_name, "machine-rc-%d-%d", machine_id, i);
        memcached_publish_rcqp(inf, i, srv_name);
        printf("publish %s\n", srv_name);
    }
    // get all published rc qps
    for (cumulative_id = 0; cumulative_id < total_machines; cumulative_id++) {
        for (i = 0; i < inf->num_local_rcqps; i++) {
            char srv_name[RDMA_MAX_QP_NAME];
            sprintf(srv_name, "machine-rc-%d-%d", cumulative_id, i);
            inf->all_rcqps[total_qp_count] =
                memcached_get_published_qp(srv_name);
            printf("get %s at %d\n", srv_name, total_qp_count);
            total_qp_count++;
        }
        printf("get machine %d/%d\n", cumulative_id, total_machines);
    }

    // connected all rc queue pairs
    total_qp_count = 0;

    for (i = 0; i < total_machines; i++) {
        for (j = 0; j < QP_NUM; j++) {
            if (i == machine_id) {
                // total_qp_count++;
                continue;
            }
            int target_qp_num = i * QP_NUM + j;
            printf("target %d\n", target_qp_num);
            printf("connect %d(%d): lid:%d qpn:%d sl:%d rkey:%lu\n",
                   total_qp_count, target_qp_num,
                   inf->all_rcqps[target_qp_num]->lid,
                   inf->all_rcqps[target_qp_num]->qpn,
                   inf->all_rcqps[target_qp_num]->sl,
                   (unsigned long)inf->all_rcqps[target_qp_num]->rkey);
            ib_connect_qp(inf, total_qp_count, inf->all_rcqps[target_qp_num]);
            total_qp_count++;
        }
    }

    /*
    for(i=0;i<total_machines;i++)
    {
        if(i==machine_id)
        {
            //total_qp_count++;
            continue;
        }
        int target_qp_num = i;
        printf("target %d\n", target_qp_num);
        printf(
                "connect %d(%d): lid:%d qpn:%d sl:%d rkey:%lu\n",
                total_qp_count,
                target_qp_num,
                inf->all_rcqps[target_qp_num]->lid,
                inf->all_rcqps[target_qp_num]->qpn,
                inf->all_rcqps[target_qp_num]->sl,
                (unsigned long)inf->all_rcqps[target_qp_num]->rkey
                );
        ib_connect_qp(
                inf,
                total_qp_count,
                inf->all_rcqps[target_qp_num]
                );
        total_qp_count++;
    }*/
    return inf;
}

int userspace_one_write(struct ibv_qp *qp, struct ibv_mr *local_mr,
                        int request_size, struct ib_mr_attr *remote_mr,
                        unsigned long long offset, int signal_flag) {
    struct ibv_sge test_sge;
    struct ibv_send_wr wr, *bad_send_wr;
    int ret;
    test_sge.length = request_size;
    test_sge.addr = (uintptr_t)local_mr->addr;
    test_sge.lkey = local_mr->lkey;
    wr.opcode = IBV_WR_RDMA_WRITE;
    wr.num_sge = 1;
    wr.next = NULL;
    wr.sg_list = &test_sge;
    wr.send_flags = signal_flag ? IBV_SEND_SIGNALED : 0;
    wr.wr_id = 0;
    wr.wr.rdma.remote_addr = remote_mr->addr + offset;
    wr.wr.rdma.rkey = remote_mr->rkey;
    ret = ibv_post_send(qp, &wr, &bad_send_wr);
    CPE(ret, "ibv_post_send error", ret);
    return 0;
}

int userspace_one_read(struct ibv_qp *qp, struct ibv_mr *local_mr,
                       int request_size, struct ib_mr_attr *remote_mr,
                       unsigned long long offset, int signal_flag) {
    struct ibv_sge test_sge;
    struct ibv_send_wr wr, *bad_send_wr;
    int ret;
    test_sge.length = request_size;
    test_sge.addr = (uintptr_t)local_mr->addr;
    test_sge.lkey = local_mr->lkey;
    wr.opcode = IBV_WR_RDMA_READ;
    wr.num_sge = 1;
    wr.next = NULL;
    wr.sg_list = &test_sge;
    wr.send_flags = signal_flag ? IBV_SEND_SIGNALED : 0;
    wr.wr.rdma.remote_addr = remote_mr->addr + offset;
    wr.wr.rdma.rkey = remote_mr->rkey;
    ret = ibv_post_send(qp, &wr, &bad_send_wr);
    CPE(ret, "ibv_post_send error", ret);
    return 0;
}

int userspace_one_poll(struct ibv_cq *cq, int tar_mem) {
    struct ibv_wc wc[RDMA_CQ_DEPTH];
    return hrd_poll_cq(cq, tar_mem, wc);
}

inline int hrd_poll_cq(struct ibv_cq *cq, int num_comps, struct ibv_wc *wc) {
    int comps = 0;

    while (comps < num_comps) {
        int new_comps = ibv_poll_cq(cq, num_comps - comps, &wc[comps]);
        if (new_comps != 0) {
            // Ideally, we should check from comps -> new_comps - 1
            if (wc[comps].status != 0) {
                fprintf(stderr, "Bad wc status %d\n", wc[comps].status);
                exit(0);
                return 1;
                // exit(0);
            }
            comps += new_comps;
        }
    }
    return 0;
}

int stick_this_thread_to_core(int core_id) {
    int num_cores = sysconf(_SC_NPROCESSORS_ONLN);
    if (core_id < 0 || core_id >= num_cores) return EINVAL;

    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(core_id, &cpuset);

    pthread_t current_thread = pthread_self();
    return pthread_setaffinity_np(current_thread, sizeof(cpu_set_t), &cpuset);
}
