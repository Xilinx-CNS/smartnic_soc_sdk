#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
ifeq ($(SNIC_FIRMWARE_QORIQ),y)

QORIQ_RES:=$(BUILDDIR)/firmware/qoriq
QORIQ_BUILD:=$(QORIQ_RES)/$(QORIQ_TAG)
QORIQ_CONFDIR=$(PACKAGEDIR)/firmware/nxp
SDK_VER_BIN=$(sdk_version_BUILDDIR)/version.bin

QORIQ_REPO=https://source.codeaurora.org/external/qoriq/qoriq-components
NXP_GITHUB_REPO=https://github.com/nxp

REPOS:=

ifeq ($(SNIC_FIRMWARE_QORIQ_RCW),y)
REPOS+=rcw

rcw_REPO_GIT=y
rcw_REPO=https://source.codeaurora.org/external/qoriq/qoriq-components
rcw_REPO_NAME=rcw

rcw_VER:=$(QORIQ_TAG)
rcw_BUILDDIR=$(QORIQ_BUILD)/rcw
rcw_CHECKOUT:=$(QORIQ_TAG)
ifeq ($(QORIQ_TAG),LSDK-20.04)
rcw_CHECKOUT:=$(rcw_CHECKOUT)-update-290520
endif

rcw_MAKESCRIPT=$(MAKE)
rcw_CONFDIR=$(PACKAGEDIR)/firmware/nxp
rcw_PATCHES=rcw/patches

ifeq ($(BOARD),lx2160ayrk)
rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2160ayrk/LLLL_NNNN_PPPP_PPPP_NNNN_NNNN_RR_20_2_0/rcw_2000_800_2600_20_2_0.bin
rcw_IMAGES=$(rcw_XSPI_BIN)
endif

ifeq ($(BOARD),lx2160ardb)
ifeq ($(SNIC_FIRMWARE_QORIQ_RCW_REV2),y)
rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2160ardb_rev2/XGGFF_PP_HHHH_RR_19_5_2/rcw_2000_700_2900_19_5_2.bin
else
rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2160ardb/XGGFF_PP_HHHH_RR_19_5_2/rcw_2000_700_2900_19_5_2.bin
endif
rcw_IMAGES=$(rcw_XSPI_BIN)
endif

ifeq ($(BOARD),lx2162au26z)
# OLD
#rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2162au26z/NNNN_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_800_2900_0_2.bin
#rcw_SD_BIN=$(rcw_BUILDDIR)/lx2162au26z/GGGG_NNNN_PPPP_PPPP_RR_17_2/rcw_2000_700_2900_17_2_sd.bin

# OPTION #1
#rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2162au26z/GGGG_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_700_2900_17_2.bin
#rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2162au26z/GGGG_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_800_2900_17_2.bin
#rcw_SD_BIN=$(rcw_BUILDDIR)/lx2162au26z/GGGG_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_700_2900_17_2_sd.bin

# OPTION #2
ifeq ($(SNIC_FIRMWARE_25G_ENABLE),y)
rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2162au26z/GGGG_NNNN_PPPP_PPPP_RR_17_2/rcw_2000_650_2900_17_2.bin
else
rcw_XSPI_BIN=$(rcw_BUILDDIR)/lx2162au26z/NNNN_NNNN_PPPP_PPPP_RR_0_2/rcw_2000_600_2900_0_2.bin
endif

rcw_IMAGES=$(rcw_XSPI_BIN)
endif

rcw-dist:
endif

firmware-rcw-rebuild:
	rm -f $(rcw_IMAGES)
	rm -f $(rcw_TARGETS)
	rm -f $(rcw_BUILD_STAMP)
	make rcw

.PHONY: firmware-rcw-rebuild

