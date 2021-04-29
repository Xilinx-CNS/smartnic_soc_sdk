#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
#

ifeq ($(SNIC_ROOTFS_THERMAL_LOAD),y)
$(rootfs_TMP)/sbin/thermalload: $(PACKAGEDIR)/thermalload/thermal_server.c $(PACKAGEDIR)/thermalload/thermal.h
	$(CC) -o $(rootfs_TMP)/sbin/thermalload $(PACKAGEDIR)/thermalload/thermal_server.c -lpthread -I.

$(rootfs_CUSTOM):$(rootfs_TMP)/sbin/thermalload
endif
