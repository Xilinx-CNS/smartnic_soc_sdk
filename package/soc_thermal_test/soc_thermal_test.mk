#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifeq ($(SNIC_ROOTFS_SOC_THERMAL_TEST),y)
soc_thermal_test_TGZ=$(PACKAGEDIR)/soc_thermal_test/soc_thermal_test.tgz
soc_thermal_test_CHECKOUT=main
soc_thermal_test_VER=$(soc_thermal_test_CHECKOUT)

soc_thermal_test_BUILD=soc_thermal_test_$(soc_thermal_test_VER)
soc_thermal_test_BUILDDIR=$(BUILDDIR)/soc_thermal_test/soc_thermal_test-$(soc_thermal_test_VER)
soc_thermal_test_PACKAGEDIR=$(PACKAGEDIR)/soc_thermal_test
soc_thermal_test_CONFDIR=$(soc_thermal_test_PACKAGEDIR)
soc_thermal_test_MAKESCRIPT=make

soc_thermal_test_IMAGES=$(soc_thermal_test_BUILDDIR)/soc_load $(soc_thermal_test_BUILDDIR)/soc_sensors

$(eval $(call package-builder,soc_thermal_test))
endif

soc_thermal_test-help  :
	@echo "soc_thermal_test applications"


TARGETS_HELP+=soc_thermal_test-help

.phony: soc_thermal_test-help
