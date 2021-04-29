#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif

diagnostics: diag.c
	$(CC) -o $(OUT)diagnostics diag.c -I. -lpthread
