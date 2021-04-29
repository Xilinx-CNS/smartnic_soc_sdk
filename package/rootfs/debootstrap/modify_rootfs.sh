#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

set -x

ROOTFS=debchroot.tgz
TMP=tmp
NEW_ROOTFS="$ROOTFS"1.tgz

if [ ! -z $1 ]; then
  ROOTFS=$1
fi

rm -rf $TMP
mkdir $TMP
cd $TMP
tar -xvzf ../$ROOTFS
sudo mount -o bind /dev dev
#sudo mount -o bind /proc proc
#sudo mount -o bind /sys sys
sudo chroot .
#sudo umount proc sys
sudo umount dev
tar cvzf ../$NEW_ROOTFS *
cd ..
sudo rm -rf $TMP


