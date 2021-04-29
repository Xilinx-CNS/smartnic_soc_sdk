#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/kernel/kernel.deps

ifeq ($(SNIC_PACKAGE_KERNEL),y)

KERNELSITE:=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot
LOCALVERSION=$(SDK_VERSION)

-include $(PACKAGEDIR)/kernel/legacy.mk

ifdef SNIC_KERNEL_5.4
kernel_VER:=v5.4
endif

ifdef SNIC_KERNEL_5.6.11
kernel_VER:=v5.6.11
endif

ifdef SNIC_KERNEL_NXP
kernel_REPO_GIT=y
kernel_REPO:=https://source.codeaurora.org/external/qoriq/qoriq-components
kernel_REPO_URL:=https://source.codeaurora.org/external/qoriq/qoriq-components/linux
kernel_REPO_NAME=linux-nxp

kernel_VER:=$(QORIQ_TAG)
kernel_CHECKOUT:=$(kernel_VER)
ifeq ($(SNIC_KERNEL_NXP_4.19),y)
kernel_VER:=$(QORIQ_TAG)-V4.19
endif

ifeq ($(SNIC_KERNEL_NXP_5.4),y)
ifeq ($(QORIQ_TAG),LSDK-20.04)
kernel_VER:=$(QORIQ_TAG)-V5.4
kernel_CHECKOUT:=$(kernel_VER)-update-290520
endif
endif
ifneq ($(SNIC_FIRMWARE_DPAA2_DISABLED),y)
kernel_VARIANT=-dpaa2-enabled
endif

kernel_DEFCONFIG_CLEAN_CUSTOM:=lsdk.config

NXP_KERNEL:=y

endif

ifeq ($(kernel_VER),)
ifeq ($(kernel_CHECKOUT),)
kernel_VER:=unknown
else
kernel_VER:=$(kernel_CHECKOUT)
endif
endif

ifeq ($(kernel_CHECKOUT),)
ifneq ($(kernel_VER),)
kernel_CHECKOUT:=$(kernel_VER)
endif
endif

KERNEL_CROSSOPTS=CROSS_COMPILE=$(CROSSNAME) ARCH=$(ARCH) LOCALVERSION=-$(LOCALVERSION)
KERNOPTS:=$(KERNEL_CROSSOPTS) BOARD=$(BOARD)

KERNOPTS+=$(KERNOPTS_EXTRA)

ifeq ($(SNIC_KERNEL_INITRAMFS_MODULES),y)
KERNOPTS+=INITRAMFS_MODULES=y
endif

ifneq (,$(SNIC_DEBIAN_PACKAGES_STAMP))
KERNOPTS+=PKGSTAMP=$(SNIC_DEBIAN_PACKAGES_STAMP)
endif


ifeq ($(SNIC_KERNEL_DEBIAN_PACKAGE),y)
KERNOPTS+=DEBIAN_PACKAGE=y
endif

NOINITRAMFSOPTS:=CONFIG_INITRAMFS_SOURCE= 
INITRAMFSOPTS:=CONFIG_INITRAMFS_SOURCE=usr/initramfs.cpio
ifeq ($(SNIC_KERNEL_INITRAMFS_COMPRESSION),y)
INITRAMFSOPTS+=CONFIG_INITRAMFS_SOURCE=usr/initramfs.cpio.gz
INITRAMFSOPTS+=CONFIG_INITRAMFS_COMPRESSION_GZIP=y
endif

