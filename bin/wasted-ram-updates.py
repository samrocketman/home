#!/usr/bin/python -t
# -*- coding: utf-8 -*-
#Author: James Antill <james.antill@redhat.com>
#Contributors:
#    Sam Gleske <sag47@drexel.edu>

#Source1: http://www.redhat.com/archives/rhl-list/2009-July/msg00228.html
#Source2: http://markmail.org/message/dodinyrhwgey35mh
#Acquired Fri Nov  9 09:09:28 EST 2012

#Successfully tested environments:
#  Ubuntu 12.04.1 LTS (Kubuntu)
#    Python 2.7.3
#  Red Hat Enterprise Linux Server release 6.3 (Santiago)
#    Python 2.6.6

#DESCRIPTION:
#  Check /proc directory for programs with open file handles to
#  deleted files.  Meaning the program is using the file in memory but the
#  it has been removed from the filesystem (such as a library).
#  
#  The purpose of this script is to safely determine which services should
#  be restarted after updating many packages on a server.
#
#  Note that a few entries in this list are "normal" e.g. a program opens a 
#  file for temporary storage, and then deletes it (but keeps the handle), 
#  but most will indicate a process that needs to be restarted to reload 
#  files from a new package.


#USAGE: 
#  Run with default behavior.  This will group by file name.
#    python wasted-ram-updates.py
#  Group output by pids so that you can see which files the process has open.
#    python wasted-ram-updates.py pids
#  Only show a summary.
#    python wasted-ram-updates.py summary

import os
import sys


# Decent (UK/US English only) number formatting.
import locale
locale.setlocale(locale.LC_ALL, '') 

#help documentation
if len(sys.argv) > 1 and (sys.argv[1] == "-h" or sys.argv[1] == "--help"):
  print """
NAME:
    wasted-ram-updates.py - discovers programs with open file handles to 
                            deleted files.

SYNOPSIS:
    wasted-ram-updates.py [OPTIONS]

DESCRIPTION:
    The purpose of this script is to safely determine which services should
    be restarted after updating many packages on a server.

    Note that a few entries in this list are "normal" e.g. a program opens a
    file for temporary storage, and then deletes it (but keeps the handle),
    but most will indicate a process that needs to be restarted to reload
    files from a new package.

OPTIONS:
    By default executing this program with no arguments will organize the
    output by file handle to deleted file.

    -h, --help
        show this help documentation

    pids
        Organize the output by PID

    summary
        Only displays summary information.

EXAMPLES:
    wasted-ram-updates.py
        Run with default behavior.  This will group by file name.

    wasted-ram-updates.py pids
        Group output by pids so that you can see which files the process 
        has open.

    wasted-ram-updates.py summary
        Only show a summary.

AUTHORS:
    Written by James Antill <james.antill@redhat.com>
    Contributors:
        Sam Gleske <sag47@drexel.edu>

LINKS:
    Source 1:
        http://www.redhat.com/archives/rhl-list/2009-July/msg00228.html
    Source 2:
        http://markmail.org/message/dodinyrhwgey35mh
"""
  sys.exit(0)

def loc_num(x):
    """ Return a string of a number in the readable "locale" format. """
    return locale.format("%d", int(x), True)
def kmgtp_num(x):
    """ Return a string of a number in the MEM size format, Ie. "30 MB". """
    ends = [" ", "K", "M", "G", "T", "P"]
    while len(ends) and x > 1024:
        ends.pop(0)
        x /= 1024
    return "%u %s" % (x, ends[0])

def cmdline_from_pid(pid):
    """ Fetch command line from a process id. """
    try:
        cmdline= open("/proc/%i/cmdline" %pid).readlines()[0]
        return " ".join(cmdline.split("\x00")).rstrip()
    except:
        return ""

pids = {}
for d in os.listdir("/proc/"):
    try:
        pid = int(d)
        pids[pid] = lambda x: x
        pids[pid].files = set()
        pids[pid].vsz   = 0
        pids[pid].s_size          = 0
        pids[pid].s_rss           = 0
        pids[pid].s_shared_clean  = 0
        pids[pid].s_shared_dirty  = 0
        pids[pid].s_private_clean = 0
        pids[pid].s_private_dirty = 0
        pids[pid].referenced      = 0
        pids[pid].name            = cmdline_from_pid(pid)
    except:
        pass

def map_sz(x):
    """ Work out vsz from mapping range. """
    (beg, end) = x.split('-')
    return (int(end, 16) - int(beg, 16))

