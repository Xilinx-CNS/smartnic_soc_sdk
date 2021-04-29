#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
#
rfs_branding_VER=0.1
version=$(SDK_VERSION)
rfs_branding_CUSTOM=$(BUILDDIR)/.conf/rootfs/rootfs_branding.stamp

$(rootfs_CUSTOM):$(rfs_branding_CUSTOM)

$(rfs_branding_CUSTOM):
	mkdir -p $(rootfs_TMP)/patches
	cp -r $(PACKAGEDIR)/rootfs/rfs_branding/rfs_patches/$(rfs_branding_VER)/* $(rootfs_TMP)/patches/
	sed -i 's/TEMP_VERSION/$(version)/g' $(rootfs_TMP)/patches/os_release.patch
	sed -i 's/TEMP_VERSION/$(version)/g' $(rootfs_TMP)/patches/lsb_release.patch
	ln -sf $(rootfs_TMP)/patches/series-lx2162au26z $(rootfs_TMP)/patches/series
	cd $(rootfs_TMP); \
	quilt push -a; \
	cd -; \
	rm -rf $(rootfs_TMP)/patches; \
	touch $(rfs_branding_CUSTOM)

