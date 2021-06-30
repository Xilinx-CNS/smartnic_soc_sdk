#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
$(rootfs_TMP)/sbin/power_throttle: $(PACKAGEDIR)/power_throttle/power_throttle.c
	$(CC) -o $(rootfs_TMP)/sbin/power_throttle $(PACKAGEDIR)/power_throttle/power_throttle.c -I.
	install -m 644 $(rootfs_CONFDIR)/power_throttle.service $(rootfs_TMP)/etc/systemd/system
ifeq ($(SNIC_ROOTFS_START_POWER_THROTTLE),y)
	ln -s /etc/systemd/system/power_throttle.service $(rootfs_TMP)/etc/systemd/system/multi-user.target.wants/power_throttle.service
endif

$(rootfs_CUSTOM):$(rootfs_TMP)/sbin/power_throttle

