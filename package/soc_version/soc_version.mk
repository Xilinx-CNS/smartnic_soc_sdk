#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif

$(rootfs_TMP)/sbin/soc_version: $(PACKAGEDIR)/soc_version/soc_version.c
	$(CC) -o $(rootfs_TMP)/sbin/soc_version $(PACKAGEDIR)/soc_version/soc_version.c -I. -DSDKVERSION=$(SDK_VERSION)

$(rootfs_CUSTOM):$(rootfs_TMP)/sbin/soc_version