ifeq ($(SNIC_FIRMWARE_QORIQ_ATF),y)
REPOS+=atf
atf_REPO_GIT=y
atf_REPO=$(QORIQ_REPO)
atf_REPO_NAME=atf
atf_VER:=$(QORIQ_TAG)
atf_BUILDDIR=$(QORIQ_BUILD)/atf
atf_CHECKOUT:=$(QORIQ_TAG)
ifeq ($(QORIQ_TAG),LSDK-20.04)
atf_CHECKOUT:=$(atf_CHECKOUT)-update-290520
endif
atf_CONFDIR=$(PACKAGEDIR)/firmware/nxp
atf_PATCHES=atf/patches
atf_MAKESCRIPT=echo ATF will be invoked elsewhere
atf_FIP_DDR=fip_ddr
ifeq ($(SNIC_LX2160ARDB),y)
atf_PLATFORM=lx2160ardb
endif
ifeq ($(SNIC_LX2162AU26Z),y)
atf_PLATFORM=lx2162au26z
endif
atf_config_hook1=echo atf config hook has been run
atf_config_hook2=echo another atf config hook has been run
atf_CONFIG_HOOKS=atf_config_hook1 atf_config_hook2
ifeq ($(SNIC_FIRMWARE_QORIQ_ATF_DEBUG),y)
atf_OUTPUT_DIR=debug
atf_DEBUG=DEBUG=1
else
atf_OUTPUT_DIR=release
endif
atf-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_CORTINA),y)
REPOS+=cortina
cortina_REPO=$(NXP_GITHUB_REPO)/qoriq-firmware-cortina.git
cortina_DIR=qoriq-firmware-cortina
cortina-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_PFE),y)
REPOS+=pfe
pfe_REPO=$(NXP_GITHUB_REPO)/qoriq-engine-pfe-bin.git
pfe_DIR=qoriq-engine-pfe-bin
pfe-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_DDR),y)
REPOS+=ddr
ddr_REPO_GIT=y
ddr_REPO=$(NXP_GITHUB_REPO)
ddr_REPO_NAME=ddr-phy-binary
ddr_REPO_DOWNLOAD=ddr-phy-binary.git
ddr_BUILDDIR=$(QORIQ_BUILD)/ddr-phy-binary
ddr_MAKESCRIPT=echo Downloaded
ddr_VER:=$(QORIQ_TAG)
ddr_CHECKOUT:=$(QORIQ_TAG)
ifeq ($(QORIQ_TAG),LSDK-20.04)
ddr_CHECKOUT:=$(ddr_CHECKOUT)-update-290520
endif
ifeq ($(SOC),lx2162a)
# yes lx2160a directory
DDR_BIN_DIR=$(ddr_BUILDDIR)/lx2160a/
DDR_BIN=$(DDR_BIN_DIR)/fip_ddr.bin
ddr_IMAGES+=$(DDR_BIN)
endif
ifeq ($(SOC),lx2160a)
DDR_BIN_DIR=$(ddr_BUILDDIR)/lx2160a/
DDR_BIN=$(DDR_BIN_DIR)/fip_ddr.bin
ddr_IMAGES+=$(DDR_BIN)
endif
ddr-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_PHY),y)
REPOS+=phi
phi_REPO=$(NXP_GITHUB_REPO)/qoriq-firmware-inphi.git
phi_DIR=qoriq-firmware-inphi
phi-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_MC),y)
REPOS+=mc
mc_REPO_GIT=y
mc_REPO=$(NXP_GITHUB_REPO)
mc_REPO_NAME=qoriq-mc-binary
mc_VER:=$(QORIQ_TAG)
mc_REPO_DOWNLOAD=qoriq-mc-binary.git
ifeq ($(SNIC_FIRMWARE_QORIQ_MC_DEBUG),y)
mc_CHECKOUT=lx2160a-early-access-bsp0.7
else
mc_CHECKOUT=$(QORIQ_TAG)
endif

mc_BUILDDIR=$(QORIQ_BUILD)/mc
mc_MAKESCRIPT=echo Downloaded
ifeq ($(mc_CHECKOUT),LSDK-20.04)
MC_BIN=$(mc_BUILDDIR)/$(SOC)/mc_10.20.4_$(SOC).itb
endif
ifeq ($(mc_CHECKOUT),lx2162a-bsp0.2)
MC_BIN=$(mc_BUILDDIR)/lx216xa/mc_10.23.0_lx2160a.itb
endif
ifeq ($(mc_CHECKOUT),lx2162a-bsp0.4)
MC_BIN=$(mc_BUILDDIR)/lx216xa/mc_10.25.0_lx2160a.itb
endif
mc_IMAGES+=$(MC_BIN)
mc-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_MC_UTILS),y)
REPOS+=mc-utils
mc-utils_REPO_GIT=y
mc-utils_REPO=$(QORIQ_REPO)
mc-utils_REPO_NAME=mc-utils
mc-utils_VER=$(QORIQ_TAG)
ifeq ($(SNIC_FIRMWARE_QORIQ_MC_UTILS_DEBUG),y)
mc-utils_CHECKOUT=lx2160a-early-access-bsp0.7
else
mc-utils_CHECKOUT=$(QORIQ_TAG)
endif
mc-utils_BUILDDIR=$(QORIQ_BUILD)/mc-utils

mc-utils_MAKESCRIPT=(SOURCEDIR=. $(MAKE) -C config)
mc-utils_CONFDIR=$(PACKAGEDIR)/firmware/nxp
mc-utils_PATCHES=mc-utils/patches

