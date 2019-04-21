CFLAGS := -Wall -Wmissing-prototypes -Wstrict-prototypes\
      -fomit-frame-pointer -freg-struct-return -ggdb \
      -I ../../../../include -I ../../../../include/uapi/
      #mbed_lib/libmbedcrypto.so mbed_lib/libmbedtls.so mbed_lib/libmbedx509.so
      #-Lmbed_lib -llibmbedx509.so -libmbedtlx -libmbedcrypto\

#CFLAGS := -fomit-frame-pointer -freg-struct-return -O2
LIBS := -libverbs -lpthread -lrdmacm -libverbs -lmemcached -lm
SRCS := $(wildcard packetStream*.c)
OBJS := $(SRCS:.c=.o)
#DEPS :=
all: $(OBJS)

clean:
	rm -f *.o

%.o: %.c 
	gcc -o $@ $(CFLAGS) $(LIBS) $<
