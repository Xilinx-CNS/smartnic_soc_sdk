#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/buildroot/buildroot.deps

ifeq ($(SNIC_PACKAGE_BUILDROOT),y)

ifdef SNIC_BUILDROOT_FEB_2019
BUILDROOTVER:=2019.02.2
endif

ifdef SNIC_BUILDROOT_MAY_2019
BUILDROOTVER:=2019.05.2
endif

ifdef SNIC_BUILDROOT_AUG_2019
BUILDROOTVER:=2019.08.1
endif

ifdef SNIC_BUILDROOT_FEB_2020
BUILDROOTVER:=2020.02.3
endif

ifeq ($(SNIC_BUILDROOT_DEFAULT_CONFIG),y)
endif

ifeq ($(SNIC_BUILDROOT_CEPH_CONFIG),y)
SUBVARIANT=-ceph
endif

buildroot_REPO_GIT=y
buildroot_REPO=git://git.buildroot.net
buildroot_REPO_DOWNLOAD=buildroot.git
buildroot_VER=$(BUILDROOTVER)
buildroot_CHECKOUT=$(BUILDROOTVER)

buildroot_BUILD=$(buildroot_VER)-$(BOARD)$(VARIANT)
buildroot_BUILDDIR=$(BUILDDIR)/buildroot/buildroot-$(buildroot_BUILD)
BUILDROOT_ROOTFS_CPIO=$(buildroot_BUILDDIR)/output/images/rootfs.cpio
buildroot_ROOTFS_CPIO=$(buildroot_BUILDDIR)/output/images/rootfs.cpio
buildroot_IMAGES=$(BUILDROOT_ROOTFS_CPIO)
buildroot_DEPENDS=$(buildroot_BUILDDIR)/.config
BUILDROOT_PRESEED_DIR=$(PRESEEDDIR)/buildroot-$(buildroot_VER)
BUILDROOT_DOWNLOAD_TGZ=downloads.tgz
ifeq ($(SNIC_BUILDROOT_PRESEED),y)
BUILDROOT_PRESEED=echo "looking for $(BUILDROOT_DOWNLOAD_TGZ) in $(BUILDROOT_PRESEED_DIR)"; if [ -e $(BUILDROOT_PRESEED_DIR)/$(BUILDROOT_DOWNLOAD_TGZ) ]; then ( cd $(buildroot_BUILDDIR); tar xvf $(BUILDROOT_PRESEED_DIR)/$(BUILDROOT_DOWNLOAD_TGZ) ) fi;
else
BUILDROOT_PRESEED=echo "no preseeding"
endif
buildroot_ENV_MAKEOPTS+=FORCE_UNSAFE_CONFIGURE=1
buildroot_CONFIGSCRIPT=($(BUILDROOT_PRESEED) $(buildroot_ENV_MAKEOPTS) $(MAKE) defconfig BR2_DEFCONFIG=$(BUILDDIR)/.conf/buildroot/config)

buildroot_MAKEOPTS+=$(MAKEOPTS)

$(eval $(call package-builder,buildroot))

buildroot-rebuild:
	rm -f $(buildroot_TARGETS)
	$(MAKE) clean -C $(buildroot_BUILDDIR)
	$(MAKE) buildroot

buildroot-menuconfig: buildroot-config
	$(MAKE) menuconfig -C $(buildroot_BUILDDIR)

buildroot-busybox-menuconfig: buildroot-config
	$(MAKE) busybox-menuconfig -C $(buildroot_BUILDDIR)

buildroot-rootfs: $(BUILDROOT_ROOTFS_CPIO)

buildroot-dist: $(BUILDROOT_ROOTFS_CPIO)
	install -D $(BUILDROOT_ROOTFS_CPIO) $(DISTRODIR)/binaries/buildroot/$(BOARD)-$(BUILDROOTVER)-rootfs.cpio

.PHONY: buildroot-menuconfig buildroot-busybox-menuconfig buildroot-rootfs

buildroot-snapshot:
	if [ -e $(BUILDROOT_PRESEED_DIR)/$(BUILDROOT_DOWNLOAD_TGZ) ]; then rm $(BUILDROOT_PRESEED_DIR)/$(BUILDROOT_DOWNLOAD_TGZ); fi
	mkdir -p $(BUILDROOT_PRESEED_DIR)
	(cd $(buildroot_BUILDDIR); tar -cvzf $(BUILDROOT_PRESEED_DIR)/$(BUILDROOT_DOWNLOAD_TGZ) dl/*; )

else
buildroot-snapshot:
	echo "buildroot not selected - no snapshot taken"

endif
.phony: buildroot-snapshot


buildroot-mainhelp:
	@echo "Buildroot: Create Initramfs image to use with recovery kernel"
buildroot-help:
	@echo
	@echo "buildroot Help"
	@echo "--------------"
	@echo "Targets"
	@echo "-------"
	@echo "buildroot-snapshot: Create source tar ball to preseed another smartnic-setup."
	@echo "			   "$Path of compressed source $(BUILDROOT_PRESEED_DIR)" 
	
TARGETS_HELP+=buildroot-mainhelp

.phony: buildroot-help

