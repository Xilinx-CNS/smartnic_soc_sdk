#!/bin/bash
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# decompress source
if [ ! -d KERNEL_DIR ]; then
  echo "uncompressing kernel"
  tar -xzf KERNEL_DIR-source.tgz
fi

if [ "$1" = 'source' ]; then
  exit 0
fi

# install dependencies
apt -y install bison flex bc

# enter source dir
pushd KERNEL_DIR

make oldconfig
make modules_prepare

if [ "$1" = 'configure' ]; then
  popd
  exit 0
fi

make -j10 Image Image.gz dtbs
make modules
if [ "$1" = 'install' ]; then
make modules_install
make install
fi

popd


