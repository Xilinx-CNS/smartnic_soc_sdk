#!/bin/bash
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

apt update

if [ -x kernel_builder.sh ]; then
pushd .
./kernel_builder.sh $1
popd
fi

if [ -x net-driver_builder.sh ]; then
pushd .
./net-driver_builder.sh $1
popd
fi

if [ -x spdk_builder.sh ]; then
pushd .
./spdk_builder.sh $1
popd
fi

if [ -x onload_builder.sh ]; then
pushd .
./onload_builder.sh $1
popd
fi

if [ -x ceph_builder.sh ]; then
pushd .
./ceph_builder.sh $1
popd
fi