files = {}
for pid in pids.keys():
    try:
        try:
            lines = open("/proc/%d/smaps" % pid).readlines()
            smaps = True
        except:
            lines = open("/proc/%d/maps" % pid).readlines()
            smaps = False

        off = 0
        while off < len(lines):
            line = lines[off]
            off += 1
            try:
                int(line[0])
            except:
                continue

            data = line.split(None, 5)
            try:
                ino = int(data[4])
                dev = int(data[3].split(":", 2)[0], 16)
            except:
                print "DBG: Bad line:", lines[off - 1]
                print "DBG:     data=", data
                continue
                
            if dev == 0:
                continue
            if ino == 0:
                continue
            if '(deleted)' not in data[5]:
                continue

            key = "%s:%d" % (data[3], ino)
            if key not in files:
                files[key] = lambda x: x # Hack
                
                files[key].s_size          = 0
                files[key].s_rss           = 0
                files[key].s_shared_clean  = 0
                files[key].s_shared_dirty  = 0
                files[key].s_private_clean = 0
                files[key].s_private_dirty = 0
                files[key].referenced      = 0
                
                files[key].vsz  = 0
                files[key].pids = set()
                files[key].name = data[5]
                
            num = map_sz(data[0])
            pids[pid].vsz  += num
            pids[pid].files.update([key])
            files[key].vsz += num
            files[key].pids.update([pid])
            try:
                if smaps:
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_size += num
                    files[key].s_size          += num
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_rss            += num
                    files[key].s_rss           += num
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_shared_clean   += num
                    files[key].s_shared_clean  += num
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_shared_dirty   += num
                    files[key].s_shared_dirty  += num
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_private_clean  += num
                    files[key].s_private_clean += num
                    off += 1
                    num = int(lines[off].split(None, 3)[1])
                    pids[pid].s_private_dirty  += num
                    files[key].s_private_dirty += num
                    off += 1
                    try:
                        num = int(lines[off].split(None, 3)[1])
                        pids[pid].referenced   += num
                        files[key].referenced  += num
                        off += 1
                    except:
                        pass
            except:
                print "DBG: Bad data:", lines[off - 1]
                
    except:
        pass

vsz             = 0
s_size          = 0
s_rss           = 0
s_shared_clean  = 0
s_shared_dirty  = 0
s_private_clean = 0
s_private_dirty = 0
referenced      = 0

out_type = "files"
if len(sys.argv) > 1 and sys.argv[1] == "pids":
    out_type = "pids"
if len(sys.argv) > 1 and sys.argv[1] == "summary":
    out_type = "summary"

for x in files.values():
    vsz             += x.vsz
    s_size          += x.s_size
    s_rss           += x.s_rss
    s_shared_clean  += x.s_shared_clean
    s_shared_dirty  += x.s_shared_dirty
    s_private_clean += x.s_private_clean
    s_private_dirty += x.s_private_dirty
    referenced      += x.referenced

    if out_type == "files":
        print "%5sB:" % kmgtp_num(x.vsz), x.name,
        print "\ts_size          = %5sB" % kmgtp_num(x.s_size * 1024)
        print "\ts_rss           = %5sB" % kmgtp_num(x.s_rss * 1024)
        print "\ts_shared_clean  = %5sB" % kmgtp_num(x.s_shared_clean * 1024)
        print "\ts_shared_dirty  = %5sB" % kmgtp_num(x.s_shared_dirty * 1024)
        print "\ts_private_clean = %5sB" % kmgtp_num(x.s_private_clean * 1024)
        print "\ts_private_dirty = %5sB" % kmgtp_num(x.s_private_dirty * 1024)
        print "\treferenced      = %5sB" % kmgtp_num(x.referenced * 1024)
        for pid in frozenset(x.pids):
            print "\t\t", pid, pids[pid].name


for pid in pids.keys():
    if not pids[pid].vsz:
         del pids[pid]

if out_type == "pids":
    for pid in pids.keys():
        print "%5sB:" % kmgtp_num(pids[pid].vsz), pid, pids[pid].name
        print "\ts_size          = %5sB" % kmgtp_num(pids[pid].s_size * 1024)
        print "\ts_rss           = %5sB" % kmgtp_num(pids[pid].s_rss * 1024)
        print "\ts_shared_clean  = %5sB" % kmgtp_num(pids[pid].s_shared_clean * 1024)
        print "\ts_shared_dirty  = %5sB" % kmgtp_num(pids[pid].s_shared_dirty * 1024)
        print "\ts_private_clean = %5sB" % kmgtp_num(pids[pid].s_private_clean * 1024)
        print "\ts_private_dirty = %5sB" % kmgtp_num(pids[pid].s_private_dirty * 1024)
        print "\treferenced      = %5sB" % kmgtp_num(pids[pid].referenced * 1024)
        for key in pids[pid].files:
            print "\t\t", files[key].name,

print "\
=============================================================================="
print "files           = %8s" % loc_num(len(files))
print "pids            = %8s" % loc_num(len(pids.keys()))
print "vsz             = %5sB" % kmgtp_num(vsz)
print "\
------------------------------------------------------------------------------"
print "s_size          = %5sB" % kmgtp_num(s_size * 1024)
print "s_rss           = %5sB" % kmgtp_num(s_rss * 1024)
print "s_shared_clean  = %5sB" % kmgtp_num(s_shared_clean * 1024)
print "s_shared_dirty  = %5sB" % kmgtp_num(s_shared_dirty * 1024)
print "s_private_clean = %5sB" % kmgtp_num(s_private_clean * 1024)
print "s_private_dirty = %5sB" % kmgtp_num(s_private_dirty * 1024)
print "referenced      = %5sB" % kmgtp_num(referenced * 1024)
print "\
=============================================================================="
