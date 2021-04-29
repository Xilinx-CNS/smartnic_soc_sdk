#!/usr/bin/python3
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

import os, json, re, time, argparse
import shutil
import sys
import random

def debug(txt):
    global DEBUG
    if DEBUG:
        print("DEBUG: " + txt)


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

def copyfile(src,dst):
    try:
        print(src)
        print(dst)
        shutil.copyfile(src, dst)
    except IOError as e:
        print("Unable to copy file. %s" % e)
        return False
    except:
        print("Unexpected error:", sys.exc_info())
        return False
    return True

def path_exists(filename):
    try:
        os.stat(filename)
        return True
    except OSError:  # stat failed
        return False

def write_json(jsonconf = None, jfile="eeprom.json"):
    print(jfile)
    with open(jfile, "w") as f:
        try:
            print("trying to write")
            print(jsonconf)
            f.write(json.dumps(jsonconf, indent=4))
        except:
            print("error in file write")
            print("Unexpected error:", sys.exc_info())
            return False
    return True

def get_rand():
    return random.randint(0xff, 0xfffffffe)

class eeprom_obj:
    def __init__(self, args):
        self.conf = ""
        self.jsonconf = {'random': '', 'netplan': '', 'interface_file': '',
                     'maintenance_boot': False, 'remote_server': ''}
        self.args = args
        self.tmpfldr = None
        self.jffsfldr = None
        self.eepromfldr = None
        self.jffs2 = False
        self.squashfs = False

    def copy_intfile(self, path):
        if not path_exists(path):
            return False
        copyfile(path, self.eepromfldr + "/interfaces")
        self.jsonconf["interface_file"] = "interfaces"
        self.squashfs = True

        return True

    def copy_remotefile(self, path):
        if not path_exists(path):
            return False
        copyfile(path, self.eepromfldr + "/update-system.json")
        self.jsonconf["remote_server"] = "update-system.json"
        self.squashfs = True

        return True
    def copy_yaml(self, path):
        if not path_exists(path):
            return False
        debug((path))
        copyfile(path, self.eepromfldr + "/01-netcfg.yaml")
        self.jsonconf["netplan"] = os.path.basename(path)
        self.squashfs = True

        return True

    def create_squashfs(self, folder_path):

        cmd = "mksquashfs  -version"
        err, msg = run_cmd(cmd)
        if err != 0:
            print ("mksquashfs not found")
            ret = False

        print("Generating blob for EEPROM")
        self.jsonconf["random"] = get_rand()
        write_json(self.jsonconf, jfile=folder_path + "/eeprom.json")
        cmd = "mksquashfs  %s eeprom.blob -noappend" % folder_path
        err, msg = run_cmd(cmd)
        if err != 0:
            print(msg)
        return True

    def create_jffs2(self, folder_path):

        cmd = "mkfs.jffs2 --version"
        err, msg = run_cmd(cmd)
        if err != 0:
            print ("mkfs.jffs2 not found")
            return

        print("Generating blob for jffs2")
        cmd = "mkfs.jffs2 --pad --no-cleanmarkers --eraseblock=128 -d %s " \
              "-o jffs2.blob" % folder_path
        err, msg = run_cmd(cmd)
        if err != 0:
            print(msg)
        return

    def copy_driver(self, path):
        copied = False
        if path_exists(path + "/sfc.ko"):
            copyfile(path + "/sfc.ko", self.jffsfldr + "/sfc.ko")
            copied = True
        if path_exists(path + "/sfc_driverlink.ko"):
            copyfile(path + "/sfc_driverlink.ko", self.jffsfldr + "/sfc_driverlink.ko")
            copied = True
        if path_exists(path + "/virtual_bus.ko"):
            copyfile(path + "/virtual_bus.ko", self.jffsfldr + "/virtual_bus.ko")
            copied = True
        if copied:
            self.jffs2 = True

        return copied

    def cmdline(self):
        if self.args.drvpath:
            self.copy_driver(self.args.drvpath[0])
        if self.args.yamlfile:
            self.copy_yaml(self.args.yamlfile[0])
        if self.args.intfile:
            self.copy_intfile(self.args.intfile[0])
        if self.args.remotefile:
            self.copy_remotefile(self.args.remotefile[0])
        if self.args.bmaint:
            self.jsonconf["maintenance_boot"] = True
            self.squashfs = True

        return True

    def setup(self):

        ret = True
        self.tmpfldr = "/tmp/%d" % get_rand()
        debug(self.tmpfldr)
        try:
            os.mkdir(self.tmpfldr)
            os.mkdir(self.tmpfldr + "/jffs2")
            os.mkdir(self.tmpfldr + "/eeprom")
        except:
            print("Unexpected error:", sys.exc_info())
            ret = False

        self.jffsfldr = self.tmpfldr + "/jffs2"
        self.eepromfldr = self.tmpfldr + "/eeprom"

        return ret

    def cleanup(self):
        shutil.rmtree(self.jffsfldr)
        shutil.rmtree(self.eepromfldr)
        shutil.rmtree(self.tmpfldr)

    def do(self):

        ret = self.setup()
        if not ret:
            return
        self.cmdline()
        if self.jffs2:
            self.create_jffs2(self.tmpfldr + "/jffs2")
        if self.squashfs:
            self.create_squashfs(self.tmpfldr + "/eeprom")
        self.cleanup()


parser = argparse.ArgumentParser(description='Generate jffs2/squashfs blob')

parser.add_argument('--update_driver', help=": Folder path with required ko's.", dest='drvpath', type = str, nargs=1, default=None)
parser.add_argument('--netconf_rootfs', help=": Rootfs network YAML file", dest='yamlfile', type = str, nargs=1, default=None)
parser.add_argument('--netconf_maint', help=": Maintenance kernel network interface file", dest='intfile', type = str, nargs=1, default=None)
parser.add_argument('--boot_maintenance', help=(": Boot into maintenance kernel"), dest='bmaint',
                    default = False, action="store_true")
parser.add_argument('--pull_mode_conf', help=": Pull mode server config", dest='remotefile', type = str, nargs=1, default=None)

if len(sys.argv) == 1:
    args = parser.parse_args(['-h', ])
else:
    args = parser.parse_args()

DEBUG = False

obj = eeprom_obj(args)
obj.do()
