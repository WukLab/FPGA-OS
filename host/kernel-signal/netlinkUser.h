#ifndef NETLINK_USER_HEADER
#define NETLINK_USER_HEADER
#include <sys/socket.h>
#include <linux/netlink.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#define NETLINK_USER 31

#define MAX_PAYLOAD 1024 /* maximum payload size*/
int send_request(int nr_requests);
struct timespec *receive(int sock_fd);
#endif
