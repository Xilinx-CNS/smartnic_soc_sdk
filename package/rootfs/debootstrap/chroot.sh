#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# this is to be executed in the root dir of the chroot as root

mount -o bind /dev dev
chroot .
umount dev
