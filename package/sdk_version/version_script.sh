#!/bin/bash
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

#
# version in string format
#
# SDKMajor.SDKMinor.SDKPatch.SDKBuild.SDKDirty
#
#

PREFIX="u26z_soc_sdk_v"
SUFFIX="-g$(git describe --always)"
BUILD="$(git describe --always --tags 2> /dev/null)"
if [ "$(git describe --always)" != "$(git describe --always --dirty)" ]; then
	DIRTY=1
else
	DIRTY=0
fi

BUILD=${BUILD/#$PREFIX}
BUILD=${BUILD%"$SUFFIX"}
BUILD=$(echo $BUILD | sed -r 's/[-]+/./g').$DIRTY
echo $BUILD
