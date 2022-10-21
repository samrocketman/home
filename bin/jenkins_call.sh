#!/bin/bash
# This is a wrapper script for jenkins-call-url and jenkins-call-url-2.7.  This
# script detections python version from the current system and selects an
# appropriate way to call jenkins-call-url.  This enables a better user
# experience by not having to worry about python version.

if type -P python3 &> /dev/null; then
  jenkins-call-url "$@"
elif python -c 'import platform,sys; sys.exit(0) if platform.python_version().startswith("2.7") else sys.exit(1)'; then
  python "$(type -P jenkins-call-url-2.7)" "@"
elif python -c 'import platform,sys; sys.exit(0) if platform.python_version().startswith("3") else sys.exit(1)'; then
  python "$(type -P jenkins-call-url)" "@"
else
  echo 'Python 2 or 3 could not be detected.' >&2
  exit 1
fi
