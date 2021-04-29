#!/bin/bash
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# decompress source
if [ ! -d SFC_DIR ]; then
  mkdir SFC_DIR
  pushd SFC_DIR
  echo "uncompressing net-driver source"
  tar -xzf ../SFC_SOURCE
  popd
fi

if [ "$1" = 'source' ]; then
  exit 0
fi

# install dependencies
apt -y install bison flex bc

if [ "$1" = 'configure' ]; then
  exit 0
fi

# enter source dir
pushd SFC_DIR
make
if [ "$1" = 'install' ]; then
  make install
fi
popd

