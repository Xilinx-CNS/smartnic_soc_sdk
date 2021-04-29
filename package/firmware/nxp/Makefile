#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
# create image file

#FIP_OFFSET=0x00100000
#200000
#NXP recommend 0x00800000 for DDR offset.We set it to reduce flash image size.
#above offset is part of U-boot image in NXP docs.
#DDR_OFFSET=0x00200000
#MC_OFFSET =0x00a00000
#DPL_OFFSET=0x00d00000
#DPC_OFFSET=0x00e00000
#DTB_OFFSET=0x00f00000
#KERNEL_OFFSET=0x01000000
#RAMFS_OFFSET=0x2000000

FIP_OFFSET=1048576
FW_VER_OFFSET=2096128
DDR_OFFSET=2097152
MC_OFFSET=10485760
DPL_OFFSET=13631488
DPC_OFFSET=14680064
DTB_OFFSET=15728640
KERNEL_OFFSET=16777216
RAMFS_OFFSET=33554432

SD_BS=512
SD_RCW_OFFSET=4096
SD_PBL_OFFSET=$(SD_RCW_OFFSET)
SD_PBL_SEEK=$(shell echo $(SD_PBL_OFFSET) \/ $(SD_BS) | bc)
SD_FIP_SEEK=$(shell echo $(FIP_OFFSET) \/ $(SD_BS) | bc)
SD_DDR_SEEK=$(shell echo $(DDR_OFFSET) \/ $(SD_BS) | bc)
SD_MC_SEEK=$(shell echo $(MC_OFFSET) \/ $(SD_BS) | bc)
SD_DPL_SEEK=$(shell echo $(DPL_OFFSET) \/ $(SD_BS) | bc)
SD_DPC_SEEK=$(shell echo $(DPC_OFFSET) \/ $(SD_BS) | bc)
SD_DTB_SEEK=$(shell echo $(DTB_OFFSET) \/ $(SD_BS) | bc)
SD_KERNEL_SEEK=$(shell echo $(KERNEL_OFFSET) \/ $(SD_BS) | bc)
SD_KERNEL_MAX=41943040
SD_KERNEL_COUNT=$(shell echo $(SD_KERNEL_MAX) \/ $(SD_BS) | bc)

NOR_BS=1024
NOR_RCW_OFFSET=0
NOR_PBL_OFFSET=$(NOR_RCW_OFFSET)
NOR_PBL_SEEK=$(shell echo $(XSPI_PBL_OFFSET) \/ $(NOR_BS) | bc)
NOR_FIP_SEEK=$(shell echo $(FIP_OFFSET) \/ $(NOR_BS) | bc)
NOR_DDR_SEEK=$(shell echo $(DDR_OFFSET) \/ $(NOR_BS) | bc)
NOR_MC_SEEK=$(shell echo $(MC_OFFSET) \/ $(NOR_BS) | bc)
NOR_DPL_SEEK=$(shell echo $(DPL_OFFSET) \/ $(NOR_BS) | bc)
NOR_DPC_SEEK=$(shell echo $(DPC_OFFSET) \/ $(NOR_BS) | bc)
NOR_DTB_SEEK=$(shell echo $(DTB_OFFSET) \/ $(NOR_BS) | bc)
NOR_KERNEL_SEEK=$(shell echo $(KERNEL_OFFSET) \/ $(NOR_BS) | bc)

