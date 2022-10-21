#!/bin/bash
[ -e "${HOME}/.jenkins-bashrc" ] && source "${HOME}/.jenkins-bashrc"
JENKINS_WEB="${JENKINS_WEB:-http://localhost:8080/}"
JENKINS_WEB="${JENKINS_WEB%/}"
export JENKINS_CALL_ARGS="-m POST -v --data-string script= ${JENKINS_WEB}/scriptText -d"
if [ ! -e "$1" ]; then
  echo "Script console script $1 does not exist." 1>&2
  exit 1
fi
jenkins_call.sh "$@"
