// Taken from
// https://stackoverflow.com/questions/15215865/netlink-sockets-in-c-using-the-3-x-linux-kernel?lq=1
#include "netlinkUser.h"
struct sockaddr_nl src_addr, dest_addr;
struct nlmsghdr *nlh = NULL;
struct iovec iov;
// int sock_fd;
struct msghdr msg;

int send_request(int nr_requests) {
    int sock_fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_USER);
    if (sock_fd < 0) return -1;

    memset(&src_addr, 0, sizeof(src_addr));
    src_addr.nl_family = AF_NETLINK;
    src_addr.nl_pid = getpid(); /* self pid */

    bind(sock_fd, (struct sockaddr *)&src_addr, sizeof(src_addr));

    memset(&dest_addr, 0, sizeof(dest_addr));
    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.nl_family = AF_NETLINK;
    dest_addr.nl_pid = 0;    /* For Linux Kernel */
    dest_addr.nl_groups = 0; /* unicast */

    nlh = (struct nlmsghdr *)malloc(NLMSG_SPACE(MAX_PAYLOAD));
    memset(nlh, 0, NLMSG_SPACE(MAX_PAYLOAD));
    nlh->nlmsg_len = NLMSG_SPACE(MAX_PAYLOAD);
    nlh->nlmsg_pid = getpid();
    nlh->nlmsg_flags = 0;

    // strcpy(NLMSG_DATA(nlh), "Hello");
    memcpy(NLMSG_DATA(nlh), &nr_requests, sizeof(int));

    iov.iov_base = (void *)nlh;
    iov.iov_len = nlh->nlmsg_len;
    msg.msg_name = (void *)&dest_addr;
    msg.msg_namelen = sizeof(dest_addr);
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    printf("Sending message to kernel\n");
    sendmsg(sock_fd, &msg, 0);
    return sock_fd;
}

struct timespec *receive(int sock_fd) {
    struct timespec *from_kernel, *ret;
    /* Read message from kernel */
    recvmsg(sock_fd, &msg, 0);
    // printf("Received message payload: %s\n", (char *)NLMSG_DATA(nlh));
    from_kernel = (struct timespec *)NLMSG_DATA(nlh);
    ret = malloc(sizeof(struct timespec));
    memcpy(ret, from_kernel, sizeof(struct timespec));
    close(sock_fd);
    return ret;
}
