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

DEBCHROOT=debchroot
ROOTFS=rootfs
ROOTFS_DEBOOTSTRAP1=$(ROOTFS)-debootstrap1
ROOTFS_DEBOOTSTRAP1_CONFIGURED=$(ROOTFS_DEBOOTSTRAP1)-conf
INSTALLDISK=/dev/sdb1
INSTALLDISKMOUNT=/mnt/usbdrive
TEMP=$(BUILD)/tmp
ifeq ($(ARCHNAME), amd64)
QEMUSTATIC=qemu-x86_64-static
else
ifeq ($(ARCHNAME), arm64)
QEMUSTATIC=qemu-aarch64-static
else
QEMUSTATIC=qemu-arm-static
endif
endif

ifneq ($(CACHE_DIR),)
DEBOOTSTRAP_OPTS+=--cache-dir=$(CACHE_DIR)
endif

ifeq ($(VARIANT),)
VARIANT=-default
endif

FAKEROOT=`if [ -z $$FAKEROOTKEY ]; then echo "fakeroot -i $(BUILD)/fakerootstate -s $(BUILD)/fakerootstate"; fi;`

all: rootfs

ifeq ($(QEMU),y)
rootfs: $(BUILD)/$(DEBCHROOT).tgz
else
rootfs: $(BUILD)/debootstrap.tgz
endif

ifeq ($(QEMU),y)
$(BUILD)/$(DEBCHROOT).tgz:  $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz
	rm -f $(DEBCHROOT).tgz
	(sudo umount $(BUILD)/$(DEBCHROOT)/dev $(BUILD)/$(DEBCHROOT)/proc $(BUILD)/$(DEBCHROOT)/sys; sudo rm -rf $(BUILD)/$(DEBCHROOT))
	mkdir -p $(BUILD)/$(DEBCHROOT)
#	(cd $(BUILD)/$(DEBCHROOT); $(FAKEROOT) tar -xzf $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz)
#	$(FAKEROOT) cp /usr/bin/$(QEMUSTATIC) $(BUILD)/$(DEBCHROOT)/usr/bin
	(cd $(BUILD)/$(DEBCHROOT); sudo tar -xzf $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz)
	sudo cp /usr/bin/$(QEMUSTATIC) $(BUILD)/$(DEBCHROOT)/usr/bin
	# needed as debootstrap unable to run mount from inside a VM as euid of root is not zero .. FIXME?
	sudo sed -i 's/setup_proc$$/#setup_proc/' $(BUILD)/$(DEBCHROOT)/debootstrap/debian-common
#	(cd $(BUILD)/$(DEBCHROOT) && sudo mount --bind /proc proc && sudo mount --bind /sys sys && sudo mount --bind /dev/random dev/random && sudo chroot . /configscript.sh; sudo umount proc sys dev/random; rm configscript.sh)
	(cd $(BUILD)/$(DEBCHROOT) && sudo mount --bind /proc proc && sudo mount --bind /sys sys && sudo mount --bind /dev dev && sudo chroot . /configscript.sh; sudo umount proc sys dev; sudo rm configscript.sh)
#	(cd $(BUILD)/$(DEBCHROOT) && sudo mount --bind /proc proc && sudo mount --bind /sys sys && sudo chroot . /configscript.sh; sudo umount proc sys; rm configscript.sh)
ifneq ($(ROOTFS_ROOTPASSWORD),)
	sudo cp rootpasswd.sh $(BUILD)/$(DEBCHROOT)
	sudo sed -i 's/ROOTPASSWD/$(ROOTFS_ROOTPASSWORD)/' $(BUILD)/$(DEBCHROOT)/rootpasswd.sh
	(sudo chroot $(BUILD)/$(DEBCHROOT) /rootpasswd.sh)
	sudo rm $(BUILD)/$(DEBCHROOT)/rootpasswd.sh 
endif
ifeq ($(ROOTFS_NOROOTPASSWORD),y)
	sudo cp norootpasswd.sh $(BUILD)/$(DEBCHROOT)
	(sudo chroot $(BUILD)/$(DEBCHROOT) /norootpasswd.sh)
	sudo rm $(BUILD)/$(DEBCHROOT)/norootpasswd.sh 
endif
ifeq ($(ROOTFS_ADDGUEST),y)
	sudo cp addguest.sh $(BUILD)/$(DEBCHROOT)
	(sudo chroot $(BUILD)/$(DEBCHROOT) /addguest.sh)
	sudo rm $(BUILD)/$(DEBCHROOT)/addguest.sh 
endif
ifeq ($(DEBCHROOT_TOOLS),y)
	sudo cp chroot_apt_update.sh $(BUILD)/$(DEBCHROOT)
	sudo cp chroot_apt_clean.sh $(BUILD)/$(DEBCHROOT)
	sudo cp chroot.sh $(BUILD)/$(DEBCHROOT)
	cp modify_rootfs.sh $(BUILD)
endif
	sudo tar -C $(BUILD)/$(DEBCHROOT) -czf $(BUILD)/$(DEBCHROOT).tgz .
	if [ -d $(BUILD)/$(DEBCHROOT) ]; then sudo rm -rf  $(BUILD)/$(DEBCHROOT); fi
endif


