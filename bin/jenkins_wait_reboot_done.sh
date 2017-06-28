#!/bin/bash
[ -e "${HOME}/.jenkins-bashrc" ] && source "${HOME}/.jenkins-bashrc"
url="${1:-${JENKINS_WAIT_REBOOT_DEFAULT}}"
endpoint=${url#*//}
endpoint=${endpoint%%.*}
while [ "503" = "$(curl ${CURL_OPTS} -siI -w "%{http_code}\\n" -o /dev/null ${url})" ];do echo -n '.';sleep 1;done
say_job_done.sh "${endpoint} ready."
