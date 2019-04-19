
CFLAGS := -Wall -Wmissing-prototypes -Wstrict-prototypes\
	  -fomit-frame-pointer -freg-struct-return -ggdb
	  #mbed_lib/libmbedcrypto.so mbed_lib/libmbedtls.so mbed_lib/libmbedx509.so
	  #-Lmbed_lib -llibmbedx509.so -libmbedtlx -libmbedcrypto\


#CFLAGS := -fomit-frame-pointer -freg-struct-return -O2
LIBS := -libverbs -lpthread -lrdmacm -libverbs -lmemcached -lm
SRCS := $(wildcard workloadStream*.c)
OBJS := $(SRCS:.c=.o)
DEPS := rdma_setup.h
all: $(OBJS)

clean:
	rm -f *.o

%.o: %.c 
	gcc rdma_setup.c -o $@ $(CFLAGS) $(LIBS) $<
