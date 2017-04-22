#!/bin/bash
#Created by Sam Gleske (https://github.com/samrocketman/home)
#Ubuntu 16.04.2 LTS
#Linux 4.4.0-72-generic x86_64
#Python 2.7.12


while $(jenkins-call-url ${1%/}/api/json | python -c 'import sys,json;print str(json.load(sys.stdin)["building"]).lower()'); do
  sleep 5
done

RESULT=$(jenkins-call-url ${1%/}/api/json | python -c 'import sys,json;print json.load(sys.stdin)["result"]')

[ "${RESULT}" = 'SUCCESS' ] && \
  say_job_done.sh 'Jobb success.' || \
  say_job_done.sh 'Jobb failed.'
