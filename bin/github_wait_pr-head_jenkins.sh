#!/bin/bash

if [ "$#" = 0 ]; then
  github_wait_commit_status.sh
else
  set -x
  github_wait_commit_status.sh "$1" continuous-integration/jenkins/pr-head
fi
