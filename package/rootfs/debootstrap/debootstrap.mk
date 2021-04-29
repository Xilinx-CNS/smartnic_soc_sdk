#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
#-include $(PACKAGEDIR)/rootfs/debian/debian.deps

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP),y)

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_EXTERNAL),y)

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_EXTERNAL_MASTER),y)
debootstrap_app_VER=master
endif
ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_EXTERNAL_1.0.123),y)
debootstrap_app_VER=1.0.123
endif

debootstrap_app_REPO_GIT=y
debootstrap_app_REPO_URL=https://salsa.debian.org/installer-team/debootstrap.git
debootstrap_app_CHECKOUT=$(debootstrap_app_VER)
debootstrap_app_BUILDDIR=$(BUILDDIR)/debootstrap-src
debootstrap_app_ADDMAKEALL=n
debootstrap_app-dist:

$(eval $(call package-builder,debootstrap_app))

DEBOOTSTRAP=$(debootstrap_app_BUILDDIR)/debootstrap
DEBOOTSTRAP_DIR=$(debootstrap_app_BUILDDIR)

else

DEBOOTSTRAP=/usr/sbin/debootstrap
DEBOOTSTRAP_DIR=

debootstrap_app: $(DEBOOTSTRAP)
	echo "Using OS provided debootstrap"

endif

ifeq ($(SNIC_ROOTFS_CUSTOM),y)
DEBOOTSTRAP_CUSTOM_SUFFIX=-custom
endif

ifeq ($(SNIC_ROOTFS_VIRTIO),y)
DEBOOTSTRAP_EXTRA_SUFFIX=-virtio
endif
ifeq ($(SNIC_ROOTFS_VIRTIO_DEV),y)
DEBOOTSTRAP_EXTRA_SUFFIX=-virtio-dev
endif

debootstrap_BUILDDIR=$(BUILDDIR)/rootfs/debootstrap-$(SUITE)-$(ARCHNAME)-$(BOARD)$(VARIANT)$(DEBOOTSTRAP_EXTRA_SUFFIX)$(DEBOOTSTRAP_CUSTOM_SUFFIX)
debootstrap_TGZ_FILENAME=debchroot.tgz
debootstrap_BASE_TGZ=$(debootstrap_BUILDDIR)/$(debootstrap_TGZ_FILENAME)

debootstrap_CONFDIR=$(PACKAGEDIR)/rootfs/debootstrap

DEBOOTSTRAP_PACKAGES=$(debootstrap_CONFDIR)/debootstrap-$(SUITE).conf

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(SOC).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(SOC).conf
endif

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD).conf
endif

ifneq ($(wildcard $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT).conf),)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-$(BOARD)$(VARIANT).conf
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEVEL),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-devel.conf
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEVEL_PCI),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-$(SUITE)-devel-pci.conf
endif

ifeq ($(SNIC_ROOTFS_VIRTIO),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-virtio.conf
endif

ifeq ($(SNIC_ROOTFS_VIRTIO_DEV),y)
DEBOOTSTRAP_PACKAGES+= $(debootstrap_CONFDIR)/debootstrap-virtio-dev.conf
endif

ifeq ($(wildcard $(debootstrap_CONFDIR)/files-$(BOARD)$(VARIANT)),)
ifeq ($(wildcard $(debootstrap_CONFDIR)/files-$(BOARD)),)
ifeq ($(wildcard $(debootstrap_CONFDIR)/files-$(SOC)),)
DEBOOTSTRAP_FILES=$(debootstrap_CONFDIR)/files
else
DEBOOTSTRAP_FILES=$(debootstrap_CONFDIR)/files-$(SOC)
endif
else
DEBOOTSTRAP_FILES=$(debootstrap_CONFDIR)/files-$(BOARD)
endif
else
DEBOOTSTRAP_FILES=$(debootstrap_CONFDIR)/files-$(BOARD)$(VARIANT)
endif

ifeq ($(wildcard $(debootstrap_CONFDIR)/rootfs-config-$(BOARD)$(VARIANT)),)
ifeq ($(wildcard $(debootstrap_CONFDIR)/rootfs-config-$(BOARD)),)
ifeq ($(wildcard $(debootstrap_CONFDIR)/rootfs-config-$(SOC)),)
DEBOOTSTRAP_CONFIG=$(debootstrap_CONFDIR)/rootfs-config
else
DEBOOTSTRAP_CONFIG=$(debootstrap_CONFDIR)/rootfs-config-$(SOC)
endif
else
DEBOOTSTRAP_CONFIG=$(debootstrap_CONFDIR)/rootfs-config-$(BOARD)
endif
else
DEBOOTSTRAP_CONFIG=$(debootstrap_CONFDIR)/rootfs-config-$(BOARD)$(VARIANT)
endif

ifeq ($(SNIC_ROOTFS_CUSTOM),y)
DEBOOTSTRAP_EXTRA_OPTS+="--include=$(SNIC_ROOTFS_CUSTOM_PACKAGES)"
endif

#DEBOOTSTRAP_EXCLUDE_PACKAGES=python2.7_2.7.17-2ubuntu4

DEBOOTSTRAPOPTS = DEBOOTSTRAP_DIR=$(DEBOOTSTRAP_DIR) DEBOOTSTRAP=$(DEBOOTSTRAP) DEBOOTSTRAP_OPTS=$(DEBOOTSTRAP_EXTRA_OPTS) REPOSITORY=$(DEBREPO) ARCHNAME=$(ARCHNAME) SUITE=$(SUITE) SOC=$(SOC) BOARD=$(BOARD) VARIANT=$(VARIANT) COMPONENTS_LIST=$(COMPONENTS) ROOTFS_SUBVARIANT=$(ROOTFS_SUBVARIANT) BUILDBASE=$(debootstrap_BUILDDIR) BUILD=$(debootstrap_BUILDDIR) INCLUDE_PACKAGES="$(DEBOOTSTRAP_PACKAGES)" EXCLUDE_PACKAGES="$(DEBOOTSTRAP_EXCLUDE_PACKAGES)" FILES=$(DEBOOTSTRAP_FILES) ROOTFS_CONFIG=$(DEBOOTSTRAP_CONFIG)

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_SWITCHROOT),y)
DEBOOTSTRAPOPTS += SWITCHROOT_FILE=boot/enable_switchroot
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_DEB_CACHE),y)
DEBOOTSTRAPOPTS += CACHE_DIR=$(debootstrap_BUILDDIR)/packages
endif

