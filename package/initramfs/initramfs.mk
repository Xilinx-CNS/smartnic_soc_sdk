#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
-include $(PACKAGEDIR)/initramfs/initramfs.deps

ifeq ($(SNIC_INITRAMFS_BUILDROOT),y)
initramfs_CPIO_SRC=$(buildroot_ROOTFS_CPIO)
else
initramfs_CPIO_SRC=$(SNIC_INITRAMFS_PATH)
endif

initramfs_BUILDDIR:=$(BUILDDIR)/initramfs
#initramfs_CONFDIR:=$(initramfs_PACKAGDIR)/$(initramfs_VER)

initramfs_VER=v0.1

initramfs_CPIO=$(initramfs_BUILDDIR)/rootfs.$(ARCH).cpio

#initramfs_CONFDIR=$(PACKAGEDIR)/initramfs
#initramfs_SRC=$(initramfs_CONFDIR)/$(initramfs_VER)
initramfs_PACKAGEDIR=$(PACKAGEDIR)/initramfs
initramfs_SRC=$(initramfs_PACKAGEDIR)/$(initramfs_VER)

initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(VARIANT)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(VARIANT)$(SUBVARIANT)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(SOC)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(SOC)
endif
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(BOARD)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(BOARD)
endif
ifneq ($(wildcard $(iniramfs_CONFDIR)/S99custom-$(BOARD)$(VARIANT)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(BOARD)$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(BOARD)$(VARIANT)$(SUBVARIANT)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(BOARD)$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/S99custom-$(CUSTOM_INITRD)),)
initramfs_S99CUSTOM=$(initramfs_SRC)/S99custom-$(CUSTOM_INITRD)
endif

initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(VARIANT)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(VARIANT)$(SUBVARIANT)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(SOC)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(SOC)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(BOARD)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(BOARD)
endif
ifneq ($(wildcard $(iniramfs_CONFDIR)/custom_init-$(BOARD)$(VARIANT)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(BOARD)$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(BOARD)$(VARIANT)$(SUBVARIANT)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(BOARD)$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom_init-$(CUSTOM_INITRD)),)
initramfs_CUSTOM_INIT=$(initramfs_SRC)/custom_init-$(CUSTOM_INITRD)
endif

