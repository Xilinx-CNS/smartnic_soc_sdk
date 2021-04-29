#!/usr/bin/python
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
import os, json, re, time, argparse

def debug(txt):
    global DEBUG
    if DEBUG:
        print("DEBUG: " + txt)


def mount_devpart(devpart, mountpoint, opt=""):
    ret = True

    if path_exists(devpart):
        if not path_exists(mountpoint):
            os.mkdir(mountpoint)
        if path_exists(mountpoint):
            umount_devpart(mountpoint)
            r, str = run_cmd("mount %s %s %s" % (opt, devpart, mountpoint))
            debug("Mount dev %s to %s status: %d" % (devpart, mountpoint, r))
            if ret != 0:
                print("%s" % str)

    else:
        ret = False

    return ret


def umount_devpart(mountpoint):
    retval = 1
    msg = ""
    retval, msg = run_cmd("umount %s" % mountpoint)
    return retval == 0


def run_cmd(cmd):
    cmd = "%s 1> /tmp/out 2> /tmp/out1" % cmd
    debug(cmd)
    ret = os.system(cmd)
    if ret != 0:
        file = "/tmp/out1"
    else:
        file = "/tmp/out"
    f = open(file, "r")
    ls = f.readlines()
    str = ""
    for l in ls:
        str = str + l

    return ret, str


def path_exists(filename):
    try:
        os.stat(filename)
        return True
    except OSError:  # stat failed
        return False


class eeprom_obj:
    def __init__(self, mmcidx):

        self.maindir = "/mnt/maint"
        self.romdir = "/mnt/rom/"
        self.eeprom = "/sys/bus/i2c/devices/0-0050/eeprom"
        self.blockdev = "/dev/mmcblk%d" % mmcidx
        self.conf = self.romdir + "eeprom.json"
        self.rootrw = None
        self.reboot_to_maintenance = False
        # json options
        self.random = 0
        self.netplan = None
        self.maintenance_boot = None

    def parse_json(self):
        with open(self.conf, "r") as f:
            try:
                maint = json.load(f)
                if "random" in maint.keys():
                    self.random = maint["random"]
                if "netplan" in maint.keys():
                    self.netplan = maint["netplan"]
                if "maintenance_boot" in maint.keys():
                    self.maintenance_boot = maint["maintenance_boot"]
            except:
                debug("json bad from path %s" % self.json)

    def mount_p2(self):
        if not mount_devpart(self.blockdev + "p2", self.maindir):
            print ("Error: Unable to mount p2")
            return False
        return True

    def unmount_p2(self):
        if not umount_devpart(self.maindir):
            print ("Maintenance unmount error")

    def mount_rwfs(self):

        cmd = "mount -o bind /proc /media/root-ro/proc"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("proc mount failed")
            debug(msg)
            return False
        cmd = "mount -o bind /run /media/root-ro/run"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("run mount failed")
            run_cmd("umount /media/root-ro/proc")
            debug(msg)
            return False
        cmd = "mount -o bind /sys /media/root-ro/sys"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("sys mount failed")
            run_cmd("umount /media/root-ro/proc")
            run_cmd("umount /media/root-ro/run")
            debug(msg)
            return False
        cmd = "mount -o remount,rw /media/root-ro"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("rw mount failed")
            debug(msg)
            run_cmd("umount /media/root-ro/proc")
            run_cmd("umount /media/root-ro/run")
            run_cmd("umount /media/root-ro/sys")
            return False
        self.rootrw = "/media/root-ro"
        return True

    def mount_rofs(self):

        cmd = "umount /media/root-ro/proc"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("proc umount failed")
            debug(msg)

        cmd = "umount /media/root-ro/run"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("run umount failed")
            debug(msg)

        cmd = "umount /media/root-ro/sys"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("sys umount failed")
            debug(msg)

        cmd = "mount -o remount,ro /media/root-ro"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("mount read-only failed")
            debug(msg)

        return True

    def copy_yml_overlay(self, ymlpath):

        if not self.copy_yml_noverlay(ymlpath):
            return False

        self.mount_rwfs()
        cmd = "cp -rf %s %s/etc/netplan/01-netcfg.yaml" % (ymlpath, self.rootrw)
        run_cmd(cmd)
        self.mount_rofs()
        return True

    def copy_yml_noverlay(self, ymlpath):

        cmd = "cp -rf %s /etc/netplan/01-netcfg.yaml" % ymlpath
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug(msg)
            debug("")
            return False
        return True

    def is_overlay_tmpfs(self):
        cmd = "mount"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            return False
        if "tmpfs-root on /media/root-rw" in msg:
            return True
        return False

    def is_overlay_persist(self):
        cmd = "mount"
        ret, msg = run_cmd(cmd)
        if ret != 0:
            return False
        if "/dev/mmcblk1p4 on /media/root-rw" in msg:
            return True
        return False

    def is_overlay(self):
        return self.is_overlay_persist() or self.is_overlay_tmpfs()

    def copy_yml(self, ymlpath):

        if not path_exists(ymlpath):
            print ("path %s not exist"  % ymlpath)
            return False
        if self.is_overlay():
            return self.copy_yml_overlay(ymlpath)
        else:
            return self.copy_yml_noverlay(ymlpath)

    def is_eeprom_present(self):
        if not path_exists(self.eeprom):
            print("Error: EEPROM not available")
            return False
        return True

    def mount_eeprom(self):
        if not self.is_eeprom_present():
            return False
        cmd = "dd if=%s of=/tmp/eeprom bs=512 count=8 skip=2" % self.eeprom
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug(msg)
            debug("EEPROM copy to tmp fail")
            return False
        cmd = "file /tmp/eeprom"
        ret, msg = run_cmd(cmd)
        if "Squashfs filesystem" not in msg:
            return False

        return mount_devpart("/tmp/eeprom", self.romdir, "-t squashfs -o loop")

    def umount_eeprom(self):
        umount_devpart(self.romdir)

    def is_new_update(self):
        if not path_exists(self.conf):
            debug("No json conf file")
            return False
        self.parse_json()
        if self.random != 0:
            if path_exists("%s/eeprom/%s" % (self.maindir, self.random)):
               return False

        return True

    def set_update_done(self):
        cmd  = "mkdir -p %s/eeprom/" % self.maindir
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug(msg)
            debug("set update done fail")
            return False
        cmd = "rm -rf %s/eeprom/*" % self.maindir
        run_cmd(cmd)
        cmd = "touch %s/eeprom/%s" % (self.maindir, self.random)
        ret, msg = run_cmd(cmd)
        if ret != 0:
            debug("random code flag add fail")
            debug(msg)
            return False

        return True

    def do_update(self):

        if self.netplan:
            self.copy_yml("%s/%s" % (self.romdir, self.netplan))
            cmd = "netplan apply"
            run_cmd(cmd)
        if self.maintenance_boot:
            self.reboot_to_maintenance = True

        return True

    def do(self):

        if not self.mount_eeprom():
            print("Error: No valid partition exist on EEPROM")
            return False
        if not self.mount_p2():
            debug("Partition 2nd mount error")
        if not self.is_new_update():
            debug("No new updates")
            self.unmount_p2()
            self.umount_eeprom()
            return True
        ret = self.do_update()
        ret = self.set_update_done()
        self.unmount_p2()
        self.umount_eeprom()
        if self.reboot_to_maintenance:
            run_cmd("boot_maintenance")

        return ret

DEBUG = False

obj = eeprom_obj(1)
obj.do()
