#!/usr/bin/env python
import sys
i="/"
while sys.stdin.readline():
    print "%s" % i,
    if i == "/":
        i="-"
    elif i == "-":
        i="\\"
    elif i== "\\":
        i="|"
    else:
        i="/"
    sys.stdout.flush()
    print "\r",
print "Done."
