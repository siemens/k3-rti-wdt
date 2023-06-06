# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) Siemens AG, 2020-2023
#
# Authors:
#   Jan Kiszka <jan.kiszka@siemens.com>
#   Li Huaqian <huaqian.li@siemens.com>

CROSS_COMPILE = arm-linux-gnueabihf-
CC = gcc

RTI_MODULE = 1
PON_REASON_BASE_ADDR = 0xA2200000

CFLAGS = -mcpu=cortex-r5 -DRTI_MODULE=$(RTI_MODULE)
ifneq ($(PON_REASON_BASE_ADDR), -1)
CFLAGS += -DPON_REASON_BASE_ADDR=$(PON_REASON_BASE_ADDR)
endif
LDFLAGS = -nostdlib -N -Wl,-strip-all -Wl,--build-id -static -Wl,--nmagic

k3-rti-wdt.fw: lscript.lds firmware.o
	$(CROSS_COMPILE)$(CC) -o $@ -T $^ $(LDFLAGS)

firmware.o: firmware.S
	$(CROSS_COMPILE)$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -rf *.o *.fw
