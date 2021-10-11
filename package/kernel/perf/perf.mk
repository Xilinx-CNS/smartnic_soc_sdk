#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif
ifeq ($(SNIC_PERF_DEBIAN_PACKAGE),y)
PERFILE:=$(notdir $(PERFDEB))

$(rootfs_TMP)/srv/local-apt-repository/$(PERFILE): $(PERFDEB)
	install -m 755 $(PERFDEB) $(rootfs_TMP)/srv/local-apt-repository/

$(rootfs_CUSTOM):$(rootfs_TMP)/srv/local-apt-repository/$(PERFILE)
endif
