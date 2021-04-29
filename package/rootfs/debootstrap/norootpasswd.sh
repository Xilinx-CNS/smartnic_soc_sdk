#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
if [ -e etc/shadow ]; then
echo "removing root password from shadow"
sed -i -e 's/root:\*:/root::/' etc/shadow
else
echo "/etc/shadow not found"
fi

