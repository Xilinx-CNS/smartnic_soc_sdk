#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif
soc_version: soc_version.c
	$(CC) -o $(OUT)soc_version soc_version.c -I. -DSDKVERSION=$(SDK_VERSION)
