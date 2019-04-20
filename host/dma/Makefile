CC=gcc

all: dma_utils.o rdm.o
	$(CC) -pthread -lrt -o rdm.out $^ -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE -I../../include

%.o: %.c
	$(CC) -pthread -c -std=c99 -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE -I../../include

clean:
	rm -rf *.o *.bin rdm.out
