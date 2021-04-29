#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif

suc_comms: suc_comms.c
	$(CC) -o $(OUT)suc_comms suc_comms.c -I.
