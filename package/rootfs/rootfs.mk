#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/rootfs/rootfs.deps

ifeq ($(SNIC_PACKAGE_ROOTFS),y)

ifeq ($(SNIC_ROOTFS_BUSTER),y)
SUITE=buster
endif
ifeq ($(SNIC_ROOTFS_BULLSEYE),y)
SUITE=bullseye
endif
ifeq ($(SNIC_ROOTFS_SID),y)
SUITE=sid
endif
ifeq ($(SNIC_ROOTFS_BIONIC),y)
SUITE=bionic
UBUNTU=y
endif
ifeq ($(SNIC_ROOTFS_FOCAL),y)
SUITE=focal
UBUNTU=y
endif

ifeq ($(SNIC_ROOTFS_ARCH_AMD64),y)
ARCHNAME=amd64
else
ifeq ($(ARCH),arm64)
ARCHNAME=arm64
else
ARCHNAME=armhf
endif
endif

ifeq ($(UBUNTU),y)
ifeq ($(ARCHNAME),amd64)
DEBREPO?=http://ubuntu.mirrors.uk2.net/ubuntu
else
DEBREPO?=http://ports.ubuntu.com/
endif
COMPONENTS=main,universe
else
DEBREPO?=http://ftp.uk.debian.org/debian/
COMPONENTS=main
endif

rootfs_GETSOURCES:="getsources.sh"

ifneq ($(SNIC_ROOTFS_ALT_REPO),)
DEBREPO=$(SNIC_ROOTFS_ALT_REPO)
endif


ifeq (x$(ARCHNAME),x)
ARCHNAME=armel
endif
DEBDIR=$(CHECKOUT)/imports/debian
ifeq ($(SNIC_ROOTFS_DEBOOTSTRAP),y)

