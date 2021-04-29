#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
#-include $(PACKAGEDIR)/rootfs/debian/debian.deps

ifeq ($(SNIC_ROOTFS_RPM),y)


ifeq ($(SNIC_ROOTFS_FEDORA28),y)
SUITE=fedora28
RELEASEVER=28
RPMREPO=http://ports.ubuntu.com/ubuntu-ports/
endif

ifeq ($(SNIC_ROOTFS_FEDORA29),y)
SUITE=fedora29
RELEASEVER=29
RPMREPO=http://ports.ubuntu.com/ubuntu-ports/
endif

ifeq ($(BOARD),bbb)
ARCHNAME=armhf
endif
ifeq ($(BOARD),rpi2)
ARCHNAME=armh
endif

ifeq ($(BOARD),rpi3)
ifeq ($(ARCH),arm64)
ARCHNAME=arm64
else
ARCHNAME=armhf
endif
endif

ifeq ($(SOC),lx2160a)
ARCHNAME=arm64
endif

ifeq (x$(ARCHNAME),x)
ARCHNAME=armel
endif

rpm_BUILDDIR=$(BUILDDIR)/rootfs/rpm_build
rpm_CONFDIR=$(PACKAGEDIR)/rootfs/rpm

RPM_PACKAGES=$(debootstrap_CONFDIR)/rpm-$(SUITE).conf

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(SOC).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(SOC).conf
endif

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD).conf
endif

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT).conf
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_EXTRAS),y)
ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)-extras.conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)-extras.conf
endif
ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT)-extras.conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT)-extras.conf
endif
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEVEL),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-devel.conf
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEVEL_PCI),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-devel-pci.conf
endif

ifeq ($(wildcard $(rpm_CONFDIR)/files-$(BOARD)$(VARIANT)),)
ifeq ($(wildcard $(rpm_CONFDIR)/files-$(BOARD)),)
ifeq ($(wildcard $(rpm_CONFDIR)/files-$(SOC)),)
RPM_FILES=$(rpm_CONFDIR)/files
else
RPM_FILES=$(rpm_CONFDIR)/files-$(SOC)
endif
else
RPM_FILES=$(rpm_CONFDIR)/files-$(BOARD)
endif
else
RPM_FILES=$(rpm_CONFDIR)/files-$(BOARD)$(VARIANT)
endif

ifeq ($(wildcard $(rpm_CONFDIR)/rootfs-config-$(BOARD)$(VARIANT)),)
ifeq ($(wildcard $(rpm_CONFDIR)/rootfs-config-$(BOARD)),)
ifeq ($(wildcard $(rmp_CONFDIR)/rootfs-config-$(SOC)),)
RPM_CONFIG=$(rpm_CONFDIR)/rootfs-config
else
RPM_CONFIG=$(rpm_CONFDIR)/rootfs-config-$(SOC)
endif
else
RPM_CONFIG=$(rpm_CONFDIR)/rootfs-config-$(BOARD)
endif
else
RPM_CONFIG=$(rpm_CONFDIR)/rootfs-config-$(BOARD)$(VARIANT)
endif

RPMOPTS = HAS_DNF=$(HAS_DNF) HAS_YUM=$(HAS_YUM) NATIVE_BUILD=$(NATIVE_BUILD) RELEASEVER=$(RELEASEVER) RPM_OPTS="$(RPM_EXTRA_OPTS)" REPOSITORY=$(RPMREPO) ARCHNAME=$(ARCHNAME) SUITE=$(SUITE) SOC=$(SOC) BOARD=$(BOARD) VARIANT=$(VARIANT) COMPONENTS=$(COMPONENTS) ROOTFS_SUBVARIANT=$(ROOTFS_SUBVARIANT) BUILDBASE=$(rpm_BUILDDIR) BUILD=$(rpm_BUILDDIR)/rpm-$(SUITE)-$(ARCHNAME)-$(BOARD)$(VARIANT) PACKAGES="$(RPM_PACKAGES)" FILES=$(RPM_FILES) CONFIG=$(RPM_CONFIG)

ifeq ($(SNIC_ROOTFS_MODULES),y)
RPMOPTS += MODULES=$(BUILDDIR)/kernel/modules
endif

ifeq ($(SNIC_ROOTFS_KERNEL),y)
RPMOPTS += VMLINUZ=$(BUILDDIR)/kernel/zImageBoot
endif

ifeq ($(SNIC_ROOTFS_SWITCHROOT),y)
RPMOPTS += SWITCHROOT_FILE=boot/enable_switchroot
endif

#ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEB_CACHE),y)
#DEBOOTSTRAPOPTS += CACHE_DIR=$(debootstrap_BUILDDIR)/debian/packages
#endif

ifeq ($(SNIC_QEMU),y)
RPMOPTS += QEMU=y
else
RPMOPTS += QEMU=n
endif

ifeq ($(SNIC_ROOTFS_NOROOTPASSWORD),y)
RPMOPTS += ROOTFS_NOROOTPASSWORD=y
endif
ifeq ($(SNIC_ROOTFS_KERNEL_AND_MODULES),y)
RPMOPTS += ROOTFS_KERNEL_AND_MODULES=y
endif
#ifeq ($(SNIC_ROOTFS_NO_SOURCES),y)
#DEBOOTSTRAPOPTS += DEBIANROOTSRAP_NO_SOURCES=y
#endif

#debootstrap_DEPENDS=$(DEBOOTSTRAP_APP)
rpm_ENV_MAKEOPTS=$(RPMOPTS)
rpm_MAKEOPTS=$(MAKEOPTS)

#$(info $(call package-builder,debootstrap))
$(eval $(call package-builder,rpm))

endif
