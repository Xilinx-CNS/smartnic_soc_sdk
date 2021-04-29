#!/bin/bash

set -e
set -x

#target=$1
#shift

mnt="proc dev"
umnt="dev proc"
ROOTFS_TMP=$1
ROOTFS_CUSTOM_NAME=$2
echo ${ROOTFS_TMP}

for fs in $mnt
do
	sudo mount -o bind /$fs ${ROOTFS_TMP}/$fs
done

function unmount_special() {

# Unmount special files
for fs in $umnt
do
  if mountpoint -q ${ROOTFS_TMP}/${fs} ; then
	sudo umount -l ${ROOTFS_TMP}/$fs
  fi
done
}

trap unmount_special EXIT

cd ${ROOTFS_TMP}
sudo chroot . /tmp/dostuff.sh
sudo cp config.deps ../${ROOTFS_CUSTOM_NAME}.deps

