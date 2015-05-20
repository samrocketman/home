#!/bin/bash
#Created by Sam Gleske (https://github.com/samrocketman)
#Wed May 20 11:09:18 EDT 2015
#Mac OS X 10.9.5
#Darwin 13.4.0 x86_64
#GNU bash, version 3.2.53(1)-release (x86_64-apple-darwin13)
#curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5
#awk version 20070501
#java version "1.7.0_55"
#Java(TM) SE Runtime Environment (build 1.7.0_55-b13)
#Java HotSpot(TM) 64-Bit Server VM (build 24.55-b03, mixed mode)

#DESCRIPTION
#  Provisions a fresh Jenkins on a local laptop, updates the plugins, and runs
#  it.
#    1. Creates a JAVA_HOME.
#    2. Downloads Jenkins.
#    3. Updates the Jenkins plugins to the latest version.

#USAGE
#  Automatically provision and start Jenkins on your laptop.
#    mkdir ~/jenkins_testing
#    cd ~/jenkins_testing
#    provision_jenkins.sh
#  Kill and completely delete your provisioned Jenkins.
#    cd ~/jenkins_testing
#    provision_jenkins.sh purge
#  Update all plugins to the latest version using jenkins-cli
#    cd ~/jenkins_testing
#    provision_jenkins.sh update-plugins
#  Start or restart Jenkins.
#    cd ~/jenkins_testing
#    provision_jenkins.sh start
#    provision_jenkins.sh restart
#  Stop Jenkins.
#    provision_jenkins.sh stop

#
# USER CUSTOMIZED VARIABLES
#

#Latest Release
jenkins_url='http://mirrors.jenkins-ci.org/war/latest/jenkins.war'
#LTS Jenkins URL
#jenkins_url='http://mirrors.jenkins-ci.org/war-stable/latest/jenkins.war'
JENKINS_HOME="${JENKINS_HOME:-my_jenkins_home}"

#Get JAVA_HOME for java 1.7 on Mac OS X
#will only run if OS X is detected
if uname -rms | grep Darwin &> /dev/null; then
  JAVA_HOME="$(/usr/libexec/java_home -v 1.7)"
  PATH="${JAVA_HOME}/bin:${PATH}"
  echo "JAVA_HOME=${JAVA_HOME}"
  java -version
fi

export jenkins_url JENKINS_HOME JAVA_HOME PATH

#
# FUNCTIONS
#
function download_file() {
  #see bash man page and search for Parameter Expansion
  url="$1"
  file="${1##*/}"
  [ ! -e "${file}" ] && (
    echo -n "Waiting for ${url} to become available."
    while [ ! "200" = "$(curl -sLiI -w "%{http_code}\\n" -o /dev/null ${url})" ]; do
      echo -n '.'
      sleep 1
    done
    echo 'ready.'
    curl -SLo "${file}" "${url}"
  )
}

function start_or_restart_jenkins() {
  #start Jenkins, if it's already running then stop it and start it again
  if [ -e "jenkins.pid" ]; then
    echo -n 'Jenkins might be running so attempting to stop it.'
    kill $(cat jenkins.pid)
    #wait for jenkins to stop
    while ps aux | grep -v 'grep' | grep "$(cat jenkins.pid)" &> /dev/null; do
      echo -n '.'
      sleep 1
    done
    rm jenkins.pid
    echo 'stopped.'
  fi
  echo 'Starting Jenkins.'
  java -jar jenkins.war &> console.log &
  echo "$!" > jenkins.pid
}

function stop_jenkins() {
  if [ -e "jenkins.pid" ]; then
    echo -n 'Jenkins might be running so attempting to stop it.'
    kill $(cat jenkins.pid)
    #wait for jenkins to stop
    while ps aux | grep -v 'grep' | grep "$(cat jenkins.pid)" &> /dev/null; do
      echo -n '.'
      sleep 1
    done
    rm jenkins.pid
    echo 'stopped.'
  fi
}

function update_jenkins_plugins() {
  jenkins_cli='java -jar ./jenkins-cli.jar -s http://localhost:8080/ -noKeyAuth'
  #download the jenkins-cli.jar client
  download_file 'http://localhost:8080/jnlpJars/jenkins-cli.jar'
  echo 'Updating Jenkins Plugins using jenkins-cli.'
  UPDATE_LIST="$( $jenkins_cli list-plugins | awk '$0 ~ /\)$/ { print $1 }' )"
  if [ ! -z "${UPDATE_LIST}" ]; then
    $jenkins_cli install-plugin ${UPDATE_LIST}
  fi
}

function install_jenkins_plugins() {
  jenkins_cli='java -jar ./jenkins-cli.jar -s http://localhost:8080/ -noKeyAuth'
  #download the jenkins-cli.jar client
  download_file 'http://localhost:8080/jnlpJars/jenkins-cli.jar'
  echo 'Install Jenkins Plugins using jenkins-cli.'
  $jenkins_cli install-plugin $@
}

function force-stop() {
  kill -9 $(cat jenkins.pid)
  rm -f jenkins.pid
}

#
# main execution
#

case "$1" in
  update-plugins)
    update_jenkins_plugins
    echo 'Jenkins may need to be restarted.'
    ;;
  purge)
    force-stop
    rm -f console.log jenkins-cli.jar jenkins.pid jenkins.war
    rm -rf "${JENKINS_HOME}"
    ;;
  start|restart)
    start_or_restart_jenkins
    ;;
  stop)
    stop_jenkins
    ;;
  *)
    #provision Jenkins by default
    #download jenkins.war
    download_file ${jenkins_url}

    #create a JENKINS_HOME directory
    mkdir -p "${JENKINS_HOME}"
    echo "JENKINS_HOME=${JENKINS_HOME}"

    start_or_restart_jenkins

    update_jenkins_plugins

    install_jenkins_plugins git github github-oauth

    start_or_restart_jenkins

    echo 'Jenkins is ready.  Visit http://localhost:8080/'
esac

