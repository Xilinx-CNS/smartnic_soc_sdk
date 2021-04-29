#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/fit/fit.deps

ifeq ($(SNIC_PACKAGE_FIT),y)

FIT_CONF:=$(PACKAGEDIR)/fit
FIT_BUILD_STAMP:=$(BUILDDIR)/fit/.stamp
FIT_BUILD:=$(BUILDDIR)/fit
FIT_BUILD_BOOT:=$(FIT_BUILD)/boot

FIT_IMAGE:=$(kernel_ImageBoot)
ifeq ($(SNIC_KERNEL_COMPRESSED),y)
FIT_ZIMAGE:=$(kernel_zImageBoot)
FIT_ZIMAGE_INITRAMFS:=$(kernel_zImageInitrd)
else
FIT_ZIMAGE:=$(kernel_ImageBoot)
FIT_ZIMAGE_INITRAMFS:=$(kernel_ImageInitrd)
endif
FIT_INITRAMFS:=$(kinitramfs_CPIO)
FIT_INITRAMFS_GZ:=$(FIT_BUILD)/$(notdir $(FIT_INITRAMFS)).gz
FITS=$(FIT_INITRAMFS_GZ)

ifeq ($(SNIC_NXP),y)
ITS:=$(SOC).its
ITS_KERNEL:=$(SOC)-kernel.its
ITS_INITRAMFS:=$(SOC)-initramfs.its
ITS_CONF=$(FIT_CONF)/nxp

FIT_UEFI_GRUB2_DTB=/boot/$(notdir $(kernel_DTB))
FIT_UEFI_GRUB2_EFI=/EFI/BOOT/BOOTAA64.EFI

FIT_UEFI_KERNEL=/boot/Image
FIT_UEFI_KERNEL_DTB=/boot/$(notdir $(kernel_DTB))

endif


FIT_ITB=$(BOARD)_kernel.itb
FIT_KERNEL_ITB=$(BOARD)_kernel_only.itb
FIT_INITRAMFS_ITB=$(BOARD)_kernel_initramfs.itb

$(FIT_BUILD_STAMP):
	if [ ! -d $(FIT_BUILD) ]; then mkdir -p $(FIT_BUILD); fi;
	touch $(FIT_BUILD_STAMP)

$(FIT_INITRAMFS_GZ): $(FIT_BUILD_STAMP) $(FIT_INITRAMFS)
	cp -f $(FIT_INITRAMFS) $(FIT_BUILD)/$(notdir $(FIT_INITRAMFS))
	rm -f $(FIT_INITRAMFS_GZ)
	(cd $(FIT_BUILD); gzip $(notdir $(FIT_INITRAMFS)))

$(FIT_BUILD)/$(ITS_INITRAMFS): $(FIT_BUILD_STAMP) $(FIT_ZIMAGE_INITRAMFS) $(kernel_DTB-m)
	cp $(ITS_CONF)/$(ITS_INITRAMFS) $(FIT_BUILD)/$(ITS_INITRAMFS).tmp
	sed -i $(FIT_BUILD)/$(ITS_INITRAMFS).tmp -e "s/COMPRESSION/$(subst /,\/,$(FIT_KERNEL_COMPRESSION))/"
	sed -i $(FIT_BUILD)/$(ITS_INITRAMFS).tmp -e "s/ZIMAGE_INITRAMFS/$(subst /,\/,$(FIT_ZIMAGE_INITRAMFS))/"
	sed -i $(FIT_BUILD)/$(ITS_INITRAMFS).tmp -e "s/DTB/$(subst /,\/,$(kernel_DTB-m))/"
	sed -i $(FIT_BUILD)/$(ITS_INITRAMFS).tmp -e "s/BOARD/$(subst /,\/,$(BOARD))/g"
	rm -f $(FIT_BUILD)/$(ITS_INITRAMFS)
	mv $(FIT_BUILD)/$(ITS_INITRAMFS).tmp $(FIT_BUILD)/$(ITS_INITRAMFS)

$(FIT_BUILD)/$(ITS_KERNEL): $(FIT_BUILD_STAMP) $(FIT_ZIMAGE) $(kernel_DTB-m)
	cp $(ITS_CONF)/$(ITS_KERNEL) $(FIT_BUILD)/$(ITS_KERNEL).tmp
	sed -i $(FIT_BUILD)/$(ITS_KERNEL).tmp -e "s/COMPRESSION/$(subst /,\/,$(FIT_KERNEL_COMPRESSION))/"
	sed -i $(FIT_BUILD)/$(ITS_KERNEL).tmp -e "s/ZIMAGE/$(subst /,\/,$(FIT_ZIMAGE))/"
	sed -i $(FIT_BUILD)/$(ITS_KERNEL).tmp -e "s/DTB/$(subst /,\/,$(kernel_DTB-m))/"
	sed -i $(FIT_BUILD)/$(ITS_KERNEL).tmp -e "s/BOARD/$(subst /,\/,$(BOARD))/g"
	rm -f $(FIT_BUILD)/$(ITS_KERNEL)
	mv $(FIT_BUILD)/$(ITS_KERNEL).tmp $(FIT_BUILD)/$(ITS_KERNEL)

