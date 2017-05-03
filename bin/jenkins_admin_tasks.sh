#!/bin/bash
#Created by Sam Gleske
#Thu Jun 30 09:40:06 PDT 2016
#Mac OS X 10.11.5
#Darwin 15.5.0 x86_64
#GNU bash, version 4.3.11(1)-release (x86_64-apple-darwin13.2.0)
#curl 7.43.0 (x86_64-apple-darwin15.0) libcurl/7.43.0 SecureTransport zlib/1.2.5

[ -e "${HOME}/.jenkins-bashrc" ] && source "${HOME}/.jenkins-bashrc"
JENKINS_WEB="${JENKINS_WEB:-http://localhost:8080/}"

#remove trailing slash
JENKINS_WEB="${JENKINS_WEB%/}"

export JENKINS_WEB
export JENKINS_CALL_ARGS="-m POST --data-string script= ${JENKINS_WEB}/scriptText -d"

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

function script_kill_day_old_jobs() {
  cat <<'EOF'
/*
    Copyright (c) 2015-2017 Sam Gleske - https://github.com/samrocketman/jenkins-script-console-scripts

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
   This script kills all builds which have been running longer than one day.
   This helps to keep a Jenkins instance healthy and executors free from
   existing stale build runs.

   Supported types to kill:
       FreeStyleBuild
       WorkflowRun (Jenkins Pipelines)
*/

import hudson.model.FreeStyleBuild
import hudson.model.Job
import hudson.model.Result
import hudson.model.Run
import java.util.Calendar
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowRun

//24 hours in a day, 3600 seconds in 1 hour, 1000 milliseconds in 1 second
long time_in_millis = 24*3600*1000
Calendar rightNow = Calendar.getInstance()

Jenkins.instance.getAllItems(Job.class).findAll { Job job ->
    job.isBuilding()
}.collect { Job job ->
    job.getBuilds().findAll { Run run ->
        run.isBuilding() && ((rightNow.getTimeInMillis() - run.getStartTimeInMillis()) > time_in_millis)
    }
}.each { List listOfRuns ->
    if(listOfRuns) {
        //the listOfRuns is not empty
        listOfRuns.each { Run item ->
            if(item instanceof WorkflowRun) {
                WorkflowRun run = (WorkflowRun) item
                run.doKill()
                println "Killed ${run}"
            } else if(item instanceof FreeStyleBuild) {
                FreeStyleBuild run = (FreeStyleBuild) item
                run.executor.interrupt(Result.ABORTED)
                println "Killed ${run}"
            } else {
                println "WARNING: Don't know how to handle ${item.class}"
            }
        }
    }
}

//null means there will be no return result for the script
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
    println 'shutdown-mode-not-enabled'
}

null
EOF
}

#
# FUNCTIONS
#

function jenkins_script_console() {
  echo "Calling jenkins_script_console $1" >&2
  jenkins-call-url <("$1")
}

if grep -- '-h\|--help' <<< "$*" &> /dev/null; then
  cat <<- "EOF"
SYNOPSIS
  jenkins_admin_tasks.sh [command]

DESCRIPTION
  Basic Jenkins server admin tasks.  Commands can be chained together.

COMMANDS

  --debug                      More verbose output.
  --disable-shutdown-mode, +s  Disable shutdown mode.
  --enable-shutdown-mode, -s   Enable shutdown mode.
  --safe-restart               Restart if Jenkins is in shutdown mode and
                               there's no in-progress executors.

ENVIRONMENT

  JENKINS_WEB - http://example.com/jenkins
EOF
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --disable-shutdown-mode|+s)
      jenkins_script_console script_disable_shutdown_mode
      ;;
    --enable-shutdown-mode|-s)
      jenkins_script_console script_enable_shutdown_mode
      ;;
    --kill-day-old-jobs|-k)
      jenkins_script_console script_kill_day_old_jobs
      ;;
    --safe-restart|-r)
      jenkins_script_console script_safe_restart
      ;;
    --debug)
      export JENKINS_CALL_ARGS="-v -v ${JENKINS_CALL_ARGS}"
      ;;
    *)
      echo 'Invalid command, see -h or --help' >&2
      exit 1
  esac
  shift
done
