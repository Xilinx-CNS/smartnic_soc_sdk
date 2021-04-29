#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
# Firmware Installation guide #

Create 3 partitions on the target SD card starting at offset 64MB+4MB
The first partition is a 20MB VFAT EFI partition (unused)
The second partition is a >=100MB ext4 BOOT partition (reduced from 1GB recomended by NXP)
The third partition is the remainder is a large ext4 ROOTFS partition


MMC install firmware image to mmc card as mmcblk0. If in USB-to-MMC adapter, replace mmcblk0 with sdX where X is the relevant device
dd if=<firmware_image> of=/dev/mmcblk0 bs=512 seek=8

