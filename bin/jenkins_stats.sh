#!/bin/bash
#Created by Sam Gleske
#Thu Sep  1 10:36:06 PDT 2016
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-36-generic x86_64
#curl 7.47.0 (x86_64-pc-linux-gnu) libcurl/7.47.0 GnuTLS/3.4.10 zlib/1.2.8 libidn/1.32 librtmp/2.3

#DESCRIPTION
#  Executes a script console script to generate live stats from Jenkins.

JENKINS_WEB="${JENKINS_WEB:-http://localhost:8080/}"
#remove trailing slash
JENKINS_WEB="${JENKINS_WEB%/}"
CURL="${CURL:-curl}"
GHE_CREDENTIALS="${GHE_CREDENTIALS:-}"

#
# SCRIPT CONSOLE SCRIPTS
#

function script_get_project_stats() {
  cat <<'EOF'


import jenkins.model.Jenkins
import groovy.transform.Field

//globally scoped vars
@Field Set projects = []
@Field HashMap count_by_type = [:]
count = 0
jobs_with_builds = 0
organizations = 0

void count_stats(def j) {
  j.items.each { i ->
    if('Folder'.equals(i.class.simpleName)) {
      count_stats(i)
      organizations++
      return
    }
    if(i.getNextBuildNumber() > 1) {
      jobs_with_builds++
    }
    projects << "${j.displayName}/${i.displayName.split(' ')[0]}"
    count++
    if(!count_by_type[i.class.simpleName]) {
      count_by_type[i.class.simpleName] = 1
    }
    else {
      count_by_type[i.class.simpleName]++
    }
  }
}

count_stats(Jenkins.instance)

println "Number of Organizations: ${organizations}"
println "Number of Projects: ${projects.size()}"
println "Number of Jenkins jobs: ${count}"
println "Jobs with more than one build: ${jobs_with_builds}"
println "Count of projects by type."
count_by_type.each {
  println "  ${it.key}: ${it.value}"
}
//null because we don't want a return value in the Script Console
null
EOF
}

#
# FUNCTIONS
#

function jenkins_script_console() {
  echo "Calling jenkins_script_console $1"
  ${CURL} --data-urlencode "script=$(eval "$@")" ${JENKINS_WEB}/scriptText
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
      echo "Using crumbs for CSRF support."
    elif ! echo "${CURL}" | grep -F "${CSRF_CRUMB}" &> /dev/null; then
      export CURL="${CURL} -d ${CSRF_CRUMB}"
      echo "Using crumbs for CSRF support."
    fi
  fi
}

function is_auth_enabled() {
  no_authentication="$( $CURL -s ${JENKINS_WEB}/api/json?pretty=true 2> /dev/null | python -c 'import sys,json;exec "try:\n  j=json.load(sys.stdin)\n  print str(j[\"useSecurity\"]).lower()\nexcept:\n  pass"' )"
  #check if authentication is required.;
  #if the value of no_authentication is anything but false; then assume authentication
  if [ ! "${no_authentication}" = "false" ]; then
    echo -n "Authentication required..."
    if [ -n "${GHE_CREDENTIALS}" ]; then
      echo 'DONE'
      return 0
    else
      echo 'FAILED'
      echo 'Could not set authentication.'
      echo 'Missing environment variable: ${GHE_CREDENTIALS}'
      echo 'export GHE_CREDENTIALS=user:oauth_token'
      exit 1
    fi
  fi
  return 1
}

#
# MAIN EXECUTION
#

#try enabling authentication
if is_auth_enabled; then
  export CURL="${CURL} -u ${GHE_CREDENTIALS}"
fi

#try enabling CSRF protection support
csrf_set_curl
jenkins_script_console script_get_project_stats
