#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

echo "Configuring"
#apt clean
#rm -rf /var/lib/apt/lists/*

# seems needed for qemu based installs where /sbin/init is not linked to /lib/systemd/systemd
#if [ ! -e /sbin/init ]; then
#  if [ -x /lib/systemd/systemd ]; then
#    echo "Fixing up install of systemd"
#    ln -s /lib/systemd/systemd /sbin/init
#  fi
#fi

#often init=/linuxrc
if [ ! -x /linuxrc ]; then
  ln -s /sbin/init /linuxrc
fi

#umount -f /proc