initramfs_CUSTOM=$(initramfs_SRC)/custom
ifneq ($(wildcard $(initramfs_SRC)/custom-$(VARIANT)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom-$(VARIANT)$(SUBVARIANT)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom-$(SOC)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(SOC)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom-$(BOARD)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(BOARD)
endif
ifneq ($(wildcard $(iniramfs_CONFDIR)/custom-$(BOARD)$(VARIANT)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(BOARD)$(VARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom-$(BOARD)$(VARIANT)$(SUBVARIANT)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(BOARD)$(VARIANT)$(SUBVARIANT)
endif
ifneq ($(wildcard $(initramfs_SRC)/custom-$(CUSTOM_INITRD)),)
initramfs_CUSTOM=$(initramfs_SRC)/custom-$(CUSTOM_INITRD)
endif
initramfs_WC=$(wildcard $(initramfs_SRC)/custom-$(SOC))

initramfs_UPDATE_JSON_FILE:=update-system.json
initramfs_UPDATE_JSON=$(initramfs_BUILDDIR)/$(initramfs_UPDATE_JSON_FILE)
initramfs_nw_file=$(initramfs_BUILDDIR)/interfaces

$(initramfs_UPDATE_JSON): 
	make $(initramfs_CONFIG_STAMP)
	cp $(initramfs_SRC)/$(initramfs_UPDATE_JSON_FILE) $(initramfs_UPDATE_JSON)
	sed -i $(initramfs_UPDATE_JSON) -e 's/SERVER/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_SERVER))/'
	sed -i $(initramfs_UPDATE_JSON) -e 's/TRANSPORT/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_TRANSPORT))/'
	sed -i $(initramfs_UPDATE_JSON) -e 's/USER/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_USER))/'
	sed -i $(initramfs_UPDATE_JSON) -e 's/PORT/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_PORT))/'
	sed -i $(initramfs_UPDATE_JSON) -e 's/DIR/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_DIR))/'
	sed -i $(initramfs_UPDATE_JSON) -e 's/FILE/$(subst /,\/,$(SNIC_INITRAMFS_CONFIG_FILE))/'
	chmod 666 $(initramfs_UPDATE_JSON)

ifeq ($(SNIC_INITRAMFS_CONFIG),y)
initramfs_ETC:=$(initramfs_UPDATE_JSON)
else
initramfs_ETC:=
endif

interface=enp1s0f0

$(initramfs_nw_file):
	@mkdir -p $(initramfs_BUILDDIR)/

ifeq ($(SNIC_INITRAMFS_MANUAL),y)
	@echo "iface $(interface) inet manual" > $(initramfs_BUILDDIR)/interfaces
endif
ifeq ($(SNIC_INITRAMFS_DHCP),y)
	@echo "auto $(interface)" > $(initramfs_BUILDDIR)/interfaces
	@echo "iface $(interface) inet dhcp" >> $(initramfs_BUILDDIR)/interfaces
endif	
ifeq ($(SNIC_INITRAMFS_STATIC),y)
	@echo "auto $(interface)" > $(initramfs_BUILDDIR)/interfaces
	@echo "iface $(interface) inet static" >> $(initramfs_BUILDDIR)/interfaces
	@echo "        address $(SNIC_INITRAMFS_STATIC_IP)" >> $(initramfs_BUILDDIR)/interfaces
	@echo "        netmask $(SNIC_INITRAMFS_STATIC_SUBNET)" >> $(initramfs_BUILDDIR)/interfaces
endif	
	@echo "auto usb0" >> $(initramfs_BUILDDIR)/interfaces
	@echo "iface usb0 inet dhcp" >> $(initramfs_BUILDDIR)/interfaces

$(initramfs_CPIO): $(initramfs_CPIO_SRC) $(initramfs_ETC)  $(initramfs_UPDATE_JSON) $(initramfs_nw_file)
	rm -rf fakeme
	rm -rf temp
	mkdir temp
	@echo "SOC is $(SOC)"
	@echo "BOARD is $(BOARD)"
	@echo "initramfs_SRC is $(initramfs_SRC)"
	@echo "initramfs_WC is $(initramfs_WC)"
	@echo "initramfs_SRC/custom-SOC is $(initramfs_SRC)/custom-$(SOC)"
	@echo "initramfs_CUSTOM is $(initramfs_CUSTOM)"
	@echo "initramfs_S99CUSTOM is $(initramfs_S99CUSTOM)"
	@echo "initramfs_CUSTOM_INIT is $(initramfs_CUSTOM_INIT)"
	@echo "wildcard(initramfs_SRC/custom-SOC is) $(wildcard $(initramfs_SRC)/custom-$(SOC))"
ifneq ($(wildcard $(initramfs_SRC)/custom-$(SOC)),)
	@echo "GOTIT!!"
endif
	@echo "initramfs_CUSTOM is $(initramfs_CUSTOM)"
	@echo "initramfs_CUSTOM_INIT is $(initramfs_CUSTOM_INIT)"
	@echo "initramfs_S99CUSTOM is $(initramfs_S99CUSTOM)"

# assume that everyone needs S99custom, init, setup and ubisetup
# so copy the defaults if variants are not present
	echo "\
	cd temp; \
	cpio -i -d -H newc -F $(initramfs_CPIO_SRC) --no-absolute-filenames; \
	if [ ! -z $(initramfs_ETC) ]; then cp $(initramfs_ETC) etc/; fi; \
	cp $(initramfs_S99CUSTOM) etc/init.d/S99custom ; \
	chmod +x etc/init.d/S99custom; \
	chown -R root:root etc/init.d/S99custom; \
	rm init; \
	cp $(initramfs_CUSTOM_INIT) init ; \
	chmod +x init; \
	chown -R root:root init; \
	cp -r $(initramfs_CUSTOM)/* .; \
	if [ -f $(initramfs_SRC)/setup$(VARIANT) ]; then \
		cp $(initramfs_SRC)/setup$(VARIANT) usr/bin/setup; \
	else \
		cp $(initramfs_SRC)/setup usr/bin/setup; \
	fi ; \
	chmod +x usr/bin/setup; \
	chown -R root:root usr/bin/setup; \
	cp $(initramfs_nw_file) etc/network/interfaces ; \
	find . | cpio -o -H newc  > $(initramfs_CPIO)" >> fakeme;
	chmod +x fakeme
	fakeroot ./fakeme
	rm -rf temp
	rm -rf fakeme

initramfs_TARGETS:=$(initramfs_CPIO)

$(eval $(call package-builder,initramfs))

initramfs-help:
	@echo "initramfs: 	Pack initramfs with custom tools and configuration"
	@echo "initramfs-clean: Clean intramfs build files"
initramfs-mainhelp :
	@echo "initramfs: Pack initramfs with custom tools and configuration"
	
TARGETS_HELP+=initramfs-mainhelp

.phony: u-boot-help
