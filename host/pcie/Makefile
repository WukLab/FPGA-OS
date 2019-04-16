CC ?= gcc

all: rdm_pcie_core

rdm_pcie_core: dma_utils.o pcie_interface.o rdm_pcie_core.o
	$(CC) -pthread -lrt -o $@ $^ -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE

%.o: %.c
	$(CC) -pthread -c -std=c99 -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE

clean:
	rm -rf *.o *.bin rdm_pcie_core