ifeq ($(BOARD),lx2160ayrk)
DPC_BIN=$(mc-utils_BUILDDIR)/config/lx2160a/YRK/dpc-100G.dtb
DPL_BIN=$(mc-utils_BUILDDIR)/config/lx2160a/YRK/dpl-100G.dtb
endif
ifeq ($(BOARD),lx2160ardb)
DPC_BIN=$(mc-utils_BUILDDIR)/config/lx2160a/RDB/dpc-usxgmii.dtb
#DPL_BIN=$(mc-utils_BUILDDIR)/config/lx2160a/RDB/dpl-eth.19.dtb
# replace default with dual 1G version
DPL_BIN=$(mc-utils_BUILDDIR)/config/lx2160a/RDB/dpl-eth.18.dtb
endif
ifeq ($(BOARD),lx2162au26z)
ifeq ($(SNIC_FIRMWARE_25G_ENABLE),y)
DPC_BIN=$(mc-utils_BUILDDIR)/config/lx2162a/U26Z/dpc_25G.dtb
DPL_BIN=$(mc-utils_BUILDDIR)/config/lx2162a/U26Z/dpl_25G.dtb
else
DPC_BIN=$(mc-utils_BUILDDIR)/config/lx2162a/U26Z/dpc_1G.dtb
DPL_BIN=$(mc-utils_BUILDDIR)/config/lx2162a/U26Z/dpl_1G.dtb
endif
endif
mc-utils_IMAGES+=$(DPC_BIN) $(DPL_BIN)

mc-utils-dist:
endif

ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_UEFI),y)
BL33_BIN=$(UEFI_IMAGE)
else
BL33_BIN=$(u-boot_IMAGE)
endif

BL2_XSPI_PBL=$(QORIQ_BUILD)/bl2_xspi.pbl
FIP_XSPI_BIN=$(QORIQ_BUILD)/fip_xspi.bin