include $(CHECKOUT)/package/rootfs/debootstrap/*.mk
rootfs_TGZ_FILENAME=$(debootstrap_TGZ_FILENAME)
rootfs_BUILDDIR=$(debootstrap_BUILDDIR)

rootfs-clean: debootstrap-clean

rootfs-dist: debootstrap-dist

.PHONY: rootfs rootfs-clean rootfs-dist
endif


rootfs_CUSTOM_NAME:=custom

ifeq ($(SNIC_ROOTFS_DEB_CUSTOM),y)

define rootfs_getdeps
	$(shell if [ -e $(rootfs_CONFDIR)/$(SUITE)-$(1).deps ]; then cat $(rootfs_CONFDIR)/$(SUITE)-$(1).deps; elif [ -e $(rootfs_CONFDIR)/$(1).deps ]; then cat $(rootfs_CONFDIR)/$(1).deps; fi)
endef
define import_install
	$(shell  if [ -e $(CHECKOUT)/imports/install.list ]; then cat $(CHECKOUT)/imports/install.list; fi)
endef


ifeq ($(SNIC_ROOTFS_EXTRA_REPOS),y)
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_extra
endif

ifeq ($(SNIC_ROOTFS_KERNEL_FIT),y)
rootfs_DEPENDS+=$(FIT_BUILD)/$(FIT_KERNEL_ITB)
endif

ifeq ($(SNIC_ROOTFS_KERNEL),y)
rootfs_DEPENDS+=$(kernel_IMAGE)
endif

ifeq ($(SNIC_ROOTFS_KERNEL_MODULES),y)
rootfs_DEPENDS+=$(kernel_modules)
endif

rootfs_BOARD_CUSTOMISATION_SCRIPT:=customise-$(BOARD).sh
rootfs_BOARD_CUSTOMISATION_DIR:=customise-$(BOARD)
ifeq ($(SNIC_ROOTFS_CUSTOMDEB),y)
ifneq ($(wildcard $(DEBDIR)/*.deb),)
rootfs_DEBFILES+=$(wildcard $(DEBDIR)/*.deb)
endif
endif
ifeq ($(SNIC_ROOTFS_KERNEL_SOURCE),y)
kerneldep_PACKAGES+=$(call rootfs_getdeps,kernel-source)
rootfs_DEPENDS+=$(kernel_TARBALL)
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_ksrc
endif
ifeq ($(SNIC_ROOTFS_DIAGNOSTIC),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,diagnostic)
rootfs_DEBFILES+=$(diagnostics_stress_DEBFILE)
endif
ifeq ($(SNIC_ROOTFS_GRUB),y)
rootfs_PACKAGES+=grub-efi-$(ARCHNAME)
ifeq ($(SNIC_ROOTFS_GRUB_INSTALL),y)
ifeq ($(ARCHNAME),arm64)
rootfs_GRUB_SRC=/usr/lib/grub/arm64-efi/monolithic/grubaa64.efi
endif
ifeq ($(ARCHNAME),amd64)
rootfs_GRUB_SRC=/usr/lib/grub/x86_64-efi/monolithic/grubx64.efi
endif
endif
rootfs_GRUB_DEST=/boot/efi/grub.efi
endif

ifeq ($(SNIC_ROOTFS_INITRAMFS),y)
rootfs_PACKAGES+=initramfs-tools
endif

ifeq ($(SNIC_ROOTFS_OVERLAYROOT),y)
rootfs_PACKAGES+=overlayroot
endif

ifeq ($(SNIC_ROOTFS_LOCAL_APT_REPO),y)
rootfs_PACKAGES+=local-apt-repository
endif

ifeq ($(SNIC_ROOTFS_CEPH_DEPLIB),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,ceph)
endif

ifeq ($(SNIC_ROOTFS_ONLOAD_DEPLIB),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,onload)
endif

ifeq ($(SNIC_ROOTFS_SPDK_DEPLIB),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,spdk)
endif

ifeq ($(SNIC_ROOTFS_DPDKSFC_DEPLIB),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,dpdksfc)
endif

ifeq ($(SNIC_ROOTFS_OVS),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,ovs)
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_ovs
endif

rootfs_PACKAGES+=$(call import_install)

ifeq ($(SNIC_ROOTFS_DEV),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,dev)
ifeq ($(SNIC_ROOTFS_DEV_ALL),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,spdk)
rootfs_PACKAGES+=$(call rootfs_getdeps,ovs)
rootfs_PACKAGES+=$(call rootfs_getdeps,oktet)
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_dev_all
else
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_dev
endif
endif

ifeq ($(SNIC_ROOTFS_OKTET),y)
rootfs_PACKAGES+=$(call rootfs_getdeps,oktet)
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_oktet
endif

ifeq ($(SNIC_ROOTFS_BUILDER),y)
rootfs_SOURCE+=$(rootfs_CONFDIR)/builder.sh
rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME)_builder
endif

# add extra packages
ifneq ($(SNIC_ROOTFS_EXTRA_PACKAGES_LIST),)
rootfs_PACKAGES+=$(SNIC_ROOTFS_EXTRA_PACKAGES_LIST)
endif


ifeq ($(SNIC_ROOTFS_PPP),y)
rootfs_PACKAGES+=ppp
runpppd_APP=$(PACKAGEDIR)/rootfs/runpppd
rootfs_APPS+=$(runpppd_APP)
ifeq ($(SNIC_ROOTFS_PPP_AUTORUN),y)
rootfs_PACKAGES+=dialog
root_AUTOLOGIN=$(PACKAGEDIR)/rootfs/autologin.conf
runpppd_AUTORUN=$(PACKAGEDIR)/rootfs/runpppd-once
endif
endif

ifeq ($(SNIC_ROOTFS_THERMAL_LOAD),y)
rootfs_PACKAGES+=stress-ng
endif

rootfs_TMP=$(rootfs_BUILDDIR)/tmpchroot

rootfs_CUSTOM_NAME:=$(rootfs_CUSTOM_NAME).tgz
rootfs_CUSTOM_NAME_ISO:=$(rootfs_CUSTOM_NAME).iso

rootfs_CUSTOM:=$(rootfs_BUILDDIR)/$(rootfs_CUSTOM_NAME)
rootfs_CUSTOM_ISO:=$(rootfs_BUILDDIR)/$(rootfs_CUSTOM_NAME_ISO)

rootfs_DEPENDS+=$(rootfs_tmp_stamp)
rootfs_TARGETS+=$(rootfs_CUSTOM)
ifeq ($(SNIC_ROOTFS_ISO),y)
rootfs_TARGETS+=$(rootfs_CUSTOM_ISO)
endif

ifneq ($(wildcard $(PRESEEDDIR)/rootfs_base.tgz),)
preseed-debroot=$(BUILDDIR)/.conf/rootfs/preseed-debroot.stamp
rootfs_BASE_TGZ=$(preseed-debroot)
else
rootfs_BASE_TGZ=$(debootstrap_BASE_TGZ)
endif

$(preseed-debroot):
	cp -rf $(PRESEEDDIR)/rootfs_base.tgz $(debootstrap_BASE_TGZ);
	touch $(preseed-debroot)

$(rootfs_CUSTOM_ISO): $(rootfs_CUSTOM)
	@cd $(rootfs_TMP); sudo mkisofs -J -joliet-long -l -r -o $(rootfs_CUSTOM_ISO) .

rootfs_tmp_stamp=$(BUILDDIR)/.conf/rootfs/rootfs-tmp.stamp

include $(PACKAGEDIR)/rootfs/rfs_branding/rfs_branding.mk
include $(PACKAGEDIR)/soc_version/soc_version.mk
include $(PACKAGEDIR)/diagnostics/diagnostics.mk
include $(PACKAGEDIR)/suc_comms/suc_comms.mk
include $(PACKAGEDIR)/thermalload/thermalload.mk
include $(PACKAGEDIR)/power_throttle/power_throttle.mk
include $(PACKAGEDIR)/kernel/perf/perf.mk

rootfs_tmp_stamp=$(BUILDDIR)/.conf/rootfs/rootfs-tmp.stamp

$(rootfs_tmp_stamp): $(rootfs_BASE_TGZ) $(soc_thermal_test_IMAGES)
	@if [ -d $(rootfs_TMP) ]; then \
	  sudo rm -rf $(rootfs_TMP); \
	fi
	@mkdir -p $(rootfs_TMP)
	@mkdir -p $(rootfs_TMP)/scratch
	@echo "I: Building rootfs $(rootfs_CUSTOM_NAME)"
	@echo "I: creating rootfs copy for customisation"
	@cd $(rootfs_TMP); sudo tar xzf ../$(rootfs_TGZ_FILENAME)
	install -m 644 $(rootfs_CONFDIR)/update_version.service $(rootfs_TMP)/etc/systemd/system
	cp $(rootfs_CONFDIR)/update_version $(rootfs_TMP)/sbin/
	chmod +x $(rootfs_TMP)/sbin/update_version
	cp $(rootfs_CONFDIR)/boot_maintenance $(rootfs_TMP)/sbin/
	chmod +x $(rootfs_TMP)/sbin/boot_maintenance
	cp $(rootfs_CONFDIR)/update-cmdline $(rootfs_TMP)/sbin/
	install -m 644 $(rootfs_CONFDIR)/datetime_start.service $(rootfs_TMP)/etc/systemd/system
	install -m 644 $(rootfs_CONFDIR)/datetime_update.service $(rootfs_TMP)/etc/systemd/system
	cp $(rootfs_CONFDIR)/datetime_update $(rootfs_TMP)/sbin/
	chmod +x $(rootfs_TMP)/sbin/datetime_update
	cp $(rootfs_CONFDIR)/upgrade_soc $(rootfs_TMP)/sbin/
	cp $(rootfs_CONFDIR)/update_maintenance $(rootfs_TMP)/sbin/
	install -m 644 $(rootfs_CONFDIR)/suc_init.service $(rootfs_TMP)/etc/systemd/system
	cp $(rootfs_CONFDIR)/suc_init.sh $(rootfs_TMP)/sbin/
	chmod +x $(rootfs_TMP)/sbin/suc_init.sh
	install -m 644 $(rootfs_CONFDIR)/swap.service $(rootfs_TMP)/etc/systemd/system
	install -m 644 $(rootfs_CONFDIR)/readeeprom.service $(rootfs_TMP)/etc/systemd/system
	cp $(rootfs_CONFDIR)/read_eeprom.py $(rootfs_TMP)/usr/sbin/
ifeq ($(SNIC_ROOTFS_SOC_THERMAL_TEST),y)
	cp $(soc_thermal_test_BUILDDIR)/soc_sensors $(rootfs_TMP)/sbin/
	cp $(soc_thermal_test_BUILDDIR)/soc_load $(rootfs_TMP)/sbin/
endif
# add source files
ifeq ($(SNIC_ROOTFS_KERNEL_FIT),y)
#	echo "$(kernel_ImageBoot) copied to $(rootfs_TMP)/boot/vmlinuz" > $(rootfs_TMP)/../kernel_copied
	@echo "I: copying kernel fit image"
	@sudo cp $(FIT_BUILD)/$(FIT_KERNEL_ITB) $(rootfs_TMP)/boot/vmlinuz.fit
endif
ifeq ($(SNIC_ROOTFS_KERNEL),y)
#	echo "$(kernel_ImageBoot) copied to $(rootfs_TMP)/boot/vmlinuz" > $(rootfs_TMP)/../kernel_copied
	@echo "I: copying kernel image"
	@sudo cp $(kernel_ImageBoot) $(rootfs_TMP)/boot/vmlinuz
# horrible Kludge - FIXME
#	@echo "FIXME - horrible hardcoded kludge"
	@sudo mv $(rootfs_TMP)/boot/vmlinuz $(rootfs_TMP)/boot/vmlinuz-$(kernel_VMLINUZVER)
endif
ifeq ($(SNIC_ROOTFS_KERNEL_MODULES),y)
#	echo "contents of $(kernel_MODULES_DIR) copied to $(rootfs_TMP)/lib/modules" > $(rootfs_TMP)/../kernel_modules_copied
	@echo "I: copying kernel modules"
	@cd $(rootfs_TMP)/lib; sudo mkdir -p modules
	@sudo cp -r $(kernel_MODULES_DIR)/lib/modules/* $(rootfs_TMP)/lib/modules/
endif
ifneq ($(rootfs_SOURCE),)
	@echo "I: copying source files $(rootfs_SOURCE)"
	@sudo cp $(rootfs_SOURCE) $(rootfs_TMP)/usr/src/
endif
ifneq ($(rootfs_APPS),)
	@echo "I: copying applications $(rootfs_APPS)"
	@sudo cp $(rootfs_APPS) $(rootfs_TMP)/usr/bin/
endif
ifeq ($(SNIC_ROOTFS_LOCAL_APT_REPO),y)
	@sudo mkdir -p $(rootfs_TMP)/srv/local-apt-repository
ifneq ($(rootfs_DEBFILES),)
	@echo "I: copying debians $(rootfs_DEBFILES)"
	@sudo cp -f $(rootfs_DEBFILES) $(rootfs_TMP)/srv/local-apt-repository
endif
endif
ifeq ($(SNIC_ROOTFS_GRUB),y)
	@sudo mkdir -p $(rootfs_TMP)/boot/efi
endif
# create execution script
	@echo "I: creating configuration script"
ifneq ($(rootfs_PACKAGES),)
	@echo "I: .. installing extra packages $(rootfs_PACKAGES)"
endif
ifneq ($(rootfs_LOCAL_PACKAGES),)
	@echo "I: .. installing local packages $(rootfs_LOCAL_PACKAGES)"
endif
	@echo "#!bin/sh -e " > $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(SNIC_ROOTFS_EXTRA_REPOS),y)
	@echo "I: .. installing extra repos"
	@sudo cp $(rootfs_TMP)/etc/apt/sources.list $(rootfs_TMP)/etc/apt/sources.list.d/$(SUITE)-updates.list
	@sudo sed -i $(rootfs_TMP)/etc/apt/sources.list.d/$(SUITE)-updates.list -e "s/$(SUITE)/$(SUITE)-updates/"
	@sudo cp $(rootfs_TMP)/etc/apt/sources.list $(rootfs_TMP)/etc/apt/sources.list.d/$(SUITE)-security.list
	@sudo sed -i $(rootfs_TMP)/etc/apt/sources.list.d/$(SUITE)-security.list -e "s/$(SUITE)/$(SUITE)-security/"
endif
	@echo "echo C: updating repository metadata" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "locale-gen en_US.UTF-8" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "update-locale LANG=en_US.UTF-8" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "apt -o APT::Sandbox::User=root update" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo C: upgrading packages" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt -y upgrade" >> $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(SNIC_ROOTFS_KERNEL_SOURCE),y)
	@echo "I: .. installing kernel source tree"
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install $(kerneldep_PACKAGES)" >> $(rootfs_TMP)/tmp/dostuff.sh
	(cd $(rootfs_TMP)/lib/modules; cd `ls `; rm source build && ln -s /usr/src/linux-$(SDK_VERSION) source && ln -s source build)
	sudo mkdir -p $(rootfs_TMP)/usr/src/linux-$(SDK_VERSION)
	@sudo tar xzf $(kernel_TARBALL) --strip-components=1 -C $(rootfs_TMP)/usr/src/linux-$(SDK_VERSION)
	@echo "echo C: configuring kernel source tree" >> $(rootfs_TMP)/tmp/dostuff.sh
#	@echo "cd /usr/src/linux-$(SDK_VERSION); make oldconfig" >> $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(ARCHNAME),amd64)
# remove dpaa config options for x86 builds
	@echo "cd /usr/src/linux-$(SDK_VERSION); sed -i .config -e 's/CONFIG_STAGING=y/#CONFIG_STAGING is not set/' " >> $(rootfs_TMP)/tmp/dostuff.sh
# merge default values from x86_64 architecture
	@echo "cd /usr/src/linux-$(SDK_VERSION); make olddefconfig" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_KERNEL_SOURCE_BUILD),y)
	@echo "cd /usr/src/linux-$(SDK_VERSION); make -j 4; make modules; make modules_install; make install" >> $(rootfs_TMP)/tmp/dostuff.sh
else
	@echo "cd /usr/src/linux-$(SDK_VERSION); LOCALVERSION=-$(SDK_VERSION) make modules_prepare" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
endif

ifneq ($(rootfs_PACKAGES),)
	@echo "echo C: installing new packages" >> $(rootfs_TMP)/tmp/dostuff.sh
ifneq ($(rootfs_DEBFILES),)
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install local-apt-repository" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "/usr/lib/local-apt-repository/rebuild -f" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "apt -o APT::Sandbox::User=root update" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install $(rootfs_PACKAGES)" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifneq ($(rootfs_LOCAL_PACKAGES),)
	@echo "apt -o APT::Sandbox::User=root update" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo C: installing local packages" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt -y install $(rootfs_LOCAL_PACKAGES)" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_INITRAMFS),y)
	@echo "update-initramfs -c -k all" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_GRUB),y)
	@echo "update-grub" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_BOARD_CUSTOMISE),y)
	@if [ -x $(rootfs_CONFDIR)/$(rootfs_BOARD_CUSTOMISATION_SCRIPT) ]; then \
	    sudo cp $(rootfs_CONFDIR)/$(rootfs_BOARD_CUSTOMISATION_SCRIPT) $(rootfs_TMP)/ ; \
	    echo "/$(rootfs_BOARD_CUSTOMISATION_SCRIPT)" >> $(rootfs_TMP)/tmp/dostuff.sh ; \
	fi
	@if [ -d $(rootfs_CONFDIR)/$(rootfs_BOARD_CUSTOMISATION_DIR) ]; then \
	    sudo cp -r $(rootfs_CONFDIR)/$(rootfs_BOARD_CUSTOMISATION_DIR) $(rootfs_TMP)/ ; \
	fi
endif
ifeq ($(SNIC_ROOTFS_KERNEL),y)
	echo "cd /boot; ln -s vmlinuz-$(kernel_VMLINUZVER) vmlinuz; ln -s initrd.img-$(kernel_VMLINUZVER) initramfs" >> $(rootfs_TMP)/tmp/dostuff.sh;
endif

ifeq ($(SNIC_ROOTFS_DEB_SOURCES),y)
	@(foo="\""`cat $(rootfs_TMP)/etc/apt/sources.list;`"\""; sudo sh -c "echo $$foo >> $(rootfs_TMP)/etc/apt/sources.list")
	# then change first instance only to deb-src
	@sudo sed -i $(rootfs_TMP)/etc/apt/sources.list -e "0,/deb /{s/deb /deb-src /}"
	@sudo cp $(rootfs_CONFDIR)/$(rootfs_GETSOURCES) $(rootfs_TMP)/tmp/
	@echo "cd /tmp; ./$(rootfs_GETSOURCES)" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_ONLOAD_SOURCE_CONFIGURE),y)
	@echo "I: .. installing and configuring onload source tree"
	if [ -x $(rootfs_TMP)/usr/src/$(onload_BUILDER_FILENAME) ]; then \
	echo "echo C: unpacking and configuring onload source" >> $(rootfs_TMP)/tmp/dostuff.sh; \
	echo "cd /usr/src/; ./$(onload_BUILDER_FILENAME) configure" >> $(rootfs_TMP)/tmp/dostuff.sh; \
	fi;
endif
ifeq ($(SNIC_ROOTFS_CEPH_SOURCE_CONFIGURE),y)
	@echo "I: .. installing and configuring ceph source tree"
	if [ -x $(rootfs_TMP)/usr/src/$(ceph_BUILDER_FILENAME) ]; then \
	echo "echo C: unpacking and configuring ceph source" >> $(rootfs_TMP)/tmp/dostuff.sh; \
	echo "cd /usr/src/; ./$(ceph_BUILDER_FILENAME) configure" >> $(rootfs_TMP)/tmp/dostuff.sh; \
	fi;
endif
ifeq ($(SNIC_ROOTFS_DIAGNOSTIC),y)
	@echo "cd /srv/local-apt-repository/; dpkg -i ./$(diagnostics_stress_DEB_FILENAME); " >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifneq ($(SNIC_ROOTFS_ROOT_PASSWORD),)
	@echo "echo C: configuring root login with password $(SNIC_ROOTFS_ROOT_PASSWORD)" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo "root:$(SNIC_ROOTFS_ROOT_PASSWORD)" | chpasswd" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_OVERLAYROOT_TMPFS),y)
#	echo "sed -i /etc/overlayroot -e "s/GPART/$(subst /,\/,$(BOOT_GPART))/" >> $(rootfs_TMP)/tmp/dostuff.sh; \
	@echo "echo C: configuring overlayroot to use tmpfs for read-write data" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sed -i /etc/overlayroot.conf -e 's/overlayroot=\"\"/overlayroot=\"tmpfs:recurse=0\"/g'" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo 'if egrep \"tmpfs-root /media/root-rw\" /proc/mounts; then echo \"WARNING: overlay volatile filesystem, changes will be lost on reboot\"; fi' >>  /etc/update-motd.d/97-overlayroot" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo 'if egrep \"mmcblk1p4 /media/root-rw\" /proc/mounts; then echo \"WARNING: overlay persistent filesystem, changes will persist on Partition 4 of eMMC\"; fi' >>  /etc/update-motd.d/97-overlayroot" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_SSH_ROOT),y)
	@echo "echo C: enabling password based root ssh login" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sed -i /etc/ssh/sshd_config -e 's/#PermitRootLogin .*$$/PermitRootLogin yes/'" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_OVERLAYROOT_SCRATCH),y)
	@echo "echo C: configuring overlayroot to use scratch partition for read-write partition" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sed -i /etc/overlayroot.conf -e 's/overlayroot=\"\"/overlayroot=\"\/dev\/mmcblk1p4\"/g'" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sed -i /etc/fstab -e '/mmcblk1p4/d'" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "mkdir /var/local/data" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo 'if egrep \"tmpfs-root /media/root-rw\" /proc/mounts; then echo \"WARNING: overlay volatile filesystem, changes will be lost on reboot\"; fi' >>  /etc/update-motd.d/97-overlayroot" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo 'if egrep \"mmcblk1p4 /media/root-rw\" /proc/mounts; then echo \"WARNING: overlay persistent filesystem, changes will persist on Partition 4 of eMMC\"; fi' >>  /etc/update-motd.d/97-overlayroot" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_PPP_AUTORUN),y)
#	sudo cp $(runpppd_INITSCRIPT) $(rootfs_TMP)/etc/init.d/;
#	sudo cp $(runpppd_SCRIPT) $(rootfs_TMP)/bin/;
	sudo mkdir -p $(rootfs_TMP)/etc/systemd/system/serial-getty@ttyAMA0.service.d
	sudo cp $(root_AUTOLOGIN) $(rootfs_TMP)/etc/systemd/system/serial-getty@ttyAMA0.service.d/
	sudo cp $(runpppd_AUTORUN) $(rootfs_TMP)/usr/bin/runpppd-once
	@echo "echo 'runpppd-once' >> /root/.bashrc" >> $(rootfs_TMP)/tmp/dostuff.sh
#	@echo "systemctl enable pppd" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_CLEANUP),y)
# add package cleanup
	@echo "echo C: removing waste-of-space" >> $(rootfs_TMP)/tmp/dostuff.sh
ifeq ($(UBUNTU),y)
	@echo "DEBIAN_FRONTEND=noninteractive apt -y remove ubuntu-advantage-* " >> $(rootfs_TMP)/tmp/dostuff.sh
endif
ifeq ($(SNIC_ROOTFS_BOARD_CUSTOMISE),y)
	@echo "sudo rm /$(rootfs_CUSTOMISATION_SCRIPT)" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
endif
# record package list
	@echo "echo C: create package list" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "sudo dpkg --get-selections | grep install | cut -f 1 > /config.deps" >> $(rootfs_TMP)/tmp/dostuff.sh
# add cleanup
	@echo "echo C: cleaning up packages and removing metadata" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt -y autoremove" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "DEBIAN_FRONTEND=noninteractive apt clean" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "rm -rf /var/lib/apt/lists/*" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "ln -s /etc/systemd/system/update_version.service /etc/systemd/system/multi-user.target.wants/update_version.service" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "ln -s /etc/systemd/system/datetime_start.service /etc/systemd/system/multi-user.target.wants/datetime_start.service" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "ln -s /etc/systemd/system/datetime_update.service /etc/systemd/system/multi-user.target.wants/datetime_update.service" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "ln -s /etc/systemd/system/suc_init.service /etc/systemd/system/multi-user.target.wants/suc_init.service" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "touch /var/local/.ts" >> $(rootfs_TMP)/tmp/dostuff.sh
	sed -i $(rootfs_TMP)/etc/systemd/system/swap.service -e 's/SIZE/$(SNIC_ROOTFS_SWAP_SIZE)/' 
ifeq ($(SNIC_ROOTFS_SWAP),y)
	@echo "ln -s /etc/systemd/system/swap.service /etc/systemd/system/multi-user.target.wants/swap.service" >> $(rootfs_TMP)/tmp/dostuff.sh
endif
	@echo "ln -s /etc/systemd/system/readeeprom.service /etc/systemd/system/multi-user.target.wants/readeeprom.service" >> $(rootfs_TMP)/tmp/dostuff.sh
	@echo "echo C: configuration done" >> $(rootfs_TMP)/tmp/dostuff.sh
	@chmod a+x $(rootfs_TMP)/tmp/dostuff.sh

# now execute in emulated environment
# proc needed by installer of ca-cerificates-java as "keytool needs mounted proc"
	@echo "I: bind mounting /dev and /proc, chrooting to temp rootfs and executing configuration script"
	sudo $(rootfs_CONFDIR)/chroot_dostuff.sh $(rootfs_TMP) $(rootfs_CUSTOM_NAME)
ifeq ($(SNIC_ROOTFS_DEB_SOURCES),y)
	@sudo rm -f $(rootfs_TMP)/../$(rootfs_CUSTOM_NAME).sources.tgz
	@sudo tar -C $(rootfs_TMP)/tmp -czf $(rootfs_TMP)/../$(rootfs_CUSTOM_NAME).sources.tgz  sources
	@sudo rm -rf $(rootfs_TMP)/tmp/sources
	@ln -f  $(rootfs_TMP)/../$(rootfs_CUSTOM_NAME).sources.tgz $(PRESEEDDIR)/rootfs.source.tgz
endif
ifeq ($(SNIC_ROOTFS_GRUB_INSTALL),y)
	@sudo cp $(rootfs_TMP)/$(rootfs_GRUB_SRC) $(rootfs_TMP)/$(rootfs_GRUB_DEST)
endif
	cp -rf $(rootfs_CONFDIR)/watchdog.conf $(rootfs_TMP)/etc/
	cp -rf $(rootfs_CONFDIR)/50-default.conf $(rootfs_TMP)/etc/rsyslog.d/
	cp -rf $(rootfs_CONFDIR)/log_rotation_script $(rootfs_TMP)/etc/rsyslog.d/
	touch $(rootfs_tmp_stamp)

$(rootfs_CUSTOM):
	@echo "I: creating $(rootfs_CUSTOM)"
	@cd $(rootfs_TMP); sudo tar czf $(rootfs_CUSTOM) .
	#sudo rm -rf $(rootfs_TMP)

rootfs-custom: $(rootfs_CUSTOM)
rootfs_base-snapshot:
	if [ -e $(PRESEEDDIR)/rootfs_base.tgz ]; then rm $(PRESEEDDIR)/rootfs_base.tgz; fi
	if [ -e $(debootstrap_BASE_TGZ) ]; then \
		cp -rf $(debootstrap_BASE_TGZ)  $(PRESEEDDIR)/rootfs_base.tgz ; \
	else \
		echo "rootfs_base.tgz not available. Try make rootfs."; \
	fi;


rootfs-info:
	@echo "rootfs_PACKAGES = $(rootfs_PACKAGES)"

rootfs-custom-clean:
	if [ -d $(rootfs_TMP) ]; then \
	  sudo umount -f $(rootfs_TMP)/dev $(rootfs_TMP)/proc || true; \
	  sudo rm -rf $(rootfs_TMP); \
	fi
	rm -f  $(rootfs_CUSTOM)

.PHONY: rootfs-custom rootfs-custom-clean
endif

$(eval $(call package-builder,rootfs))

endif

rootfs-mainhelp  rootfs-help:
	@echo "rootfs: Build Root filesystem including kernel"
	@echo "rootfs_base-snapshot: Copy minimal rootfs to preseed directory"


TARGETS_HELP+=rootfs-mainhelp rootfs-mainhelp

.phony: rootfs-mainhelp

