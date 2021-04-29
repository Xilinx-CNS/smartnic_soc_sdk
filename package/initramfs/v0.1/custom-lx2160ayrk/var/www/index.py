#!/usr/bin/micropython
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
import os, json
import updatesystem

def path_exists(filename):
    try:
        status = os.stat(filename)
        return True
    except OSError:  # stat failed
        return False

def cat(filename):
    contents = ""
    if path_exists(filename):
        with open(filename,"r") as f:
            contents = f.read()
    contents=contents.replace("\n"," ")
    return contents

def start_form(action,legend=None):
    retval = '<form action="'+action+'"><fieldset>'
    if not legend is None:
      retval+= '<legend>'+legend+'</legend>'
    return retval

def end_form():
    return '</fieldset></form>'

def start_element(label=None):
    retval="<p>"
    if not label is None:
        retval += '<label>'+label+'</label>'
    return retval

def end_element(label=None):
    retval = ""
    if not label is None:
        retval += '<label>'+label+'</label>'
    return retval+'</p>'

def input_element(key,legend=None,hint=None):
    val = updatesystem.get_config(key)
    if legend is None:
      legend=key
    retval=start_element(legend)
    retval += '<input name = "' + key +'" value= "' + val + '"/>'
    return retval + end_element(hint)

def hidden_element(key,hint=None):
    val = 'yes'
    retval=start_element()
    retval += '<input type="hidden" name = "' + key +'" value= "' + val + '"/>'
    return retval + end_element(hint)

def input_button(name,hint=None):
    retval=start_element(name)
    retval += '<input type="button" value = "' + name + '"/>'
    return retval + end_element(hint)

def submit_button(name,legend="",hint=None):
    retval=start_element(legend)
    retval += '<input type="submit" value = "' + name + '"/>'
    return retval + end_element(hint)

def checkbox_element(key,hint=None):
    retval=start_element(key)
    retval+='<input type="checkbox" input name = "' + key +'"/>'
    return retval+end_element(hint)

def password_element(pw="test", hint=None):
    retval=start_element("Password")
    retval+="""<input
      type="password"
      id="mypwd"
      value="""
    retval += '"'+pw+'"'
    retval +="""
      />
    """
    return retval + end_element(hint)

def html_header():
  retval="""
<html>
<header>
"""
  retval += updatesystem.get_html_style()
  return retval+"</header>"

def html_body():
  retval = "<body>"
  # title
  retval += "<h1>Update System Configuration</h1>"
  # security token
  retval += password_element(updatesystem.get_password())

  # configuration
  retval+=start_form("action.py","configuration")
  for key in updatesystem.get_config_keys():
    legend = updatesystem.get_config_legend(key);
    retval += input_element(key,legend)
  retval += submit_button("Save Configuration")
  retval += end_form()

  # actions
  for key in updatesystem.get_action_keys():
    legend = updatesystem.get_action_legend(key);
    retval += start_form("action.py",legend)
    retval +=hidden_element(key)
    retval += submit_button(legend)
    retval += end_form()

  return retval + "</body>"

print("")

print(html_header())

print(html_body())

# body
#print("<body>")


#print (password_element(updatesystem.get_password()))

# configuration
#print(start_form("action.py","configuration"))
#for key in updatesystem.get_config_keys():
#  legend = updatesystem.get_config_legend(key);
#  print (input_element(key,legend))
#print (submit_button("Save Configuration"))
#print(end_form())

# actions
#for key in updatesystem.get_action_keys():
#  legend = updatesystem.get_action_legend(key);
#  print(start_form("action.py",legend))
#  print (hidden_element(key))
#  print (submit_button(legend))
#  print(end_form())

print("</html>")

