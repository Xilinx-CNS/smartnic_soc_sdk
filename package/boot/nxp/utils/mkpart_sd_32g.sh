#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
DEV=/dev/mmcblk0

EFI_START=68MiB
EFI_END=388MiB
BOOT_END=3000MiB
ROOTFS_END=22000MiB

if [ ! -b ${DEV} ]; then
echo "Block device ${DEV} not present"
exit 1
fi

#devsize=$[ `fdisk -ls ${DEV}` / 1000000 ]
#if [ ${devsize} -ge 7 ] ; then
#    echo "SD card: ${devsize} GB"
#else
#    echo "the size of SD disk is too small: ${devsize}"
#    exit 1
#fi

echo "This is a partition creator fo a 32G SD card as ${DEV}"
echo "BIG FAT HUGE WARNING"
echo "It will destroy the contents of the SD card entirely"

echo "Creating partitions ..."
sudo umount ${DEV}*

sudo parted -a minimal -s ${DEV} mklabel msdos

# 20MB for EFI partition-1
sudo parted -a minimal -s ${DEV} mkpart primary fat16 ${EFI_START} ${EFI_END}
# 1GB for boot partition-2
sudo parted -a minimal -s ${DEV} mkpart primary ext2 ${EFI_END} ${BOOT_END}
# most for rootfs partition-3
sudo parted -a minimal -s ${DEV} mkpart primary ext2 ${BOOT_END} ${ROOTFS_END}
# rest for rootfs partition-4
sudo parted -a minimal -s ${DEV} mkpart primary ext2 ${ROOTFS_END} 100%

echo "Formatting partitions ..."
sudo umount ${DEV}*

sudo mkfs.vfat -n EFI ${DEV}p1
sudo mkfs.ext4 -F -v -b 4096 -L boot ${DEV}p2
sudo mkfs.ext4 -F -v -O ^huge_file -b 4096 -L rootfs ${DEV}p3
sudo mkfs.ext4 -F -v -O ^huge_file -b 4096 -L scratch ${DEV}p4


