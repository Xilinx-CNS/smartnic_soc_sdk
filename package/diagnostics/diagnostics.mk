#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifneq ($(CROSSNAME),)
CC=$(CROSSNAME)gcc
endif



$(rootfs_TMP)/bin/diagnostics: $(PACKAGEDIR)/diagnostics/diag.c
	$(CC) -o $(rootfs_TMP)/bin/diagnostics $(PACKAGEDIR)/diagnostics/diag.c -I. -lpthread

diagnostics_stress_DEB_FILENAME=stressapptest_1.0.6-2_arm64.deb
diagnostics_stress_DEBFILE=$(PACKAGEDIR)/diagnostics/$(diagnostics_stress_DEB_FILENAME)

ifeq ($(SNIC_ROOTFS_DIAGNOSTIC),y)
$(rootfs_CUSTOM):$(rootfs_TMP)/bin/diagnostics
endif
