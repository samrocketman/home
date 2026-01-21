#!/bin/bash

url="${1:-}"
if [ -z "${url:-}" ]; then
  if [ -f "${JENKINS_HEADERS_FILE:-}" ]; then
    jenkins_host="$(yq .headers.Host < "$JENKINS_HEADERS_FILE")"
    url="https://${jenkins_host}/"
  fi
fi
jenkins_call.sh -avvo /dev/null -m HEAD "${url}"
