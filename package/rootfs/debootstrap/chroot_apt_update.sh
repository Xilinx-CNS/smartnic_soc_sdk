#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# this is to be executed within a chroot as root

apt -o APT::Sandbox::User=root update
