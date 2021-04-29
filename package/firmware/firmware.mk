#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/firmware/firmware.deps

ifeq ($(SNIC_PACKAGE_FIRMWARE),y)

ifeq ($(SNIC_NXP),y)
include $(PACKAGEDIR)/firmware/nxp/*.mk
firmware: firmware-qoriq
firmware-clean: firmware-qoriq-clean
firmware-config: firmware-qoriq-config
firmware-dist:firmware-qoriq-dist
firmware-distclean:firmware-qoriq-distclean
firmware-help:firmware-qoriq-help
firmware-rebuild:firmware-qoriq-rebuild
endif
endif

