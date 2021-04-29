#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

$(rootfs_TMP)/sbin/suc_comms: $(PACKAGEDIR)/suc_comms/suc_comms.c
	$(CC) -o $(rootfs_TMP)/sbin/suc_comms $(PACKAGEDIR)/suc_comms/suc_comms.c -I.
	cp $(rootfs_CONFDIR)/suc_comms.service $(rootfs_TMP)/etc/systemd/system
ifeq ($(SNIC_ROOTFS_START_SuC_COMMS),y)
	ln -s /etc/systemd/system/suc_comms.service $(rootfs_TMP)/etc/systemd/system/multi-user.target.wants/suc_comms.service
endif

$(rootfs_CUSTOM): $(rootfs_TMP)/sbin/suc_comms
