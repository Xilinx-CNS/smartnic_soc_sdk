#!/usr/bin/micropython
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#

#import os, updatesystem, urllib.parse
import os, updatesystem
import cgi

debug=False
debug=True

print("")

print(updatesystem.get_html_style())

print("<h1>Action ...</h1>")

form=cgi.FieldStorage(environ=updatesystem.get_environ())
form_keys=form.keys()

if debug:
  print("<p>Form is " + str(form) +"</p>")
  print("<p>Form keys are " + str(form_keys) +"</p>")

#for key in keys:
do_config_update = False
for key in form_keys:
  conf_keys=updatesystem.get_config_keys()
  if key in conf_keys:
    if debug:
      print('<p>update conf '+key +' with = '+form[key].value+'<p/>')
    updatesystem.set_config(key,form[key].value)
    do_config_update=True

if do_config_update:
    result = updatesystem.save_config()
    print('<p>saved config: ' + result+'</p>')

for key in form_keys:
  action_keys=updatesystem.get_action_keys()
  print('<p>action_keys are '+str(action_keys)+'<p/>')
  if debug:
    print('<p>action key search is '+key+'<p/>')
  if key in action_keys:
      print(updatesystem.do_action(key))

print('<p>Completed</p>')
