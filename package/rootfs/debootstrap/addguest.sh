#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
adduser --quiet --disabled-password --gecos Guest guest
echo guest:guest | chpasswd
