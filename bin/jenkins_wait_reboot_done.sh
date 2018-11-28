#!/bin/bash
[ -e "${HOME}/.jenkins-bashrc" ] && source "${HOME}/.jenkins-bashrc"
url="${1:-${JENKINS_WAIT_REBOOT_DEFAULT}}"
url="${url%/}"
if [ "${url##*/}" != login ]; then
  url="${url}/login"
fi
endpoint=${url#*//}
endpoint=${endpoint%%.*}
endpoint=${endpoint%%:*}
while [ ! 200 = "$(curl ${CURL_OPTS} -siI -w "%{http_code}\\n" -o /dev/null ${url})" ];do echo -n '.';sleep 1;done
say_job_done.sh "${endpoint} ready."