ifeq ($(SNIC_KERNEL_REDUCED),y)
kernel_VARIANT:=-reduced
endif
kernel_PACKAGEDIR=$(PACKAGEDIR)/kernel
kernel_RES=$(BUILDDIR)/kernel
kernel_VERSION_NAME=$(kernel_VER)-$(BOARD)$(VARIANT)
kernel_BUILD=linux-$(kernel_VERSION_NAME)$(kernel_VARIANT)
kernel_BUILDDIR=$(BUILDDIR)/kernel/$(kernel_BUILD)
kernel_ImageBoot=$(kernel_RES)/ImageBoot-$(kernel_BUILD)
kernel_vmImageBoot=$(kernel_RES)/vmImageBoot-$(kernel_BUILD)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
kernel_zImageBoot=$(kernel_RES)/zImageBoot-$(kernel_BUILD)
kernel_zImageInitrd=$(kernel_RES)/zImageInitrd-$(kernel_BUILD)
endif
kernel_ImageInitrd=$(kernel_RES)/ImageInitrd-$(kernel_BUILD)
kernel_vmImageInitrd=$(kernel_RES)/vmImageInitrd-$(kernel_BUILD)
kernel_headers=$(kernel_RES)/$(kernel_BUILD)-headers.tgz
kernel_TARBALL_FILENAME=$(kernel_BUILD)-source.tgz
kernel_TARBALL=$(kernel_RES)/$(kernel_TARBALL_FILENAME)
kernel_BUILDER_FILENAME=kernel_builder.sh
kernel_BUILDER=$(kernel_RES)/$(kernel_BUILDER_FILENAME)
kernel_MODULES=$(kernel_RES)/$(kernel_BUILD)-modules.tgz
kinitramfs_MODULES=$(kernel_RES)/$(kernel_BUILD)-kinitramfs-modules.tgz
kernel_MODULES_SYMVERS=$(kernel_RES)/$(kernel_BUILD)-modules.symvers
kernel_MODULES_DIR=$(kernel_RES)/linux-$(kernel_VERSION_NAME)-modules
kinitramfs_MODULES_DIR=$(kernel_RES)/linux-$(kernel_VERSION_NAME)-kinitramfs-modules
kernel_DEFCONFIG_CLEAN:=defconfig $(kernel_DEFCONFIG_CLEAN_CUSTOM)
kernel_CONFIG=$(kernel_BUILDDIR)/.config
kernel_source_tmp_dir=$(kernel_TARBALL)-build
#ifneq ($(VARIANT),)
KERNOPTS+=VARIANT=$(VARIANT)
#endif

ifneq ($(SUBVARIANT),)
KERNOPTS+=SUBVARIANT=-$(SUBVARIANT)
endif

ifeq ($(kernel_REPO_GIT),)
kernel_REPO_TGZ=$(KERNELSITE)/linux-$(kernel_VER).tar.gz
kernel_BUILD_SUBDIR=linux-$(kernel_VER)
endif

kernel_DEPENDS+=$(kernel_CONFIG)

KERNOPTS+=SFC_SRCDIR=$(sfc_BUILDDIR)/drivers/net/ethernet/sfc

kinitramfs_CPIO=$(kernel_RES)/rootfs.$(ARCH).cpio

kpatches_DIR=$(kernel_PATCHESDIR)/$(kernel_VER)
kinitramfs_MODULES_LIST=$(kpatches_DIR)/initrdmodules.list
ifneq ($(wildcard $(kpatches_DIR)/initrdmodules-$(BOARD).list),)
kinitramfs_MODULES_LIST=$(kpatches_DIR)/initrdmodules-$(BOARD).list
endif
ifneq ($(wildcard $(kpatches_DIR)/initrdmodules-$(BOARD)$(VARIANT).list),)
kinitramfs_MODULES_LIST=$(kpatches_DIR)/initrdmodules-$(BOARD)$(VARIANT).list
endif

kernel_MODULESVER=$(shell ls $(kinitramfs_MODULES_DIR)/lib/modules)
kernel_MODULES_PATH=$(kinitramfs_MODULES_DIR)/lib/modules/$(kernel_MODULESVER)
ifeq ($(SNIC_KERNEL_MODULES_NODEBUG),y)
kernel_MODULES_INSTALL_OPTS:=INSTALL_MOD_STRIP=1
endif


kernel_VMLINUZVER=$(kernel_MODULESVER)

