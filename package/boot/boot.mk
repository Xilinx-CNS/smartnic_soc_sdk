#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/boot/boot.deps

ifeq ($(SNIC_PACKAGE_BOOT),y)

BOOT_CONF:=$(PACKAGEDIR)/boot
BOOT_BUILD:=$(BUILDDIR)/boot
BOOT_BUILD_STAMP:=$(BOOT_BUILD)/.dir.stamp
BOOT_BUILD_UBOOT:=$(BOOT_BUILD)/boot
BOOT_BUILD_UBOOT_STAMP:=$(BOOT_BUILD_UBOOT)/.dir.stamp
BOOT_BUILD_BOOT:=$(BOOT_BUILD)/rootfs-boot
BOOT_BUILD_BOOT_STAMP:=$(BOOT_BUILD_BOOT)/.dir.stamp
BOOT_BUILD_USB:=$(BOOT_BUILD)/usb
BOOT_BUILD_USB_STAMP:=$(BOOT_BUILD_USB)/.dir.stamp
BOOT_BUILD_USB_BOOT:=$(BOOT_BUILD_USB)/boot

BOOT_DTB=$(SOC).dtb

$(BOOT_BUILD_STAMP):
	if [ ! -d $(BOOT_BUILD) ]; then mkdir -p $(BOOT_BUILD); fi;
	touch $(BOOT_BUILD_STAMP)

$(BOOT_BUILD_BOOT_STAMP): $(BOOT_BUILD_STAMP)
	if [ ! -d $(BOOT_BUILD_BOOT) ]; then mkdir -p $(BOOT_BUILD_BOOT); fi;
	touch $(BOOT_BUILD_BOOT_STAMP)

$(BOOT_BUILD_USB_STAMP): $(BOOT_BUILD_STAMP)
	if [ ! -d $(BOOT_BUILD_USB) ]; then mkdir -p $(BOOT_BUILD_USB); fi;
	touch $(BOOT_BUILD_USB_STAMP)

$(BOOT_BUILD_UBOOT_STAMP): $(BOOT_BUILD_STAMP)
	if [ ! -d $(BOOT_BUILD_UBOOT) ]; then mkdir -p $(BOOT_BUILD_UBOOT); fi;
	touch $(BOOT_BUILD_UBOOT_STAMP)

BOOTS=

ifeq ($(SNIC_BOOT_MMC0),y)
MMC_INDEX:=0
BOOT_TGZ=boot_mmc0.tgz
endif
ifeq ($(SNIC_BOOT_MMC1),y)
MMC_INDEX:=1
BOOT_TGZ=boot_mmc1.tgz
endif
MMC_DEV:=mmcblk$(MMC_INDEX)

ifeq ($(SNIC_NXP),y)

BOOT_UTILITIES=$(BOOT_CONF)/nxp/utils

BOOT_CUSTOM_DIR=$(BOOT_CONF)/nxp/custom

BOOT_CUSTOM_INSTALLER=$(BOOT_CUSTOM_DIR)/installer
BOOT_CUSTOM_UPDATER=$(BOOT_CUSTOM_DIR)/updater-$(BOARD)

BOOT_BOOTSCRIPT=$(BOOT_BUILD)/$(BOARD)_boot.scr
BOOT_DEFAULT_BOOTSCRIPT=$(BOOT_BUILD)/boot.scr
BOOT_KERNEL_BOOTSCRIPT=$(BOOT_BUILD)/$(BOARD)_kernel_boot.scr
BOOT_INITRAMFS_BOOTSCRIPT=$(BOOT_BUILD)/$(BOARD)_initramfs_boot.scr

BOOT_COMPLEX_BOOTSCRIPT=$(BOOT_BUILD)/complex_boot.scr
BOOT_COMPLEX_BOOTSCRIPT_TEMPLATE=$(BOOT_CONF)/nxp/complex_boot.txt

BOOT_PART=$(MMC_INDEX):$(SNIC_BOOT_PART)
BOOT_KPART=$(MMC_INDEX):$(SNIC_BOOT_KERNPART)
BOOT_GPART=$(MMC_INDEX):$(SNIC_EFI_PART)
#BOOT_GRUB=/boot/efi/grub.efi
BOOT_DPART=$(BOOT_PART)
BOOT_KERNEL=/boot/vmlinuz
BOOT_DTB_PATH=/boot/$(BOOT_DTB)
BOOT_ROOTFS=$(MMC_DEV)$(SNIC_BOOT_ROOTFSPART)
BOOT_BOOTSCRIPT_TEMPLATE=$(BOOT_CONF)/nxp/$(BOARD)_boot.txt