$(BL2_XSPI_PBL) $(FIP_XSPI_BIN): $(BL33_BIN) $(rcw_XSPI_BIN) $(DDR_BIN) $(atf_CONFIG_STAMP)
	rm -f $(ATF_BL2_XSPI_PBL) $(ATF_FIP_XSPI_BIN)
	(CROSS_COMPILE=$(CROSSNAME) $(MAKE) -C $(atf_BUILDDIR) realclean)
	cp -f $(DDR_BIN_DIR)/*.bin $(atf_BUILDDIR)
	cp -r $(ddr_BUILDDIR) $(atf_BUILDDIR)
	(CROSS_COMPILE=$(CROSSNAME) $(MAKE) $(atf_DEBUG) -C $(atf_BUILDDIR) all pbl fip $(atf_FIP_DDR) PLAT=$(atf_PLATFORM) BOOT_MODE=flexspi_nor RCW=$(rcw_XSPI_BIN) BL33=$(BL33_BIN))
	cp -f $(atf_BUILDDIR)/build/$(atf_PLATFORM)/$(atf_OUTPUT_DIR)/bl2*.pbl $(BL2_XSPI_PBL) && \
	cp -f $(atf_BUILDDIR)/build/$(atf_PLATFORM)/$(atf_OUTPUT_DIR)/fip.bin $(FIP_XSPI_BIN)

ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_IMAGES),y)

KERNEL_ITB=$(BUILDDIR)/fit/$(BOARD)_kernel_initramfs.itb
FIRMWARE_IMAGES_DIR=$(QORIQ_BUILD)/images
XSPI_IMAGE=$(QORIQ_BUILD)/images/boot_xspi.img
XSPI_IMAGE_2M=$(QORIQ_BUILD)/images/boot_xspi_2M.img

QORIQ_FIRMWARE_README_IMAGE=$(QORIQ_CONFDIR)/readme.txt

ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_IMAGES_64M),y)

$(XSPI_IMAGE): $(FIP_XSPI_BIN) $(DDR_BIN) $(MC_BIN) $(DPL_BIN) $(DPC_BIN) $(KERNEL_ITB) $(sdk_version_IMAGES)
	$(MAKE) BOOT=XSPI IMAGE=$(XSPI_IMAGE) PBL=$(BL2_XSPI_PBL) FIP=$(FIP_XSPI_BIN) DDR_BIN=$(DDR_BIN) MC_BIN=$(MC_BIN) DPL_BIN=$(DPL_BIN) DPC_BIN=$(DPC_BIN) KERNEL_ITB=$(KERNEL_ITB) -C $(QORIQ_CONFDIR) SDK_VER_BIN=$(SDK_VER_BIN)

endif

ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_IMAGES_2M),y)

$(XSPI_IMAGE_2M): $(FIP_XSPI_BIN) $(DDR_BIN) $(sdk_version_IMAGES)
	$(MAKE) BOOT=XSPI IMAGE=$(XSPI_IMAGE_2M) PBL=$(BL2_XSPI_PBL) FIP=$(FIP_XSPI_BIN) DDR_BIN=$(DDR_BIN) -C $(QORIQ_CONFDIR) SDK_VER_BIN=$(SDK_VER_BIN)
endif

REPOS+=qoriq-images
qoriq-images_BUILDDIR=$(QORIQ_BUILD)/images
ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_IMAGES_64M),y)
qoriq-images_DEPENDS+= $(XSPI_IMAGE)
endif
ifeq ($(SNIC_FIRMWARE_QORIQ_BOOT_IMAGES_2M),y)
qoriq-images_DEPENDS+= $(XSPI_IMAGE_2M)
endif
qoriq-images_clean_hook=$(MAKE) clean CLEAN_IMAGE=$(XSPI_IMAGE) -C $(QORIQ_CONFDIR) 
qoriq-images_CLEAN_HOOKS=qoriq-images_clean_hook
qoriq-images_install_hook= install -D $(XSPI_IMAGE) $(DISTRODIR)/binaries/qoriq/boot_xspi.img
qoriq-images_distclean_hook= rm -rf $(DISTRODIR)/binaries/qoriq/boot_xspi.img
qoriq-images-dist: qoriq-images
	install -D $(XSPI_IMAGE) $(DISTRODIR)/binaries/firmware/qoriq/boot_xspi.img

qoriq-images_INSTALL_HOOKS=qoriq-images_install_hook
qoriq-images_DISTCLEAN_HOOKS=qoriq-images_distclean_hook
endif

#$(foreach repo,$(REPOS),$(eval $(info package-builder,$(repo))))
$(foreach repo,$(REPOS),$(eval $(call package-builder,$(repo))))

firmware-qoriq-local: $(foreach repo,$(REPOS),$(repo))
.PHONY: firmware-qoriq-local

firmware-qoriq-clean-local: $(foreach repo,$(REPOS),$(repo)-clean)
	rm -rf $(QORIQ_BUILD)
.PHONY: firmware-qoriq-clean-local

firmware-qoriq-dist-local: firmware-qoriq-local
	install -D $(XSPI_IMAGE) $(DISTRODIR)/binaries/firmware/qoriq/boot_xspi.img
	install -D $(QORIQ_FIRMWARE_README_IMAGE) $(DISTRODIR)/binaries/firmware/qoriq/readme.txt

.PHONY: firmware-qoriq-dist-local

firmware-qoriq-config-local: $(foreach repo,$(REPOS),$(repo)-config)

firmware-qoriq-distclean-local: $(foreach repo,$(REPOS),$(repo)-distclean)
.PHONY: firmware-qoriq-distclean-local

firmware-qoriq_BUILDDIR=$(QORIQ_BUILD)/firmware
firmware-qoriq_DEPENDS=firmware-qoriq-local
firmware-qoriq_DIST_DEPENDS=firmware-qoriq-dist-local
firmware-qoriq_CLEAN_DEPENDS=firmware-qoriq-clean-local
#firmware-qoriq_CONFIG_DEPENDS=firmware-qoriq-config-local
firmware-qoriq_DISTCLEAN_DEPENDS=firmware-qoriq-distclean-local

$(eval $(call package-builder,firmware-qoriq))

firmware-qoriq-rebuild: firmware-qoriq-clean-local
	$(MAKE) firmware-qoriq

firmware-qoriq-dist: firmware-qoriq-dist-local

firmware-qoriq-distclean: firmware-qoriq-distclean-local

firmware-qoriq-config: firmware-qoriq-config-local

.PHONY: firmware-qoriq-dist firmware-qoriq-distclean

firmware-qoriq-mainhelp:
	@echo "firmware: NXP Firmware binaries RCW, PBL, BL2,BL31, DDR, MC, DPA"

firmware-qoriq-help:
	@echo "firmware: 	It build and pack pbl,rcw,bl21,b31,bl33 image into boot_XXX.img"
	@echo "          	.img can be used to flash boot device"
	@echo "           	Images available at"
	@echo " 	  	$(QORIQ_BUILD)/images"
	@echo "firmware-rcw-rebuild: To Re-build rcw binary of current target board"
 
TARGETS_HELP+=firmware-qoriq-mainhelp

endif
