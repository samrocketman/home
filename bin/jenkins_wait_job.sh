#!/bin/bash

while $(jenkins-call-url ${1%/}/api/json | jq -r '.building'); do
  sleep 5
done

RESULT=$(jenkins-call-url ${1%/}/api/json | jq -r '.result')

[ "${RESULT}" = 'SUCCESS' ] && \
  say_job_done.sh 'Jobb success.' || \
  say_job_done.sh 'Jobb failed.'