endif

$(BOOT_COMPLEX_BOOTSCRIPT): $(kernel_DTB)
	cp $(BOOT_COMPLEX_BOOTSCRIPT_TEMPLATE) $(BOOT_BUILD)/tmp
	sed -i $(BOOT_BUILD)/tmp -e "s/GPART/$(subst /,\/,$(BOOT_GPART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/GRUB/$(subst /,\/,$(BOOT_GRUB))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/KPART/$(subst /,\/,$(BOOT_KPART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/DPART/$(subst /,\/,$(BOOT_DPART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ROOT/$(subst /,\/,$(BOOT_ROOTFS))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/KERNEL/$(subst /,\/,$(BOOT_KERNEL))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/KERNVER/$(subst /,\/,$(kernel_VMLINUZVER))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/DTB/$(subst /,\/,$(BOOT_DTB_PATH))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ITB/$(subst /,\/,$(FIT_INITRAMFS_ITB))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/HUGEPAGES_SIZE/$(subst /,\/,$(SNIC_BOOT_HUGEPAGES_SIZE))/g"
	sed -i $(BOOT_BUILD)/tmp -e "s/HUGEPAGES_NUM/$(subst /,\/,$(SNIC_BOOT_HUGEPAGES_NUM))/"
	mkimage -T script -C none -n "Boot Script" -d $(BOOT_BUILD)/tmp $(BOOT_COMPLEX_BOOTSCRIPT)
	rm $(BOOT_BUILD)/tmp

$(BOOT_BOOTSCRIPT):
	cp $(BOOT_BOOTSCRIPT_TEMPLATE) $(BOOT_BUILD)/tmp
	sed -i $(BOOT_BUILD)/tmp -e "s/PART/$(subst /,\/,$(BOOT_PART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ROOT/$(subst /,\/,$(BOOT_ROOTFS))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ITB/$(subst /,\/,$(FIT_ITB))/"
	mkimage -T script -C none -n "Boot Script" -d $(BOOT_BUILD)/tmp $(BOOT_BOOTSCRIPT)
	rm $(BOOT_BUILD)/tmp

$(BOOT_KERNEL_BOOTSCRIPT):
	cp $(BOOT_BOOTSCRIPT_TEMPLATE) $(BOOT_BUILD)/tmp
	sed -i $(BOOT_BUILD)/tmp -e "s/PART/$(subst /,\/,$(BOOT_PART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ROOT/$(subst /,\/,$(BOOT_ROOTFS))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ITB/$(subst /,\/,$(BOOT_KERNEL_ITB))/"
	mkimage -T script -C none -n "Boot Script" -d $(BOOT_BUILD)/tmp $(BOOT_KERNEL_BOOTSCRIPT)
	rm $(BOOT_BUILD)/tmp

$(BOOT_INITRAMFS_BOOTSCRIPT): 
	cp $(BOOT_BOOTSCRIPT_TEMPLATE) $(BOOT_BUILD)/tmp
	sed -i $(BOOT_BUILD)/tmp -e "s/PART/$(subst /,\/,$(BOOT_PART))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ROOT/$(subst /,\/,$(BOOT_ROOTFS))/"
	sed -i $(BOOT_BUILD)/tmp -e "s/ITB/$(subst /,\/,$(FIT_INITRAMFS_ITB))/"
	mkimage -T script -C none -n "Boot Script" -d $(BOOT_BUILD)/tmp $(BOOT_INITRAMFS_BOOTSCRIPT)
	rm $(BOOT_BUILD)/tmp

ifeq ($(SNIC_BOOT_FIT_KERNEL),y)
ifeq ($(SNIC_FIT_KERNEL_ONLY),y)
BOOTS+=$(BOOT_KERNEL_BOOTSCRIPT) $(FIT_BUILD)/$(FIT_ITB)
endif

ifeq ($(SNIC_FIT_KERNEL_INITRAMFS),y)
BOOTS+=$(BOOT_INITRAMFS_BOOTSCRIPT) $(FIT_BUILD)/$(FIT_INITRAMFS_ITB)
endif

ifeq ($(SNIC_FIT_KERNEL_INITRD),y)
BOOTS+=$(BOOT_BOOTSCRIPT) $(FIT_BUILD)/$(FIT_INITRD_ITB)
endif
endif

