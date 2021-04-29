#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# makefile for creation of custom rootfs

# requires chroot and sudo
# rootfs should have qemu-aarch64-static in /usr/bin for arm64 emulation builds
# will work for amd64 and arm64 targets

# simple example
# place rootfs_base.tgz in same dir as this script
# edit package_list.depss to include a number of packages required as a space separated set of names
# run make
# FIXME note that the $(call rootfs_getdeps) adds spaces to the callee thus clobbering the ifeq... later on
# this doesn't matter for packages but it does for cp'd files

# doing this on a .deb based distro
DEB:=y
# or rpm based distro
RPM:=

CWD=$(shell pwd)

rootfs_BASE_TGZ_NAME?=

# try and autodetect base name if not set
ifeq ($(rootfs_BASE_NAME),)
ifeq ($(wildcard rootfs_base.tgz),rootfs_base.tgz)
rootfs_BASE_TGZ_NAME=rootfs_base.tgz
else
ifeq ($(wildcard debchroot.tgz),debchroot.tgz)
rootfs_BASE_TGZ_NAME=debchroot.tgz
else
ifeq ($(wildcard rpmchroot.tgz),rpmchroot.tgz)
rootfs_BASE_TGZ_NAME=rpmchroot.tgz
else
rootfs_BASE_TGZ_NAME=rootfs.tgz
endif
endif
endif
endif

rootfs_CUSTOM_NAME=rootfs_custom
rootfs_BUILDDIR_NAME=$(rootfs_CUSTOM_NAME)

rootfs_CUSTOM_NAME_TGZ:=$(rootfs_CUSTOM_NAME).tgz
rootfs_CUSTOM_NAME_ISO:=$(rootfs_CUSTOM_NAME).iso

rootfs_BASE_TGZ=$(CWD)/$(rootfs_BASE_TGZ_NAME)
rootfs_BUILDDIR?=$(CWD)/$(rootfs_BUILDDIR_NAME)
rootfs_CUSTOM_TGZ:=$(rootfs_BUILDDIR)/$(rootfs_CUSTOM_NAME_TGZ)
rootfs_CUSTOM_ISO:=$(rootfs_BUILDDIR)/$(rootfs_CUSTOM_NAME_ISO)

# options, set FOO=BAR for BAR.deps to be parsed
PACKAGES?=package_list
LOCAL_PACKAGES?=local_packages/local_packages
SOURCE?=
APPS?=
DEBFILES?=

# options - customise in *.deps
rootfs_PACKAGES?=
rootfs_SOURCE?=
rootfs_APPS?=
rootfs_DEBFILES?=
ROOTFS_ISO?=

#options - customise kernel images
kernel_IMAGE_BOOT?=
kernel_MODULE_TAR?=
kernel_SOURCE_TAR?=

ifeq ($(kernel_IMAGE_BOOT),)
ifneq ($(wildcard kernel_images/ImageBoot-*), )
    kernel_IMAGE_BOOT=$(CWD)/$(wildcard kernel_images/ImageBoot-*)
endif
endif

ifeq ($(kernel_MODULE_TAR),)
ifneq ($(wildcard kernel_images/linux-*-modules.tgz), )
    kernel_MODULE_TAR=$(CWD)/$(wildcard kernel_images/linux-*-modules.tgz)
endif
endif

ifeq ($(kernel_SOURCE_TAR),)
ifneq ($(wildcard kernel_images/linux-*-source.tgz), )
	kernel_SOURCE_TAR=$(CWD)/$(wildcard kernel_images/linux-*-source.tgz)
endif
endif

ifeq ($(kernel_IMAGE_DEB),)
ifneq ($(wildcard kernel_images/linux-image-*.deb), )
    kernel_IMAGE_DEB=$(CWD)/$(wildcard kernel_images/linux-image-*.deb)
endif
endif

ifeq ($(kernel_HEADER_DEB),)
ifneq ($(wildcard kernel_images/linux-headers-*.deb), )
    kernel_HEADER_DEB=$(CWD)/$(wildcard kernel_images/linux-headers-*.deb)
endif
endif

define rootfs_getdeps
	$(shell if [ -e $(1).deps ]; then cat $(1).deps; fi)
endef