$(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz: $(BUILD)/$(ROOTFS_DEBOOTSTRAP1).tgz $(ROOTFS_CONFIG) $(FILES)
	(cd $(BUILD) && rm -rf $(ROOTFS) && mkdir -p $(ROOTFS))
	# no idea if this is needed
	rm -f $(BUILD)/fakerootstate
	(cd $(BUILD)/$(ROOTFS) && $(FAKEROOT) tar xzf $(BUILD)/$(ROOTFS_DEBOOTSTRAP1).tgz)
#	$(FAKEROOT) "./rootfs-config-$(BOARD)$(VARIANT)" "$(BUILD)/$(ROOTFS)" "files-$(BOARD)$(VARIANT)"
	$(FAKEROOT) "$(ROOTFS_CONFIG)" "$(BUILD)/$(ROOTFS)" "$(FILES)"
ifneq ($(MODULES),)
	cp -r $(MODULES)/lib/* $(BUILD)/$(ROOTFS)/lib
endif
ifneq ($(ADD_SOURCE),)
	echo "************ ADD_SOURCE **************"
	echo "adding $(ADD_SOURCE)"
	cp $(ADD_SOURCE) $(BUILD)/$(ROOTFS)/usr/src/
endif
ifneq ($(VMLINUZ),)
	cp $(VMLINUZ) $(BUILD)/$(ROOTFS)/boot/vmlinuz
endif
ifneq ($(SWITCHROOT_FILE),)
	echo "Switchroot enabled" > $(BUILD)/$(ROOTFS)/$(SWITCHROOT_FILE)
endif
	$(FAKEROOT) tar -C $(BUILD)/$(ROOTFS) -czf $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz .

$(BUILD)/$(ROOTFS_DEBOOTSTRAP1).tgz:
	#Clean-up: in order to use fakeroot we have to clean out rootfs first 
	mkdir -p $(BUILD)
ifneq ($(CACHE_DIR),)
	mkdir -p $(CACHE_DIR)
endif
	(cd $(BUILD) && rm -rf $(ROOTFS))
	rm -f $(BUILD)/fakerootstate
	
	# build rootfs with debootstrap and then fix it up enough to run /debootstrap/debootstrap --second-stage
	# and tar up the resulting whole.
	# Fakeroot state is loaded/saved between invocations to preserve ownerships
	# INCLUDE_DEBS="ser2net,mc,usbutils,firmware-ralink,wireless-tools,wpasupplicant,crda"
	DBOPTIONS="$(shell cat $(INCLUDE_PACKAGES) | tr '\n' ',' | tr -d ' ')" ; \
	echo "$${DBOPTIONS}" && \
	echo "**************" && \
	echo "**************" && \
	if [ -d $(DEBOOTSTRAP_DIR) ]; then cd $(DEBOOTSTRAP_DIR); fi && \
	$(FAKEROOT) $(DEBOOTSTRAP) $(DEBOOTSTRAP_OPTS) --arch=$(ARCHNAME) --components=$(COMPONENTS_LIST) --include="$${DBOPTIONS}" --exclude="$(EXCLUDE_PACKAGES)"--variant=minbase --foreign $(SUITE) $(BUILD)/$(ROOTFS) $(REPOSITORY) && \
	cd $(BUILD) && \
	echo "**************" && \
	echo "**************" && \
	echo "******" ; \
	echo "FAKEROOTKEY = $(FAKEROOTKEY)" ; \
	echo "FAKEROOT = $(FAKEROOT)" ; \
	echo "******" ; \
	$(FAKEROOT) tar -C $(BUILD)/$(ROOTFS) -czf $(BUILD)/$(ROOTFS_DEBOOTSTRAP1).tgz .

$(BUILDDIR)/kernel/modules.tgz:
	$(MAKE) $(BUILDDIR)/kernel/modules.tgz -C ../kernel

installdisk: rootfs
	mount $(INSTALLDISK)
	cp $(BUILD)/debianrootstrap.tgz $(INSTALLDISKMOUNT)/
	umount $(INSTALLDISKMOUNT)

clean:
	$(RM) $(BUILD)/*.tgz

ifeq ($(QEMU),y)
dist: $(BUILD)/$(DEBCHROOT).tgz
	install -D $(BUILD)/$(DEBCHROOT).tgz $(DISTRODIR)/binaries/rootfs/`basename $(BUILD)`/$(DEBCHROOT).tgz 
else
dist: $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz
	install -D $(BUILD)/$(ROOTFS_DEBOOTSTRAP1_CONFIGURED).tgz $(DISTRODIR)/binaries/rootfs/`basename $(BUILD)`/needs-chroot-configure-rootfs.tgz
endif
ifeq ($(DEBCHROOT_TOOLS),y)
	install -D $(BUILD)/modify_rootfs.sh $(DISTRODIR)/binaries/rootfs/`basename $(BUILD)`/modify_rootfs.sh
#	sed -i $(DISTRODIR)/binaries/rootfs/debootstrap/$(BOARD)-$(SUITE)_modify_rootfs.sh -e "s/debchroot/$(BOARD)-$(SUITE)-rootfs/"
endif

distclean: clean
	(cd $(BUILDBASE) && $(RM) -rf * )
	-(cd $(DISTRODIR)/binaries/rootfs/debootstrap && $(RM) -rf debian )
	-(cd $(DISTRODIR)/sources/rootfs/debootstrap && $(RM) -rf debian )

source:
	mkdir -p $(DISTRODIR)/sources/rootfs/debian
	( cd $(DISTRODIR)/sources/rootfs/debian && $(RM) -rf * )
	# .debs have been copied to $(BUILD)/sources/packages by multistrap
	mkdir -p $(DISTRODIR)/sources/rootfs/debian/packages
	cp -v $(BUILD)/sources/packages/*.deb $(DISTRODIR)/sources/rootfs/$(DEBIANDIR)/packages
#	( cd $(DISTRODIR)/sources/rootfs/emdebian && svn export --force svn://balloonboard.org/balloon/branches/menuconfig//rootfs/emdebian . )

.PHONY: all rootfs clean distclean install dist source installdisk