ifeq ($(SNIC_KERNEL_INITRAMFS_MODULES),y)
$(kinitramfs_CPIO): $(kinitramfs_MODULES) $(initramfs_CPIO)
	@echo "kernel_MODULESVER = $(kernel_MODULESVER)"
	@echo "kernel_MODULES_PATH = $(kernel_MODULES_PATH)"
	rm -rf fakeme
	rm -rf temp
	mkdir temp
	echo "\
	cd temp; \
	cpio -i -d -H newc -F $(initramfs_CPIO) --no-absolute-filenames; \
	if [ -f $(kpatches_DIR)/modules-$(BOARD)$(VARIANT) ]; then \
		cp $(kpatches_DIR)/modules-$(BOARD)$(VARIANT) etc/modules; \
	elif [ -f $(kpatches_DIR)/modules-$(BOARD) ]; then \
		cp $(kpatches_DIR)/modules-$(BOARD) etc/modules; \
	else \
		cp $(kpatches_DIR)/modules etc/modules; \
	fi; \
	mkdir -p lib/modules/$(kernel_MODULESVER); \
	cp $(kernel_MODULES_PATH)/modules.* lib/modules/$(kernel_MODULESVER)/; \
	cat "$(kinitramfs_MODULES_LIST)" | while read module; do \
	    if [ -e $(kernel_MODULES_PATH)/\$$module ]; then \
		echo \"Copying \$$module\"; \
		mkdir -p lib/modules/$(kernel_MODULESVER)/\$$module; \
		rmdir lib/modules/$(kernel_MODULESVER)/\$$module; \
		cp -f $(kernel_MODULES_PATH)/\$$module lib/modules/$(kernel_MODULESVER)/\$$module; \
	    fi; \
	done; " > fakeme; \
	echo "/sbin/depmod -ae -b . -F $(kernel_BUILDDIR)/System.map $(kernel_MODULESVER);" >> fakeme; \
	echo "chown -R root:root lib" >> fakeme
	echo "find . | cpio -o -H newc  > $(kinitramfs_CPIO)" >> fakeme
	chmod +x fakeme
	fakeroot ./fakeme
	rm -rf temp
	rm -rf fakeme
else
$(kinitramfs_CPIO): $(initramfs_CPIO)
	cp -f $(initramfs_CPIO) $(kinitramfs_CPIO)
endif

kinitramfs: $(kinitramfs_CPIO)

kinitramfs-clean:
	rm -f $(kinitramfs_CPIO) $(kinitramfs_UPDATE_JSON)

.PHONY: kinitramfs kinitramfs-clean

