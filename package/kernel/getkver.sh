#!/bin/sh
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
k_ver=`awk  '{ if ($1 == "VERSION") { print $3 } }' < $1`
#echo "k_ver = $k_ver"
k_patchlevel=`awk ' { if ($1 == "PATCHLEVEL") { print $3 } }' < $1`
#echo "k_patchlevel = $k_patchlevel"
k_sublevel=`awk ' { if ($1 == "SUBLEVEL") { print $3 } }' < $1`
#echo "k_sublevel = $k_sublevel"

kernver="$k_ver.$k_patchlevel.$k_sublevel"

#echo "kernver = $kernver"

echo $kernver

