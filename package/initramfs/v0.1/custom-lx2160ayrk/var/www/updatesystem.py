#!/usr/bin/micropython
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
import os, json

sd_blk="/dev/mmcblk0"
emmc_blk="/dev/mmcblk1"

config_file="/etc/update-system.json"
save_config_file="/mnt/rwfs/overlay/etc/update-system.json"

def path_exists(filename):
    try:
        status = os.stat(filename)
        return True
    except OSError:  # stat failed
        return False

_conf = None

_configs = {'update_server':"Update Server",'update_dir':"Update Directory",'update_user':"Update User",'update_server_transport':"Update Transport","update_config_file":"Update Config File"}
def get_config_keys():
    return _configs.keys()

_actions = {'update_system':"Update System"}
if path_exists(sd_blk):
  _actions['format_sd']="Format SD card"

if path_exists(emmc_blk):
  _actions['format_emmc']="Format eMMC"

def get_action_keys():
    return _actions.keys()

def get_legend(key,conf):
    if key in conf:
      return conf[key]
    return ""

def get_config_legend(key):
    return get_legend(key, _configs)

def get_action_legend(key):
    return get_legend(key, _actions)

def make_environ(envs):
  retval = {}
  for env in envs:
    val=os.getenv(env)
    if not val is None:
      retval[env]=val
  return retval
  
_environ = make_environ(["QUERY_STRING","REQUEST_METHOD"])

def get_environ():
    return _environ

def update_system():
    return os.system("update-system")

def format_sd(size=16):
    if path_exists(sd_blk):
        os.system("mkpart mmcblk0 " + str(size))
        return "<p>ok</p>"
    else:
        return "<p>No SD card present</p>"

def format_emmc(size=16):
    if path_exists(sd_blk):
        os.system("mkpart mmcblk1 16" + str(size))
        return "<p>ok</p>"
    else:
        return "<p>No eMMC present</p>"

def do_action(action_key):
    retval = "<p>action "+action_key+" requested</p>"
    if action_key is 'update_system':
      return retval+update_system()
    if action_key is 'format_sd':
      return retval+format_sd()
    if action_key is 'format_emmc':
      return retval+format_emmc()
    return retval + "<p>No action taken</p>"

def read_config():
    global _conf
    if _conf is None:
        _conf = ""
        with open(config_file,"r") as f:
            try:
                _conf = json.load(f)
            except:
                _conf = ""
    return _conf

def save_config(filename=save_config_file):
    conf = read_config()
    ret = ''
    ret+= '<p>opening '+filename+'</p>\n'
    with open(filename,"w") as f:
        ret+='<p>opened for writing ok</p>\n'
        try:
            f.write(json.dumps(conf,indent=4))
        except:
            ret += '<p>saving failed</p>'
    return ret

def set_config(key,val):
    global _conf
    read_config()
    _conf[key]=val

def get_config(key):
    conf = read_config()
    if key in conf:
      return conf[key]
    return ""

def get_password():
    return "password"

# not the best place for this but ...    
def get_html_style():
  style= """<style> body {background-color: powderblue;}
    h1 {color: red;} 
    p {color: blue;}
  </style>"""
  return style