kernel_ENV_MAKEOPTS=$(KERNOPTS) $(INITRAMFSOPTS)
kernel_MAKEOPTS+=$(MAKEOPTS)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
$(kernel_zImageBoot) $(kernel_ImageBoot) $(kernel_vmImageBoot): $(kernel_CONFIG)
else
$(kernel_ImageBoot) $(kernel_vmImageBoot): $(kernel_CONFIG)
endif
	# make sure initrd is not present before building
	rm -f $(kernel_BUILDDIR)/usr/*.gz
	rm -f $(kernel_BUILDDIR)/usr/*.bz2
	rm -f $(kernel_BUILDDIR)/usr/*.cpio
	rm -f $(kernel_BUILDDIR)/usr/*.o
	echo "KERN_VERSION=$(KERN_VERSION) K_VERSION=$(K_VERSION) K_PATCHLEVEL = $(K_PATCHLEVEL) K_SUBLEVEL=$(K_SUBLEVEL)"
ifeq ($(SNIC_KERNEL_DEBIAN_PACKAGE),y)
	rm -f $(RES)/linux*.buildinfo
	rm -f $(RES)/linux*.changes
	rm -f $(RES)/linux*.deb
#ifeq ($(SNIC_KERNEL_SOURCE),y)
#	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(NOINITRAMFSOPTS) deb-pkg)
#else
	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(NOINITRAMFSOPTS) bindeb-pkg)
#endif
else
ifeq ($(ARCH),arm)
	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(NOINITRAMFSOPTS) zImage dtbs)
else
	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(NOINITRAMFSOPTS) Image Image.gz dtbs)
endif
endif
	cp $(kernel_BUILDDIR)/vmlinux $(kernel_vmImageBoot)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
ifeq ($(ARCH),arm)
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/zImage $(kernel_zImageBoot)
else
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/Image.gz $(kernel_zImageBoot)
endif
endif
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/Image $(kernel_ImageBoot)

kernel_IMAGES+=$(kernel_ImageBoot)

ifeq ($(SNIC_KERNEL_COMPRESSED),y)
kernel_IMAGES+=$(kernel_zImageBoot)
endif

ifeq ($(SNIC_KERNEL_COMPRESSED),y)
$(kernel_zImageInitrd) $(kernel_ImageInitrd) $(kernel_vmImageInitrd): $(kernel_ImageBoot) $(kinitramfs_CPIO)
else
$(kernel_ImageInitrd) $(kernel_vmImageInitrd): $(kernel_ImageBoot) $(kinitramfs_CPIO)
endif
	rm -f $(kernel_BUILDDIR)/usr/*.gz
	rm -f $(kernel_BUILDDIR)/usr/*.bz2
	rm -f $(kernel_BUILDDIR)/usr/*.cpio
	rm -f $(kernel_BUILDDIR)/usr/*.o
	cp -f $(kinitramfs_CPIO) $(kernel_BUILDDIR)/usr/initramfs.cpio
ifeq ($(SNIC_KERNEL_INITRAMFS_COMPRESSION),y)
	(cd $(kernel_BUILDDIR)/usr; gzip initramfs.cpio)
endif
	rm -rf $(kernel_BUILDDIR)/usr/*.o
ifeq ($(ARCH),arm)
	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(INITRAMFSOPTS) zImage)
else
	(cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(INITRAMFSOPTS) Image Image.gz)
endif
	cp $(kernel_BUILDDIR)/vmlinux $(kernel_vmImageInitrd)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
ifeq ($(ARCH),arm)
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/zImage $(kernel_zImageInitrd)
else
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/Image.gz $(kernel_zImageInitrd)
endif
endif
	cp $(kernel_BUILDDIR)/arch/$(ARCH)/boot/Image $(kernel_ImageInitrd)

sfc_deb:=$(wildcard  $(CHECKOUT)/imports/debian/sfc-dkms*.deb)

$(kinitramfs_MODULES): $(kernel_ImageBoot)
	@echo "Building kinitramfs modules"
	@echo "ls -al $(kinitramfs_MODULES)" `ls -alh $(kinitramfs_MODULES)`
	@echo "Building $(kinitramfs_MODULES)"
	rm -f $(kinitramfs_MODULES)
	mkdir -p $(kinitramfs_MODULES_DIR)/lib
	rm -r $(kinitramfs_MODULES_DIR)/lib
	@echo "I: Building in tree modules"
	( export INSTALL_MOD_PATH=$(kinitramfs_MODULES_DIR) && \
	cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) modules && \
	   $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(kernel_MODULES_INSTALL_OPTS) modules_install)
	@echo "I: Installed in tree modules"
	if [ ! "X$(sfc_deb)" = "X" ]; then \
		rm -rf $(kernel_RES)/net-driver/; \
		mkdir -p $(kernel_RES)/net-driver/; \
		echo "I: SFC detected"; \
		dpkg -x $(sfc_deb) $(kernel_RES)/net-driver/; \
	( export INSTALL_MOD_PATH=$(kinitramfs_MODULES_DIR) && export INSTALL_MOD_DIR=kernel/drivers/net/ethernet/sfc/ && \
	export KPATH=$(kernel_BUILDDIR) && export SRCARCH=$(ARCH) && NDEBUG=y && export C=$(CROSSNAME)gcc && export CC=$(CROSSNAME)gcc && \
	  cd $(kernel_RES)/net-driver/usr/src/sfc* && \
	  $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(kernel_MODULES_INSTALL_OPTS) && \
	  $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(kernel_MODULES_INSTALL_OPTS) modules_install) ; \
	fi;
	if [ -r $(kernel_MODULES_SYMVERS) ]; then  rm -f $(kernel_MODULE_SYMVERS); fi;
	cp $(kernel_BUILDDIR)/Module.symvers $(kernel_MODULES_SYMVERS)
	(cd $(kinitramfs_MODULES_DIR)/lib/modules; cd `ls `; rm source build && ln -s /usr/src/linux-$(kernel_VERSION_NAME) source && ln -s source build)
	(cd $(kinitramfs_MODULES_DIR) &&  tar --create --gzip --file $(kinitramfs_MODULES) lib)

$(kernel_MODULES): $(kernel_ImageBoot)
	@echo "ls -al $(kernel_MODULES)" `ls -alh $(kernel_MODULES)`
	@echo "Building $(kernel_MODULES)"
	rm -f $(kernel_MODULES)
	mkdir -p $(kernel_MODULES_DIR)/lib
	rm -r $(kernel_MODULES_DIR)/lib
	@echo "I: Building in tree modules"
	( export INSTALL_MOD_PATH=$(kernel_MODULES_DIR) && \
	cd $(kernel_BUILDDIR) && $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) modules && \
	   $(KERNEL_CROSSOPTS) $(MAKE) $(MAKEOPTS) $(kernel_MODULES_INSTALL_OPTS) modules_install)
	@echo "I: Installed in tree modules"
	if [ -r $(kernel_MODULES_SYMVERS) ]; then  rm -f $(kernel_MODULE_SYMVERS); fi;
	cp $(kernel_BUILDDIR)/Module.symvers $(kernel_MODULES_SYMVERS)
	(cd $(kernel_MODULES_DIR) &&  tar --create --gzip --file $(kernel_MODULES) lib)

$(kernel_KERNEL_MODULES_SYMVERS): $(kernel_MODULES)

ifeq ($(SNIC_KERNEL_INITRD),y)
kernel_TARGETS+=$(kernel_ImageInitrd)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
kernel_TARGETS+=$(kernel_zImageInitrd)
endif
endif

ifeq ($(SNIC_KERNEL_MODULES),y)

kernel_TARGETS+=$(kernel_MODULES) $(kinitramfs_MODULES)

#kernel_IMAGES+=$(kernel_MODULES)

kernel_modules: $(kernel_MODULES) $(kinitramfs_MODULES)

.PHONY: kernel_modules
endif

ifeq ($(SNIC_KERNEL_HEADERS),y)
kernel_IMAGES+=$(kernel_headers)
endif

kernel-clean-targets:
	rm -f $(kernel_MODULES)
	rm -f $(kinitramfs_MODULES)
	rm -f $(kernel_ImageBoot)
	rm -f $(kernel_ImageInitrd)
	rm -f $(kernel_zImageBoot)
	rm -f $(kernel_zImageInitrd)
	rm -f $(kernel_vmImageBoot)
	rm -f $(kernel_vmImageInitrd)
	rm -f $(kernel_headers)

ifeq ($(SNIC_KERNEL_REMAKE),y)
kernel-touch-config: kernel-config
	touch $(kernel_BUILDDIR)/.config

.phony: kernel-touch-config

kernel_PREDEPENDS+=kernel-touch-config
endif

kernel_DEFCONFIG=$(BOARD)$(VARIANT)_defconfig
kernel_CONFIGSCRIPT=(cp $(BUILDDIR)/.conf/kernel/config $(kernel_BUILDDIR)/arch/$(ARCH)/configs/$(kernel_DEFCONFIG); $(kernel_ENV_MAKEOPTS) $(MAKE) -C $(kernel_BUILDDIR) $(kernel_DEFCONFIG))

kernel-defconfig: kernel-patched
	rm -f $(kernel_CONFIG)
	$(KERNEL_CROSSOPTS) $(MAKE) -C $(kernel_BUILDDIR) $(kernel_DEFCONFIG_CLEAN)

ifeq ($(BOARD),lx2160ardb)
kernel_DTB=$(kernel_BUILDDIR)/arch/arm64/boot/dts/freescale/fsl-lx2160a-rdb$(VARIANT).dtb
endif
ifeq ($(BOARD),lx2160ayrk)
kernel_DTB=$(kernel_BUILDDIR)/arch/arm64/boot/dts/freescale/fsl-lx2160a-yrk$(VARIANT).dtb
kernel_DTB-m=$(kernel_BUILDDIR)/arch/arm64/boot/dts/freescale/fsl-lx2160a-yrk$(VARIANT)-m.dtb
endif
ifeq ($(BOARD),lx2162au26z)
kernel_DTB=$(kernel_BUILDDIR)/arch/arm64/boot/dts/freescale/fsl-lx2162a-u26z$(VARIANT).dtb
kernel_DTB-m=$(kernel_BUILDDIR)/arch/arm64/boot/dts/freescale/fsl-lx2162a-u26z$(VARIANT)-m.dtb
endif

ifeq ($(kernel_DTB-m),)
kernel_DTB-m=$(kernel_DTB)
endif

$(kernel_DTB) $(kernel_DTB-m): $(kernel_ImageBoot)

kernel_IMAGES+=$(kernel_DTB) $(kernel_DTB-m)

ifeq ($(SNIC_KERNEL_SOURCE),y)
$(kernel_TARBALL): $(kernel_CONFIG) $(kernel_MODULES)
	rm -f $(kernel_TARBALL)
	if [ -d "$(kernel_source_tmp_dir)" ]; then rm -rf $(kernel_source_tmp_dir); fi;
	mkdir -p $(kernel_source_tmp_dir)/$(kernel_BUILD)
	cp -r $(kernel_BUILDDIR)/* $(kernel_source_tmp_dir)/$(kernel_BUILD)
	rm -f $(kernel_source_tmp_dir)/$(kernel_BUILD)/usr/*.gz
	rm -f $(kernel_source_tmp_dir)/$(kernel_BUILD)/usr/*.bz2
	rm -f $(kernel_source_tmp_dir)/$(kernel_BUILD)/usr/*.cpio
	rm -f $(kernel_source_tmp_dir)/$(kernel_BUILD)/usr/*.o

	$(KERNEL_CROSSOPTS) $(MAKE) mrproper -C $(kernel_source_tmp_dir)/$(kernel_BUILD)
	cp $(kernel_BUILDDIR)/.config $(kernel_source_tmp_dir)/$(kernel_BUILD)/
	#cp $(kernel_BUILDDIR)/Module.symvers $(kernel_source_tmp_dir)/$(kernel_BUILD)/
	cp $(kernel_MODULES_SYMVERS) $(kernel_source_tmp_dir)/$(kernel_BUILD)/Module.symvers
	(cd $(kernel_source_tmp_dir) && rm -f $(kernel_BUILD)/patches && tar czf $(kernel_TARBALL) $(kernel_BUILD)/.config $(kernel_BUILD)/*)
	rm -rf $(kernel_source_tmp_dir)
	touch $(kernel_TARBALL)

$(kernel_BUILDER):
	cd $(kernel_BUILDDIR); \
	cd ..; \
	cp $(kernel_PACKAGEDIR)/`basename $(kernel_BUILDER)` $(kernel_BUILDER)
	sed -i $(kernel_BUILDER) -e "s/KERNEL_DIR/$(subst /,\/,$(kernel_BUILD))/"
	chmod a+x $(kernel_BUILDER); \

kernel_TARGETS+=$(kernel_TARBALL) $(kernel_BUILDER)
endif

#$(info $(call package-builder,kernel))
$(eval $(call package-builder,kernel))

$(kernel_CONFIG): $(kernel_CONFIG_STAMP)

kernel-source: $(kernel_TARBALL) $(kernel_BUILDER)

kernel-menuconfig: kernel-config
	$(MAKE) menuconfig -C $(kernel_BUILDDIR)

kernel-rebuild: kernel-config
	touch $(kernel_BUILDDIR)/.config
ifeq ($(SNIC_KERNEL_INITRD),y)
	rm -f $(kinitramfs_CPIO)
endif
	$(MAKE) kernel

ifeq ($(SNIC_KERNEL_INITRD),y)
kernel-rebuild-initramfs: kernel-config
	rm -f $(kinitramfs_CPIO)
	$(MAKE) kernel
endif

kernel-dist: $(kernel_TARGETS)
ifeq ($(SNIC_KERNEL_SOURCE),y)
	install -D $(kernel_TARBALL) $(SOURCEDIR)/kernel/`basename $(kernel_TARBALL)`
	install -D $(kernel_BUILDER) $(SOURCEDIR)/kernel/`basename $(kernel_BUILDER)`
endif
ifeq ($(SNIC_KERNEL_HEADERS),y)
	install -D $(kernel_headers) $(DISTRODIR)/binaries/kernel/`basename $(kernel_headers)`
endif
ifeq ($(SNIC_KERNEL_MODULES),y)
	install -D $(kernel_MODULES) $(DISTRODIR)/binaries/kernel/`basename $(kernel_MODULES)`
endif
	install -D $(kernel_DTB) $(DISTRODIR)/binaries/kernel/`basename $(kernel_DTB)`
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
	install -D $(kernel_zImageBoot) $(DISTRODIR)/binaries/kernel/`basename $(kernel_zImageBoot)`
endif
	install -D $(kernel_ImageBoot) $(DISTRODIR)/binaries/kernel/`basename $(kernel_ImageBoot)`
ifeq ($(SNIC_KERNEL_INITRD),y)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
	install -D $(kernel_zImageInitrd) $(DISTRODIR)/binaries/kernel/`basename $(kernel_zImageInitrd)`
endif
	install -D $(kernel_ImageInitrd) $(DISTRODIR)/binaries/kernel/`basename $(kernel_ImageInitrd)`
endif
ifeq ($(SNIC_KERNEL_DEBIAN_PACKAGE),y)
	kernver=`$(kernel_PACKAGEDIR)/getkver.sh $(kernel_BUILDDIR)/Makefile`; \
	echo "kernver from shell app = $$kernver"; \
	install -D $(kernel_RES)/linux-image-$$kernver*$(ARCH)*.deb $(DISTRODIR)/binaries/kernel/;  \
	install -D $(kernel_RES)/linux-headers-$$kernver*$(ARCH)*.deb $(DISTRODIR)/binaries/kernel/;
	install -D $(kernel_RES)/linux-libc-dev_$$kernver*$(ARCH)*.deb $(DISTRODIR)/binaries/kernel/;
endif

kernel-info:
	@echo "SOC is $(SOC)"
	@echo "BOARD is $(BOARD)"
	@echo "VARIANT is $(VARIANT)"
	@echo "kernel_BUILDDIR is $(kernel_BUILDDIR)"
	@echo "kernel_VARIANT is $(kernel_VARIANT)"
	@echo "kernel_VMLINUZ is $(kernel_VMLINUZ)"
	@echo "kernel_VMLINUZVER is $(kernel_VMLINUZVER)"

.PHONY: kernel-menuconfig kernel-rebuild kernel-source kernel-info

endif

kernel-mainhelp:
	@echo 'kernel: NXP kernel'

kernel-help:
	@echo
	@echo "=== Kernel Help ==="
	@echo
	@echo "I: no kernel help. look at the source"

TARGETS_HELP+=kernel-mainhelp

.phony: kernel-help


