# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) Siemens AG, 2020-2021
#
# Authors:
#   Jan Kiszka <jan.kiszka@siemens.com>

CROSS_COMPILE = arm-linux-gnueabihf-
CC = gcc

RTI_MODULE = 1

CFLAGS = -mcpu=cortex-r5 -DRTI_MODULE=$(RTI_MODULE)
LDFLAGS = -nostdlib -N -Wl,-strip-all -static

k3-rti-wdt.fw: lscript.lds firmware.o
	$(CROSS_COMPILE)$(CC) -o $@ -T $^ $(LDFLAGS)

firmware.o: firmware.S
	$(CROSS_COMPILE)$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -rf *.o *.fw
