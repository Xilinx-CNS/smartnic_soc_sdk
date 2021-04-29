#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
sdk_version_BUILDDIR=$(BUILDDIR)/sdk_version/
sdk_version_ENV_MAKEOPTS+=OUT=$(sdk_version_BUILDDIR)
sdk_version_IMAGES=$(sdk_version_BUILDDIR)/sdk_version_util
sdk_version_POST_MAKESCRIPT=$(sdk_version_BUILDDIR)/sdk_version_util
$(eval $(call package-builder,sdk_version))