XSPI_BS=1024
XSPI_RCW_OFFSET=0
XSPI_PBL_OFFSET=$(XSPI_RCW_OFFSET)
XSPI_PBL_SEEK=$(shell echo $(XSPI_PBL_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_FIP_SEEK=$(shell echo $(FIP_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_FW_VER_SEEK=$(shell echo $(FW_VER_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_DDR_SEEK=$(shell echo $(DDR_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_MC_SEEK=$(shell echo $(MC_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_DPL_SEEK=$(shell echo $(DPL_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_DPC_SEEK=$(shell echo $(DPC_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_DTB_SEEK=$(shell echo $(DTB_OFFSET) \/ $(XSPI_BS) | bc)
XSPI_KERNEL_SEEK=$(shell echo $(KERNEL_OFFSET) \/ $(XSPI_BS) | bc)


BS=$($(BOOT)_BS)
PBL_SEEK=$($(BOOT)_PBL_SEEK)
FIP_SEEK=$($(BOOT)_FIP_SEEK)
FW_VER_SEEK=$($(BOOT)_FW_VER_SEEK)
DDR_SEEK=$($(BOOT)_DDR_SEEK)
MC_SEEK=$($(BOOT)_MC_SEEK)
DPL_SEEK=$($(BOOT)_DPL_SEEK)
DPC_SEEK=$($(BOOT)_DPC_SEEK)
DTB_SEEK=$($(BOOT)_DTB_SEEK)
KERNEL_SEEK=$($(BOOT)_KERNEL_SEEK)

$(IMAGE):
	mkdir -p $(dir $(IMAGE))
	rm -f $(IMAGE)
	# startwith rcw and pbl merged code
	dd if=$(PBL) of=$(IMAGE) bs=$(BS) seek=$(PBL_SEEK)
	# add in bootloader wrapped in a fip
	dd if=$(FIP) of=$(IMAGE) bs=$(BS) seek=$(FIP_SEEK)
	# add FW version
	if [ "X$(SDK_VER_BIN)" = "X" ]; then \
		echo "Skipping Firmware version binary"; \
	else \
		dd if=$(SDK_VER_BIN) of=$(IMAGE) bs=$(BS) seek=$(FW_VER_SEEK); \
	fi
	# add bootloader environment
	# add secure headers
	# add ddr phy
	dd if=$(DDR_BIN) of=$(IMAGE) bs=$(BS) seek=$(DDR_SEEK)
	# add fuse provisioning
	# fman ucode??
	# ethernet phy fw
	# flashing image script
	# dpaa2 mc fw
	if [ "X$(MC_BIN)" = "X" ]; then \
		echo "Skipping MC image"; \
	else \
		dd if=$(MC_BIN) of=$(IMAGE) bs=$(BS) seek=$(MC_SEEK); \
	fi
	# dpaa2 dpl fw
	if [ "X$(DPL_BIN)" = "X" ]; then \
		echo "Skipping DPL image"; \
	else \
		dd if=$(DPL_BIN) of=$(IMAGE) bs=$(BS) seek=$(DPL_SEEK); \
	fi
	# dpaa2 dpc fw
	if [ "X$(DPC_BIN)" = "X" ]; then \
	    	echo "Skipping DPC image"; \
	else \
		dd if=$(DPC_BIN) of=$(IMAGE) bs=$(BS) seek=$(DPC_SEEK); \
	fi
	# device tree
	if [ "X$(DTB)" = "X" ]; then \
	echo "Skipping dtb image"; \
	else \
		dd if=$(DTB) of=$(IMAGE) bs=$(BS) seek=$(DTB_SEEK); \
	fi
	# kernel
	if [ "X$(KERNEL_ITB)" = "X" ]; then \
	echo "Skipping kernel image"; \
	else \
		dd if=$(KERNEL_ITB) of=$(IMAGE) bs=$(BS) seek=$(KERNEL_SEEK); \
	fi
	# ramdisk
	@echo "BOOT = $(BOOT)"
	if [ "X$(BOOT)" = "XSD" ]; then \
	  dd if=$(IMAGE) of=$(IMAGE).tmp bs=1M count=40; \
	  rm $(IMAGE); \
	  tail -c +4097 $(IMAGE).tmp > $(IMAGE); \
	  rm $(IMAGE).tmp; \
	fi

.PHONY: $(IMAGE)

clean:
	rm -f $(CLEAN_IMAGE)

.PHONY: clean

