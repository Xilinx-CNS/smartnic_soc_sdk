#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
# Title:    Makefile
# Purpose:  Makes emdebian rootfs using deboostrap
# Needs debootstrap >= 1.9.0

#include $(CHECKOUT)/Makefile.in

RPMCHROOT=rpmchroot
ROOTFS=rootfs
ROOTFS_RPM1=$(ROOTFS)-rpm1
ROOTFS_RPM1_CONFIGURED=$(ROOTFS_RPM1)-conf
INSTALLDISK=/dev/sdb1
INSTALLDISKMOUNT=/mnt/usbdrive
TEMP=$(BUILD)/tmp
ifeq ($(ARCHNAME), arm64)
QEMUSTATIC=qemu-aarch64-static
else
QEMUSTATIC=qemu-arm-static
endif

#ifneq ($(CACHE_DIR),)
#DEBOOTSTRAP_OPTS+=--cache-dir=$(CACHE_DIR)
#endif

ifeq ($(VARIANT),)
VARIANT=-default
endif

#FAKEROOT=`if [ -z $$FAKEROOTKEY ]; then echo "fakeroot -i $(BUILD)/fakerootstate -s $(BUILD)/fakerootstate"; fi;`
FAKEROOT=sudo

all: rootfs

ifeq ($(QEMU),y)
rootfs: $(BUILD)/$(RPMCHROOT).tgz
else
rootfs: $(BUILD)/rpmrootfs.tgz
endif

ifeq ($(HAS_DNF),y)
INSTALLER=dnf
else
ifeq ($(NATIVE_BUILD),y)
ifeq ($(HAS_YUM),y)
INSTALLER=yum
endif
endif
endif

ifeq ($(QEMU),y)
$(BUILD)/$(RPMCHROOT).tgz:  $(BUILD)/$(ROOTFS_RPM1_CONFIGURED).tgz
	rm -f $(RPMCHROOT).tgz
	(sudo umount $(BUILD)/$(RPMCHROOT)/dev; sudo umount $(BUILD)/$(RPMCHROOT)/proc; sudo umount $(BUILD)/$(RPMCHROOT)/sys; sudo rm -rf $(BUILD)/$(RPMCHROOT))
	mkdir -p $(BUILD)/$(RPMCHROOT)
	(cd $(BUILD)/$(RPMCHROOT); $(FAKEROOT) tar -xzf $(BUILD)/$(ROOTFS_RPM1_CONFIGURED).tgz)
	$(FAKEROOT) mkdir -p $(BUILD)/$(RPMCHROOT)/usr/bin
	$(FAKEROOT) cp /usr/bin/$(QEMUSTATIC) $(BUILD)/$(RPMCHROOT)/usr/bin
ifneq ($(INSTALLER),)
	$(FAKEROOT) $(INSTALLER) --installroot=$(BUILD)/$(RPMCHROOT) --releasever=$(RELEASEVER) install -y --nogpgcheck dnf
else
	@echo "****** ERROR Installer not available (needs dnf?) ******"
	@exit
endif
	(cd $(BUILD)/$(RPMCHROOT) && sudo mount --bind /proc proc && sudo mount --bind /sys sys && sudo chroot . /configscript.sh && sudo umount proc sys && rm configscript.sh)
ifeq ($(ROOTFS_NOROOTPASSWORD),y)
	cp norootpasswd.sh $(BUILD)/$(RPMCHROOT)
	(sudo chroot $(BUILD)/$(RPMCHROOT) /norootpasswd.sh)
	rm $(BUILD)/$(RPMCHROOT)/norootpasswd.sh 
endif
	$(FAKEROOT) tar -C $(BUILD)/$(RPMCHROOT) -czf $(BUILD)/$(RPMCHROOT).tgz .
endif

$(BUILD)/$(ROOTFS_RPM1_CONFIGURED).tgz: $(BUILD)/$(ROOTFS_RPM1).tgz $(CONFIG) $(FILES)
	(cd $(BUILD) && sudo rm -rf $(ROOTFS) && mkdir -p $(ROOTFS))
	# no idea if this is needed
	rm -f $(BUILD)/fakerootstate
#	(cd $(BUILD)/$(ROOTFS) && $(FAKEROOT) sudo tar xzf $(BUILD)/$(ROOTFS_RPM1).tgz)
	(cd $(BUILD)/$(ROOTFS) && sudo tar xzf $(BUILD)/$(ROOTFS_RPM1).tgz)
	$(FAKEROOT) "$(CONFIG)" "$(BUILD)/$(ROOTFS)" "$(FILES)"
