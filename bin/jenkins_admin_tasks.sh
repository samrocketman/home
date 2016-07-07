#!/bin/bash
#Created by Sam Gleske
#Thu Jun 30 09:40:06 PDT 2016
#Mac OS X 10.11.5
#Darwin 15.5.0 x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-apple-darwin13.2.0)
#curl 7.43.0 (x86_64-apple-darwin15.0) libcurl/7.43.0 SecureTransport zlib/1.2.5

JENKINS_WEB="${JENKINS_WEB:-http://localhost:8080/}"

#remove trailing slash
JENKINS_WEB="${JENKINS_WEB%/}"
CURL="${CURL:-curl}"

#
# SCRIPT CONSOLE SCRIPTS
#

function script_enable_shutdown_mode() {
  cat <<'EOF'
Jenkins.instance.doQuietDown(false, 0)
null
EOF
}

function script_disable_shutdown_mode() {
  cat <<'EOF'
Jenkins.instance.doCancelQuietDown()
null
EOF
}

function script_safe_restart() {
  cat <<'EOF'
import hudson.model.RestartListener

//determine if a restart is necessary and if so, restart
if(Jenkins.instance.isQuietingDown() && RestartListener.isAllReady()) {
    //println 'Jenkins is restarting.'
    try {
        Jenkins.instance.restart()
        println 'safe-restart'
    }
    catch(Exception e) {
        println 'restart-required'
    }
}
else if(Jenkins.instance.isQuietingDown() && !RestartListener.isAllReady()) {
    //println 'Shutdown mode is on but builds are still occuring.'
    println 'tried-restart-but-building'
}
else {
    //println 'Jenkins is ready for use.'
    println 'ready'
}

null
EOF
}

#
# FUNCTIONS
#

function jenkins_script_console() {
  echo "Calling jenkins_script_console $1" >&2
  ${CURL} --data-urlencode "script=$(eval "$1")" ${JENKINS_WEB}/scriptText
}

#CSRF protection support
function is_crumbs_enabled() {
  use_crumbs="$( $CURL -s ${JENKINS_WEB}/api/json?pretty=true 2> /dev/null | python -c 'import sys,json;exec "try:\n  j=json.load(sys.stdin)\n  print str(j[\"useCrumbs\"]).lower()\nexcept:\n  pass"' )"
  if [ "${use_crumbs}" = "true" ]; then
    return 0
  fi
  return 1
}

#CSRF protection support
function get_crumb() {
  ${CURL} -s ${JENKINS_WEB}/crumbIssuer/api/json | python -c 'import sys,json;j=json.load(sys.stdin);print j["crumbRequestField"] + "=" + j["crumb"]'
}

#CSRF protection support
function csrf_set_curl() {
  if is_crumbs_enabled; then
    if [ ! "${CSRF_CRUMB}" = "$(get_crumb)" ]; then
      if [ -n "${CSRF_CRUMB}" ]; then
        #remove existing crumb value from curl command
        CURL="$(echo "${CURL}" | sed "s/ -d ${CSRF_CRUMB}//")"
      fi
      export CSRF_CRUMB="$(get_crumb)"
      export CURL="${CURL} -d ${CSRF_CRUMB}"
      echo "Using crumbs for CSRF support." >&2
    elif ! echo "${CURL}" | grep -F "${CSRF_CRUMB}" &> /dev/null; then
      export CURL="${CURL} -d ${CSRF_CRUMB}"
      echo "Using crumbs for CSRF support." >&2
    fi
  fi
}

function is_auth_enabled() {
  no_authentication="$( $CURL -s ${JENKINS_WEB}/api/json?pretty=true 2> /dev/null | python -c 'import sys,json;exec "try:\n  j=json.load(sys.stdin)\n  print str(j[\"useSecurity\"]).lower()\nexcept:\n  pass"' )"
  #check if authentication is required.;
  #if the value of no_authentication is anything but false; then assume authentication
  if [ ! "${no_authentication}" = "false" ]; then
    echo -n "Authentication required..." >&2
    if [ -n "${JENKINS_AUTH}" ]; then
      echo "DONE" >&2
      return 0
    else
      echo "FAILED" >&2
      echo "Could not set authentication." >&2
      echo "Missing environment variable: JENKINS_AUTH" >&2
      exit 1
    fi
  fi
  return 1
}

case "$1" in
  -h|--help)
    cat <<- "EOF"
SYNOPSIS
  jenkins_admin_tasks.sh [command]

DESCRIPTION
  Basic admin tasks.

COMMANDS

  --enable-shutdown-mode, -s
  --disable-shutdown-mode, +s
  --safe-restart

ENVIRONMENT

  JENKINS_AUTH - user:password
  JENKINS_WEB - http://example.com/jenkins
EOF
    exit 1
esac

if is_auth_enabled; then
  export CURL="curl -s --user $JENKINS_AUTH"
fi
csrf_set_curl

case "$1" in
  --enable-shutdown-mode|-s)
    jenkins_script_console script_enable_shutdown_mode
    ;;
  --disable-shutdown-mode|+s)
    jenkins_script_console script_disable_shutdown_mode
    ;;
  --safe-restart)
    jenkins_script_console script_safe_restart
    ;;
  *)
    echo 'Invalid command, see -h or --help' >&2
    exit 1
esac
