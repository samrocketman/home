#!/usr/bin/env python
#Created by Sam Gleske
#Created on Fri Nov 30 14:38:16 EST 2012
#
#Tested:
#  Python 2.4.3 (#1, Jun 11 2009, 14:09:37)
#  Python 2.7.3
#
#Description:
#  "tail -f" a file until a phrase has been displayed and then exit.
#
#Modified from pytailer.
#  http://code.google.com/p/pytailer/source/browse/src/tailer/__init__.py

import time

class Tailer(object):
  line_terminators = ('\r\n', '\n', '\r')
  def __init__(self, file, read_size=1024, end=False):
    self.read_size = read_size
    self.file = file
    self.start_pos = self.file.tell()
    if end:
      self.seek_end()
  def seek_end(self):
    self.seek(0, 2)
  def seek(self, pos, whence=0):
    self.file.seek(pos, whence)
  def follow(self, delay=1.0):
    """\
    Iterator generator that returns lines as data is added to the file.
    Based on: http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/157035
    """
    trailing = True
    while 1:
      where = self.file.tell()
      line = self.file.readline()
      if line:    
        if trailing and line in self.line_terminators:
          # This is just the line terminator added to the end of the file
          # before a new line, ignore.
          trailing = False
          continue
        if line[-1] in self.line_terminators:
          line = line[:-1]
          if line[-1:] == '\r\n' and '\r\n' in self.line_terminators:
            # found crlf
            line = line[:-1]
        trailing = False
        yield line
      else:
        trailing = True
        self.seek(where)
        time.sleep(delay)
  def __iter__(self):
    return self.follow()
  def close(self):
    self.file.close()

def help():
  print """Name:
  pytailuntil - good for tailing service startup logs

Synopsis:
  python pytailuntil.py /path/to/file.log "phrase to find"

Description:
  "tail -f" a file until a phrase has been displayed and then exit.
  
Modified from pytailer.
  http://code.google.com/p/pytailer/source/browse/src/tailer/__init__.py"""

def _main(filepath,phrase):
  import re
  tailer = Tailer(open(filepath,'rb'))
  phrase_regex = re.compile(phrase)
  try:
    try:
      tailer.seek_end()
      for line in tailer.follow(delay=1.0):
        print line
        if not re.search(phrase_regex,line) == None:
          break
    except KeyboardInterrupt:
      pass
  finally:
    tailer.close()

def main():
  import sys
  from os.path import isfile
  if len(sys.argv) < 3 or sys.argv[1] == "-h" or sys.argv[1] == "--help":
    help()
    sys.exit()
  if isfile(sys.argv[1]):
    _main(sys.argv[1],sys.argv[2])
  else:
    print >>sys.stderr, 'File does not exist, try --help'
    sys.exit(1)

if __name__ == '__main__':
  main()
