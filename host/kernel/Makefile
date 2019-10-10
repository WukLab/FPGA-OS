#
# Makefile for Hotpot
# Copyright (C) 2016-2017 Wuklab, UCSD. All rights reserved.
#

obj-m := remap.o

# Targets
all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
help:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) help