$(FIT_BUILD)/$(ITS): $(FIT_BUILD_STAMP) $(FIT_ZIMAGE) $(FIT_INITRAMFS_GZ) $(kernel_DTB-m)
	cp $(ITS_CONF)/$(ITS) $(FIT_BUILD)/$(ITS).tmp
	sed -i $(FIT_BUILD)/$(ITS).tmp -e "s/COMPRESSION/$(subst /,\/,$(FIT_KERNEL_COMPRESSION))/"
	sed -i $(FIT_BUILD)/$(ITS).tmp -e "s/ZIMAGE/$(subst /,\/,$(FIT_ZIMAGE))/"
	sed -i $(FIT_BUILD)/$(ITS).tmp -e "s/INITRD/$(subst /,\/,$(FIT_INITRAMFS_GZ))/"
	sed -i $(FIT_BUILD)/$(ITS).tmp -e "s/DTB/$(subst /,\/,$(kernel_DTB-m))/"
	sed -i $(FIT_BUILD)/$(ITS).tmp -e "s/BOARD/$(subst /,\/,$(BOARD))/g"
	rm -f $(FIT_BUILD)/$(ITS)
	mv $(FIT_BUILD)/$(ITS).tmp $(FIT_BUILD)/$(ITS)

$(FIT_BUILD)/$(FIT_ITB) : $(FIT_BUILD)/$(ITS)
	(pwd && mkimage -f $(FIT_BUILD)/$(ITS) $(FIT_BUILD)/$(FIT_ITB))

$(FIT_BUILD)/$(FIT_KERNEL_ITB): $(FIT_BUILD)/$(ITS_KERNEL)
	(pwd && mkimage -f $(FIT_BUILD)/$(ITS_KERNEL) $(FIT_BUILD)/$(FIT_KERNEL_ITB))

$(FIT_BUILD)/$(FIT_INITRAMFS_ITB): $(FIT_BUILD)/$(ITS_INITRAMFS)
	(pwd && mkimage -f $(FIT_BUILD)/$(ITS_INITRAMFS) $(FIT_BUILD)/$(FIT_INITRAMFS_ITB))

ifeq ($(SNIC_FIT_KERNEL_INITRAMFS),y)
FITS+=$(FIT_BUILD)/$(FIT_INITRAMFS_ITB)
endif

ifeq ($(SNIC_FIT_EXTRA_KERNEL_INITRAMFS),y)
FITS+=$(FIT_BUILD)/$(FIT_INITRAMFS_ITB)
endif

ifeq ($(SNIC_FIT_KERNEL_ONLY),y)
FITS+=$(FIT_BUILD)/$(FIT_KERNEL_ITB)
endif


ifeq ($(SNIC_FIT_KERNEL_INITRD),y)
FITS+=$(FIT_BUILD)/$(FIT_ITB)
endif

ifeq ($(SNIC_FIT_KERNEL_CMDLINE_IGNORE_LPI_DISABLE_FAILURE),y)
FIT_CMDLINE+=irqchip.gicv3_lpi_disable_override=1
endif

fit: $(FITS)
	@echo "Done with $(FITS)"

TARGETS+=fit

.PHONY: fit

fit-clean:
	rm -rf $(FIT_BUILD)

fit-rebuild: fit-clean
	$(MAKE) fit

fit-dist: fit
ifeq ($(SNIC_PACKAGE_FIT_BOOT),y)
	rm -rf $(DISTRODIR)/binaries/fit/boot
	mkdir -p $(DISTRODIR)/binaries/fit/boot
#	install -D $(FIT_BUILD_BOOT)/* $(DISTRODIR)/binaries/fit/$(SOC)/boot/
	cp -a $(FIT_BUILD_BOOT)/* $(DISTRODIR)/binaries/fit/boot
	(cd $(DISTRODIR)/binaries/fit; tar cvzf boot.tgz boot/*;)
endif

fit-distclean: fit-clean
	rm -rf $(DISTRODIR)/binaries/fit/*

.phony: fit-clean fit-dist fit-distclean fit-rebuild

endif



