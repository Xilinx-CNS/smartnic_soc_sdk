#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

# Top Level Makefile for menuconfig2

# Directory structure is:
# balloonsvn (checkout of balloonsvn/trunk)
#
# build |- <packagename>
#
# distro - binaries |- <packagename>
#       |            - utils
#       |
#        - sources  |- <packagename>
#                   |- initrd
#                    - rootfs

# base dir
export CHECKOUT:=$(shell pwd)

world: all

# parse configs
include Makefile.in

# add in help
include Makefile.help

# add in local customisations
-include Makefile.local

# include config subsystem
include Makefile.conf

all: config
	@echo "I: Build finished succesfully"

install: config-install

clean: config-clean

distclean: config-distclean

reallyclean:
	@rm -rf $(CHECKOUT)/build $(CHECKOUT)/distro

dist: config-dist
	@echo "I: Distribution completed"

source: config-source

uninstall: config-uninstall

info:
	@echo "I packages selected\n$(TARGETS)"

help: $(MAIN_HELP)

.PHONY: world all setup install clean distclean dist uninstall source ifo help status
