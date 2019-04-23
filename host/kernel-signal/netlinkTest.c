#include "netlinkUser.h"
int main() {
    // struct timespec *ret = send_request_and_get_timespec(156);
    struct timespec *ret;
    int sock_fd = send_request(3377);
    printf("wait 1 seconds");
    sleep(1);
    ret = receive(sock_fd);
    printf("Received message payload: %lld %lld\n", ret->tv_sec, ret->tv_nsec);
}
