#!/usr/bin/env python
#Created by Sam Gleske
#Wed Jul  6 14:19:35 PDT 2016
#Mac OS X 10.11.5
#Darwin 15.5.0 x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-apple-darwin13.2.0)
#Python 2.7.9

import xml.etree.ElementTree as ET
import argparse
from sys import exit

parser = argparse.ArgumentParser(description='Get info from pom.xml.')

for x in ['groupId', 'artifactId', 'packaging', 'version', 'name', 'description']:
    parser.add_argument('--%s' % x, dest='property', action='store_const', const=x, help='Get the pom property for %s' % x)

parser.add_argument('--release', dest='property', action='store_const', const='release', help='Determine if it should be released based on -SNAPSHOT in version.')
parser.add_argument('--pom-file', dest='pomfile', type=str, default='pom.xml', help='Location of pom.xml.  Default: pom.xml')

args = parser.parse_args()

if not args.property:
    parser.print_help()
    exit(1)

with open(args.pomfile) as f:
    if args.property == 'release':
        print(str(not ET.parse(f).getroot().find( '{http://maven.apache.org/POM/4.0.0}version').text.endswith('-SNAPSHOT')).lower())
    else:
        print(ET.parse(f).getroot().find( '{http://maven.apache.org/POM/4.0.0}%s' % args.property).text)