ifeq ($(SNIC_BOOT_COMPLEX),y)
BOOTS+=$(BOOT_COMPLEX_BOOTSCRIPT)
endif

ifeq ($(SNIC_BOOT_CUSTOM_INSTALLER_ROOTFS),y)
BOOTS+= $(rootfs_CUSTOM)
endif

boot: $(BOOT_BUILD_STAMP) $(BOOT_BUILD_BOOT_STAMP) $(BOOT_BUILD_UBOOT_STAMP) $(BOOT_BUILD_USB_STAMP) $(foreach f,$(BOOTS),$(f))
#boot: $(BOOT_BUILD) $(BOOT_BUILD_BOOT) $(BOOT_BUILD_UBOOT) $(BOOTS)
	@echo "Done with $(BOOTS)"

ifeq ($(SNIC_PACKAGE_BOOT),y)

	rm -rf $(BOOT_BUILD_BOOT)
	mkdir -p $(BOOT_BUILD_BOOT)
	rm -rf $(BOOT_BUILD_UBOOT)
	mkdir -p $(BOOT_BUILD_UBOOT)
	rm -rf $(BOOT_BUILD_USB_BOOT)
	mkdir -p $(BOOT_BUILD_USB_BOOT)

	ln $(FIRMWARE_IMAGES_DIR)/boot_xspi.img $(BOOT_BUILD_USB_BOOT)/
	ln $(FIRMWARE_IMAGES_DIR)/boot_xspi_2M.img $(BOOT_BUILD_USB_BOOT)/
	ln $(BOOT_CONF)/README $(BOOT_BUILD_USB_BOOT)/
	ln $(FIT_BUILD)/$(FIT_INITRAMFS_ITB) $(BOOT_BUILD_USB_BOOT)/$(FIT_INITRAMFS_ITB)
	cp $(kernel_DTB) $(BOOT_BUILD_UBOOT)/$(notdir $(kernel_DTB))
	rm -f $(BOOT_BUILD_UBOOT)/$(BOOT_DTB)
	(cd $(BOOT_BUILD_UBOOT); ln -s $(notdir $(kernel_DTB)) $(BOOT_DTB))

ifeq ($(SNIC_BOOT_FIT_KERNEL),y)
ifeq ($(SNIC_FIT_KERNEL_ONLY),y)
	cp $(FIT_BUILD)/$(FIT_KERNEL_ITB) $(BOOT_BUILD_UBOOT)/$(FIT_KERNEL_ITB)
#	cp $(FIT_BUILD)/$(FIT_KERNEL_ITB) $(BOOT_BUILD_BOOT)/vmlinuz.fit
	cp $(BOOT_KERNEL_BOOTSCRIPT) $(BOOT_BUILD_UBOOT)/$(notdir $(BOOT_KERNEL_BOOTSCRIPT))
ifeq ($(SNIC_BOOT_KERNEL_ONLY_LINK),y)
	(cd $(BOOT_BUILD_UBOOT); ln -s $(notdir $(BOOT_KERNEL_BOOTSCRIPT)) $(notdir $(BOOT_BOOTSCRIPT)))
endif
endif

ifeq ($(SNIC_FIT_KERNEL_INITRAMFS),y)
	cp $(FIT_BUILD)/$(FIT_INITRAMFS_ITB) $(BOOT_BUILD_UBOOT)/$(FIT_INITRAMFS_ITB)
	cp $(BOOT_INITRAMFS_BOOTSCRIPT) $(BOOT_BUILD_UBOOT)/$(notdir $(BOOT_INITRAMFS_BOOTSCRIPT))
ifeq ($(SNIC_BOOT_KERNEL_INITRAMFS_LINK),y)
	(cd $(BOOT_BUILD_UBOOT); ln -s $(notdir $(BOOT_INITRAMFS_BOOTSCRIPT)) $(notdir $(BOOT_BOOTSCRIPT)))
endif
endif

ifeq ($(SNIC_FIT_KERNEL_INITRD),y)
	cp $(FIT_BUILD)/$(FIT_ITB) $(BOOT_BUILD_UBOOT)/$(FIT_ITB)
ifeq ($(SNIC_BOOT_KERNEL_INITRD_LINK),y)
	cp $(BOOT_BOOTSCRIPT) $(BOOT_BUILD_UBOOT)/$(notdir $(BOOT_BOOTSCRIPT))
endif
endif
endif