ifeq ($(SNIC_QEMU),y)
DEBOOTSTRAPOPTS += QEMU=y
else
DEBOOTSTRAPOPTS += QEMU=n
endif

ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_NOROOTPASSWORD),y)
DEBOOTSTRAPOPTS += ROOTFS_NOROOTPASSWORD=y
endif
ifneq ($(SNIC_ROOTFS_DEBOOTSTRAP_ROOTPASSWORD),)
DEBOOTSTRAPOPTS += ROOTFS_ROOTPASSWORD=$(SNIC_ROOTFS_DEBOOTSTRAP_ROOTPASSWORD)
endif
ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP_ADDGUEST),y)
DEBOOTSTRAPOPTS += ROOTFS_ADDGUEST=y
endif
ifeq ($(SNIC_ROOTFS_NO_SOURCES),y)
DEBOOTSTRAPOPTS += DEBIANROOTSRAP_NO_SOURCES=y
endif
ifeq ($(SNIC_ROOTFS_CHROOT_TOOLS),y)
DEBOOTSTRAPOPTS += DEBCHROOT_TOOLS=y
endif

ifneq ($(ADD_SOURCE),)
DEBOOTSTRAPOPTS += ADD_SOURCE="$(ADD_SOURCE)"
endif

DEBOOTSTRAPOPTS += DEBCHROOT_TOOLS=y
debootstrap_DEPENDS+=debootstrap_app
debootstrap_ENV_MAKEOPTS=$(DEBOOTSTRAPOPTS)
debootstrap_MAKEOPTS=$(MAKEOPTS)
debootstrap_ADDMAKEALL=n
debootstrap-dist: debootstrap
	$(debootstrap_ENV_MAKEOPTS) $(MAKE) $(debootstrap_MAKEOPTS) -C $(debootstrap_CONFDIR) dist

debootstrap_IMAGES+=$(debootstrap_BASE_TGZ)

debootstrap_CUSTOM=$(debootstrap_BUILDDIR)/debootstrap-custom.tgz

$(debootstrap_CUSTOM): $(debootstrap_TGZ)
#$(debootstrap_CUSTOM):
	cd $(debootstrap_BUILDDIR); \
	rm -rf tmp; \
	mkdir tmp; \
	cd tmp; \
	sudo tar xzf $(debootstrap_TGZ); \
	sudo mount -o bind /dev dev ; \
	echo "Entering chroot. Type <exit> when done to repack the image"; \
	sudo chroot . ; \
	sudo umount dev ; \
	echo "repacking the image"; \
	sudo tar czf $(debootstrap_CUSTOM) . ; \
	cd .. ; \
	sudo rm -rf tmp;

debootstrap-custom: $(debootstrap_CUSTOM)

debootstrap-custom-clean:
	rm -rf  $(debootstrap_CUSTOM)

.PHONY: debootstrap-custom debootstrap-custom-clean

#$(info $(call package-builder,debootstrap))
$(eval $(call package-builder,debootstrap))

endif
