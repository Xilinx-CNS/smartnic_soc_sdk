#!/usr/bin/env python
#
# This file is distributed as part of Xilinx ARM SDK
#
# Copyright (c) 2020 - 2021,  Xilinx, Inc.
# All rights reserved.
#
import subprocess, cgi, cgitb

form = cgi.FieldStorage() 

def start():
    print "Content-type:text/html\r\n\r\n"
    print '<html>'

def head():
    print '<head>'
    print '<title>Test Python CGI app</title>'
    print '</head>'

def body():
    print '<body>'
    name = form.getvalue('name')
    hostname = subprocess.check_output([hostname])
    if hostname is None:
	hostname = 'LX2160a'
    print '<h2>Hello %s python CGI Word!</h2>' % hostname
    if not name is None
	print '<p>name = %s</p>' % name
    print '</body>'

def end():
    print '</html>'

def main():
    start()
    head()
    body()
    end()

if __name__ == '__main__':
    main()

