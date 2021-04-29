#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/u-boot/u-boot.deps

ifeq ($(SNIC_PACKAGE_UBOOT),y)

u-boot_CONFIG=$(SOC)-$(BOARD)_custom_defconfig

ifeq ($(SNIC_FIRMWARE_DPAA2_DISABLED), y)
u-boot_VARIANT=-dpaa2-disabled
endif

# defaults
u-boot_REPO_GIT:=y
u-boot_CHECKOUT:=master
u-boot_REPO:=https://github.com/u-boot/u-boot

ifeq ($(SNIC_UBOOT_LATEST),y)
# force latest
else

ifeq ($(SNIC_NXP), y)
u-boot_REPO:=https://source.codeaurora.org/external/qoriq/qoriq-components

ifneq ($(QORIQ_TAG),)
u-boot_CHECKOUT:=$(QORIQ_TAG)
u-boot_VER:=$(u-boot_CHECKOUT)
endif

ifeq ($(QORIQ_TAG),LSDK-20.04)
u-boot_CHECKOUT:=$(u-boot_CHECKOUT)-update-290520
endif
endif

endif

# default VER
ifeq ($(u-boot_VER),)
u-boot_VER:=$(u-boot_CHECKOUT)
endif

u-boot_ENV_MAKEOPTS+=ARCH=$(ARCH) CROSS_COMPILE=$(CROSSNAME)
u-boot_MAKEOPTS+=$(MAKEOPTS) SUBLEVEL=$(SDK_VERSION)
ifeq ($(u-boot_CONFIGSCRIPT),)
u-boot_CONFIGSCRIPT=(cp $(BUILDDIR)/.conf/u-boot/config configs/$(u-boot_CONFIG); $(u-boot_ENV_MAKEOPTS) $(MAKE) $(u-boot_CONFIG))
endif
ifeq ($(SNIC_UBOOT_MINIMAL),y)
u-boot_BUILD=$(u-boot_VER)-$(BOARD)$(VARIANT)-minimal
else
u-boot_BUILD=$(u-boot_VER)-$(BOARD)$(VARIANT)
endif
u-boot_BUILDDIR=$(BUILDDIR)/u-boot/u-boot-$(u-boot_BUILD)
u-boot_IMAGE=$(u-boot_BUILDDIR)/u-boot.bin
u-boot_elf_IMAGE=$(u-boot_BUILDDIR)/u-boot.elf
u-boot_IMAGES+=$(u-boot_IMAGE) $(u-boot_elf_IMAGE)
u-boot_DEPENDS=$(u-boot_BUILDDIR)/.config

#$(info $(call package-builder,u-boot))
$(eval $(call package-builder,u-boot))

u-boot-rebuild: u-boot-config
	touch $(BUILDDIR)/u-boot/u-boot-$(u-boot_BUILD)/.config
	$(MAKE) u-boot

u-boot-cleanbuild: u-boot-config
	$(MAKE) -C $(u-boot_BUILDDIR) clean
	$(MAKE) u-boot
	

u-boot-menuconfig: u-boot-config
	$(MAKE) menuconfig -C $(u-boot_BUILDDIR)

u-boot-dist:
	install -D $(u-boot_IMAGE) $(DISTRODIR)/binaries/u-boot/u-boot.bin

.PHONY: u-boot-menuconfig u-boot-rebuild u-boot-cleanbuild u-boot-dist

endif

u-boot-mainhelp:
	@echo "u-Boot: NXP U-Boot loader "

u-boot-help:

	@echo "u-Boot: NXP U-Boot loader"
	@echo "u-boot-menuconfig -      u-boot configuration"
	@echo "u-boot-rebuild -         Incremental Build"
	@echo "u-boot-cleanbuild -      Clean "

TARGETS_HELP+=u-boot-mainhelp

.phony: u-boot-help