ifeq ($(SNIC_BOOT_COMPLEX),y)
	cp $(BOOT_COMPLEX_BOOTSCRIPT) $(BOOT_BUILD_UBOOT)/$(notdir $(BOOT_COMPLEX_BOOTSCRIPT))
	ln $(BOOT_COMPLEX_BOOTSCRIPT) $(BOOT_BUILD_USB_BOOT)/boot.scr

ifeq ($(SNIC_BOOT_COMPLEX_LINK),y)
	(cd $(BOOT_BUILD_UBOOT); ln -s $(notdir $(BOOT_COMPLEX_BOOTSCRIPT)) $(notdir $(BOOT_BOOTSCRIPT)))
endif
endif

	# add default bootscript
	ln -s $(notdir $(BOOT_BOOTSCRIPT)) $(BOOT_BUILD_UBOOT)/$(notdir $(BOOT_DEFAULT_BOOTSCRIPT))

ifeq ($(SNIC_BOOT_CUSTOM_INSTALLER),y)
	cp -r $(BOOT_CUSTOM_INSTALLER)/* $(BOOT_BUILD)
ifeq ($(SNIC_BOOT_CUSTOM_INSTALLER_ROOTFS),y)
	ln -f $(rootfs_CUSTOM) $(BOOT_BUILD)/data/rootfs.tgz
endif
endif

ifeq ($(SNIC_BOOT_CUSTOM_UPDATER),y)
	cp -r $(BOOT_CUSTOM_UPDATER)/* $(BOOT_BUILD)
ifeq ($(SNIC_BOOT_CUSTOM_UPDATER_IMGS),y)
	cp -r $(FIRMWARE_IMAGES_DIR)/* $(BOOT_BUILD)/data/
endif
endif

ifeq ($(SNIC_BOOT_PARTITION_UTILITIES),y)
	cp -r $(BOOT_UTILITIES)/* $(BOOT_BUILD)
	rm $(BOOT_BUILD)/Config.in
endif
endif
ifeq ($(SNIC_ROOTFS_DEB_SOURCES),y)
	ln -f $(rootfs_BUILDDIR)/$(rootfs_CUSTOM_NAME).sources.tgz $(BOOT_BUILD)/rootfs.source.tgz
endif
	cd $(BOOT_BUILD); rm -f $(BOOT_TGZ); tar czf $(BOOT_TGZ) boot data maintenance
	cd $(BOOT_BUILD);ln $(BOOT_TGZ) $(BOOT_BUILD_USB_BOOT)/$(BOOT_TGZ)
	cd $(BOOT_BUILD_USB);zip -r boot.zip boot/

.PHONY: boot

boot-clean:
	rm -rf $(BOOT_BUILD)

boot-rebuild: boot-clean
	$(MAKE) boot

boot-dist: boot
ifeq ($(SNIC_PACKAGE_BOOT),y)
	rm -rf $(DISTRODIR)/binaries/boot/boot
	rm -rf $(DISTRODIR)/binaries/boot/u-boot
	mkdir -p $(DISTRODIR)/binaries/boot/boot
	mkdir -p $(DISTRODIR)/binaries/boot/u-boot
#	install -D $(BOOT_BUILD_BOOT)/* $(DISTRODIR)/binaries/boot
	cp -a $(BOOT_BUILD_UBOOT)/* $(DISTRODIR)/binaries/boot/u-boot
	(cd $(DISTRODIR)/binaries/boot; tar cvzf u-boot.tgz u-boot/*;)
ifeq ($(BOOT_BUILD_BOOT_POPULATED),y)
	cp -a $(BOOT_BUILD_BOOT)/* $(DISTRODIR)/binaries/boot/boot
	(cd $(DISTRODIR)/binaries/boot; tar cvzf boot.tgz boot/*;)
endif
endif

boot-distclean: boot-clean
	rm -rf $(DISTRODIR)/binaries/u-boot/*
	rm -rf $(DISTRODIR)/binaries/boot/*

.phony: boot-clean boot-dist boot-distclean boot-rebuild

boot-mainhelp:
	@echo "boot: Pack required images for booting"

boot-help:
	@echo "boot: Pack required images for booting"
	@echo "Available Targets:"
	@echo "boot:         Images required to boot from eMMc available at"
	@echo "              $(BOOT_BUILD)"
	@echo "              Images required to recovery boot from USB available at"
	@echo "              $(BOOT_BUILD_USB)"
	@echo "              Copy boot folder from above path to USB drive"
	@echo "boot-clean:   Delete images"

TARGETS_HELP+=boot-mainhelp

.phony: boot-help

endif



