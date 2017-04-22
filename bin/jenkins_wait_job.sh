#!/bin/bash

while $(jenkins-call-url ${1%/}/api/json | python -c 'import sys,json;print str(json.load(sys.stdin)["building"]).lower()'); do
  sleep 5
done

RESULT=$(jenkins-call-url ${1%/}/api/json | python -c 'import sys,json;print json.load(sys.stdin)["result"]')

[ "${RESULT}" = 'SUCCESS' ] && \
  say_job_done.sh 'Jobb success.' || \
  say_job_done.sh 'Jobb failed.'
