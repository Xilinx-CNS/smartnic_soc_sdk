#!/bin/sh 
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

if [ ! -d /var/local/data/ ]; then
	mkdir -p /var/local/data/
fi
if [ ! -f /var/local/data/.swapfile ]; then
	if [ $1 -gt 2048 ]; then
		echo "Size larger that 2048MiB"
		exit 1
	fi
	fallocate -l $1MiB /var/local/data/.swapfile
	if [ $? -eq 0 ]
	then
		chmod 600 /var/local/data/.swapfile
		mkswap /var/local/data/.swapfile
	else
		rm /var/local/data/.swapfile
		exit 2
	fi
fi
if [ -f /var/local/data/.swapfile ]; then
	echo "Mounting swap"
	swapon /var/local/data/.swapfile
fi
exit 0