ifneq ($(MODULES),)
	cp -r $(MODULES)/lib/* $(BUILD)/$(ROOTFS)/lib
endif
ifneq ($(VMLINUZ),)
	cp $(VMLINUZ) $(BUILD)/$(ROOTFS)/boot/vmlinuz
endif
ifneq ($(SWITCHROOT_FILE),)
	echo "Switchroot enabled" > $(BUILD)/$(ROOTFS)/$(SWITCHROOT_FILE)
endif
	$(FAKEROOT) tar -C $(BUILD)/$(ROOTFS) -czf $(BUILD)/$(ROOTFS_RPM1_CONFIGURED).tgz .

#	$(FAKEROOT) $(RPM) $(RPM_OPTS) --arch=$(ARCHNAME) --components=$(COMPONENTS) $${DBOPTIONS} --variant=minbase --foreign $(SUITE) $(BUILD)/$(ROOTFS) $(REPOSITORY) && \
#	$(FAKEROOT) rpm -i --nodeps --force --root=$(BUILD)/$(ROOTFS) $$serverfile && \
#	$(FAKEROOT) yum --installroot=$(BUILD)/$(ROOTFS) --releasever=28 install -y --nogpgcheck dnf && \

#	serverpath=pub/fedora/linux/releases/28/Everything/x86_64/os/Packages/f && \

$(BUILD)/$(ROOTFS_RPM1).tgz:
	#Clean-up: in order to use fakeroot we have to clean out rootfs first 
	mkdir -p $(BUILD)
#ifneq ($(CACHE_DIR),)
#	mkdir -p $(CACHE_DIR)
#endif
	(cd $(BUILD) && sudo rm -rf $(ROOTFS))
#	rm -f $(BUILD)/fakerootstate
	
	# build rootfs with RPM and then fix it up enough to run /RPM/RPM --second-stage
	# and tar up the resulting whole.
	# Fakeroot state is loaded/saved between invocations to preserve ownerships
	# INCLUDE_DEBS="ser2net,mc,usbutils,firmware-ralink,wireless-tools,wpasupplicant,crda"
	DBOPTIONS=`cat $(PACKAGES)` ; \
	echo "$${DBOPTIONS}" && \
	echo "**************" && \
	echo "**************" && \
	cd $(BUILD) && \
	server=https://download.fedoraproject.org && \
	serverpath=pub/fedora/linux/releases/28/Everything/aarch64/os/Packages/f && \
	serverfile=fedora-repos-28-1.noarch.rpm && \
	wget $$server/$$serverpath/$$serverfile && \
	$(FAKEROOT) rpm -v -i --nodeps --force --root=$(BUILD)/$(ROOTFS) $$serverfile && \
	echo "**************" && \
	echo "**************" && \
	echo "******" ; \
	echo "FAKEROOTKEY = $(FAKEROOTKEY)" ; \
	echo "FAKEROOT = $(FAKEROOT)" ; \
	echo "******" ; \
	$(FAKEROOT) tar -C $(BUILD)/$(ROOTFS) -czf $(BUILD)/$(ROOTFS_RPM1).tgz .

$(BUILDDIR)/kernel/modules.tgz:
	$(MAKE) $(BUILDDIR)/kernel/modules.tgz -C ../kernel

installdisk: rootfs
	mount $(INSTALLDISK)
	cp $(BUILD)/debianrootstrap.tgz $(INSTALLDISKMOUNT)/
	umount $(INSTALLDISKMOUNT)

clean:
	$(RM) $(BUILD)/*.tgz

dist: $(BUILD)/rpmrootfs.tgz source
	install -D $(BUILD)/rpmrootfs.tgz $(DISTRODIR)/binaries/rootfs/RPM/$(RPMDIR)/rpmrootfs.tgz
	-install -D $(BUILD)/rpmrootfs.modules.tgz $(DISTRODIR)/binaries/rootfs/RPM/$(RPMDIR)/rpmrootfs.modules.tgz

distclean: clean
	(cd $(BUILDBASE) && $(RM) -rf * )
	-(cd $(DISTRODIR)/binaries/rootfs/RPM && $(RM) -rf rpm )
	-(cd $(DISTRODIR)/sources/rootfs/RPM && $(RM) -rf rpm )

source:
	mkdir -p $(DISTRODIR)/sources/rootfs/rpm
	( cd $(DISTRODIR)/sources/rootfs/rpm && $(RM) -rf * )
	# .debs have been copied to $(BUILD)/sources/packages by multistrap
	mkdir -p $(DISTRODIR)/sources/rootfs/rpm/packages
	cp -v $(BUILD)/sources/rpm/*.rpm $(DISTRODIR)/sources/rootfs/$(RPMDIR)/packages

.PHONY: all rootfs clean distclean install dist source installdisk
