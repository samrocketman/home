#!/bin/bash
#Sam Gleske
#Tue Mar 28 00:19:18 PDT 2017
#jq-1.5

#DESCRIPTION
#  Read the queue of Jenkins and exit when nothing is in the queue.

#master host
endpoint="${JENKINS_WEB:-}"
options=""

while [ "$#" -gt 0 ]; do
  case $1 in
    -*)
      [ -z "$options" ] && options="$1" || options="$options $1"
      shift
      continue
      ;;
    *)
      endpoint=$1
      continue
  esac
done

function call_jenkins() {
  jenkins-call-url ${options} "${endpoint%/}/queue/api/json"
}

while true; do
  count=$(call_jenkins | jq -r '.items[].url' | wc -l)
  echo $count
  if [ "$count" -eq 0 ]; then break; fi
  sleep 30
done