rootfs_TMP?=$(rootfs_BUILDDIR)/tmp
ifneq ($(PACKAGES),)
rootfs_PACKAGES+=$(strip $(call rootfs_getdeps,$(PACKAGES)))
endif
ifneq ($(LOCAL_PACKAGES),)
rootfs_LOCAL_PACKAGES+=$(strip $(call rootfs_getdeps,$(LOCAL_PACKAGES)))
ifeq ($(DEB),y)
ifneq ($(wildcard local_packages/*.deb),)
rootfs_DEBFILES+=$(wildcard local_packages/*.deb)
endif
endif
endif
ifneq ($(APPS),)
rootfs_APPS+=$(strip $(call rootfs_getdeps,$(APPS)))
endif
ifneq ($(DEBS),)
rootfs_DEBFILES+=$(strip $(call rootfs_getdeps,$(DEBS)))
endif
ifneq ($(SOURCE),)
rootfs_SOURCE=$(strip $(call rootfs_getdeps,$(SOURCE)))
endif

# targets
rootfs_TARGETS+=$(rootfs_CUSTOM_TGZ)
ifeq ($(ROOTFS_ISO),y)
rootfs_TARGETS+=$(rootfs_CUSTOM_ISO)
endif

main: $(rootfs_TARGETS)

clean:
	echo "Cleaning"
	if [ -d $(rootfs_TMP) ]; then sudo umount -f $(rootfs_TMP)/dev/pts $(rootfs_TMP)/dev $(rootfs_TMP)/sys $(rootfs_TMP)/proc || true; fi
	sudo rm -rf $(rootfs_BUILDDIR)

$(rootfs_CUSTOM_ISO): $(rootfs_CUSTOM_TGZ)
	@cd $(rootfs_TMP); sudo mkisofs -J -joliet-long -l -r -o $(rootfs_CUSTOM_ISO) .

$(rootfs_CUSTOM_TGZ): $(rootfs_BASE_TGZ)
	@if [ -d $(rootfs_TMP)/dev ]; then \
	  sudo umount -f $(rootfs_TMP)/dev $(rootfs_TMP)/sys $(rootfs_TMP)/proc || true; \
	fi
	@if [ -d $(rootfs_TMP) ]; then \
	  sudo rm -rf $(rootfs_TMP); \
	fi
	@mkdir -p $(rootfs_TMP)
	@chmod 777 $(rootfs_TMP)
	@echo "I: Building rootfs $(rootfs_CUSTOM_NAME) in dir $(rootfs_BUILDDIR_NAME) from $(rootfs_BASE_TGZ_NAME)"
	@echo "I: creating rootfs copy for customisation"
	@cd $(rootfs_TMP); sudo tar xzf $(rootfs_BASE_TGZ)
ifneq ($(kernel_IMAGE_BOOT),)
	@echo "I:copying kernel image $(kernel_IMAGE_BOOT)"
	@sudo rm -rf $(rootfs_TMP)/boot/vmlinuz*
	@sudo cp $(kernel_IMAGE_BOOT) $(rootfs_TMP)/boot/vmlinuz
endif
ifneq ($(kernel_MODULE_TAR),)
	@echo "I:copying kernel modules $(kernel_MODULE_TAR)"
	@sudo rm -rf $(rootfs_TMP)/lib/modules/
	@cd $(rootfs_TMP); sudo tar xf $(kernel_MODULE_TAR) -C lib/ --strip-components 1
endif
ifneq ($(rootfs_SOURCE),)
	@echo "I: copying source files $(rootfs_SOURCE)"
	@sudo cp $(rootfs_SOURCE) $(rootfs_TMP)/usr/src/
endif
ifneq ($(rootfs_APPS),)
	@echo "I: copying applications $(rootfs_APPS)"
	@sudo cp $(rootfs_APPS) $(rootfs_TMP)/usr/bin/
endif
ifneq ($(rootfs_DEBFILES),)
	@sudo mkdir -p $(rootfs_TMP)/srv/local-apt-repository
	@echo "I: copying debians $(rootfs_DEBFILES)"
	@echo "I: DEB FILES$(rootfs_DEBFILES)=="
	@sudo cp -f $(rootfs_DEBFILES) $(rootfs_TMP)/srv/local-apt-repository
endif

# create execution script
	@echo "I: creating configuration script"
ifneq ($(rootfs_PACKAGES),)
	@echo "I: .. installing extra packages $(rootfs_PACKAGES)"
endif
	@echo "#!bin/sh" | sudo tee $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo C: updating repository metadata" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(DEB),y)
	@echo "apt -o APT::Sandbox::User=root update" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
	@echo "echo C: upgrading packages" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(DEB),y)
	@echo "DEBIAN_FRONTEND=noninteractive apt -y upgrade" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(RPM),y)
	@echo "yum update --assumeyes" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
ifneq ($(rootfs_PACKAGES),)
	@echo "echo C: installing new packages" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(DEB),y)
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install $(rootfs_PACKAGES)" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
ifneq ($(rootfs_DEBFILES),)
	@echo "I: .. installing local debian packages $(rootfs_LOCAL_PACKAGES)"
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install local-apt-repository" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "/usr/lib/local-apt-repository/rebuild -f" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "apt -o APT::Sandbox::User=root update" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install $(rootfs_LOCAL_PACKAGES)" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif

ifeq ($(kernel_IMAGE_BOOT),)
ifneq ($(kernel_IMAGE_DEB),)
	@echo "I: installing debian kernel" \
	echo "rm -rf /boot/vmlinuz*" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh; \
	echo "rm -rf /lib/modules/*" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh; \
	echo "DEBIAN_FRONTEND=noninteractive apt -y install $(kernel_IMAGE_DEB)" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh;
endif
endif

ifneq ($(kernel_HEADER_DEB),)
	@echo "I: installing debian kernel" \
	echo "DEBIAN_FRONTEND=noninteractive apt -y install $(kernel_HEADER_DEB)" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh;
endif

endif
ifeq ($(RPM),y)
	@echo "yum install --assumeyes $(rootfs_PACKAGES)" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
endif
ifneq ($(kernel_SOURCE_TAR),)
	@echo "I: Installing kernel source tree"
	@sudo rm -rf $(rootfs_TMP)/usr/src/linux-*
	@cd $(rootfs_TMP)/usr/src; sudo tar xf $(kernel_SOURCE_TAR)
	@cd $(rootfs_TMP); builddir=`ls -d usr/src/linux-*`; echo "cd $$builddir; make modules_prepare" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
#ifeq ($(CLEANUP),y)
#	@echo "echo C: removing waste-of-space" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
#endif
ifeq ($(DEB),y)
# record package list
	@echo "echo C: create package list" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sudo dpkg --get-selections | grep install | cut -f 1 > /config.deps" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
# add cleanup
	@echo "echo C: cleaning up packages and removing metadata" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt -y autoremove" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt clean" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@echo "rm -rf /var/lib/apt/lists/*" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
endif
	@echo "echo C: configuration done" | sudo tee -a $(rootfs_TMP)/tmp/dostuff.sh
	@sudo chmod a+x $(rootfs_TMP)/tmp/dostuff.sh
# now execute in emulated environment
# proc needed by installer of ca-cerificates-java as "keytool needs mounted proc"
	@echo "I: bind mounting /dev and /proc, chrooting to temp rootfs and executing configuration script"
	@sudo mount -o bind /dev $(rootfs_TMP)/dev
	@sudo mount -o bind /dev/pts $(rootfs_TMP)/dev/pts
	@sudo mount -o bind /proc $(rootfs_TMP)/proc
	@sudo mount -o bind /sys $(rootfs_TMP)/sys
	cd $(rootfs_TMP); sudo chroot . /tmp/dostuff.sh; if [ -e config.deps ]; then sudo cp config.deps ../$(rootfs_CUSTOM_NAME).deps; fi
#ifeq ($(CLEANUP),y)
#ifeq ($(BR2_QEMU),y)
#	@echo "I: removing qemu static binary"
#	@sudo rm -f $(rootfs_TMP)/usr/bin/qemu*static
#endif
#endif
	@cd $(rootfs_TMP); sudo umount dev/pts dev proc sys || true
	@echo "I: creating $(rootfs_CUSTOM_TGZ)"
	@cd $(rootfs_TMP); sudo tar czf $(rootfs_CUSTOM_TGZ) .
	#sudo rm -rf $(rootfs_TMP)

.phony: main clean
