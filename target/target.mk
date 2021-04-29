#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
# set target options
# ARCH
# SOC
# BOARD

ifeq ($(SNIC_ARCH_ARM),y)
export ARCH:=arm
ifneq ($(NATIVE_BUILD),y)
export CROSSNAME:=arm-linux-gnueabi-
endif
endif
ifeq ($(SNIC_ARCH_ARM64),y)
export ARCH:=arm64
ifneq ($(NATIVE_BUILD),y)
export CROSSNAME:=aarch64-linux-gnu-
endif
endif

ifeq ($(NATIVE_BUILD),y)
export CROSSNAME:=
endif

DEPS+=gcc-target

ifeq ($(SNIC_LEGACY),y)
-include target/extra_soc.mk
endif

ifeq ($(SNIC_SOC_LS1088A),y)
export SOC:=ls1088a
endif
ifeq ($(SNIC_SOC_LX2160A),y)
export SOC:=lx2160a
endif
ifeq ($(SNIC_SOC_LX2162A),y)
export SOC:=lx2162a
endif

ifeq ($(SNIC_LEGACY),y)
include target/extra_boards.mk
endif

ifeq ($(SNIC_LX2160ARDB),y)
export BOARD:=lx2160ardb
endif
ifeq ($(SNIC_LX2162AU26Z),y)
export BOARD:=lx2162au26z
endif

# set or override variables as a consequence

ifeq ($(SNIC_VARIANT_DEFAULT),y)
VARIANT:=
endif
ifeq ($(SNIC_VARIANT_NXP_LIGHT),y)
VARIANT:=-light
endif

ifeq ($(SNIC_NXP),y)

ifeq ($(SNIC_QORIQ_TAG_LSDK_20.04),y)
QORIQ_TAG:=LSDK-20.04
endif

ifeq ($(SNIC_QORIQ_TAG_LX2162A-BSP0.2),y)
QORIQ_TAG:=lx2162a-bsp0.2
endif

ifeq ($(SNIC_QORIQ_TAG_LX2162A-BSP0.4),y)
QORIQ_TAG:=lx2162a-bsp0.4
endif
endif


