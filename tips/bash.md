# bash tips

See the exit status of each command in a one liner pipeline.

    echo ${PIPESTATUS[@]}

# Get HTTP status from URL using HEAD method

This can be used in bash scripts or other type of status scripts to get the raw
HTTP code without retrieving the content of the page using the HTTP `HEAD`
method.  If you want to pass through `3XX` redirects and get the status of the
final destination then also pass in `-L` option.  See `curl(1)` man page for
explanation of options.

    curl -siI -w "%{http_code}\\n" -o /dev/null https://www.google.com/

See an [example of a script using this](../bin/jenkins_wait_reboot_done.sh).

# Locking scripts forcing serialization

Sometimes, allowing only a single instance of a script to run is desired.
The `flock` command makes use of the `floc()` Linux Kernel API to open and
maintain an exclusive lock on a file.

```bash
#!/bin/bash

# exit this program on the first non-zero exit code of a command
set -e

# Open a write lock on a file which is maintained globally across scripts by
# the Linux Kernel.  Additionally, if a lock is successfully obtained then this
# script will automatically delete the lock.
function lock() {
  local fd="${1:-200}"
  local lock_file="${2:-/tmp/script.lock}"

  eval "exec ${fd}> \"${lock_file}\""
  flock -n "${fd}" || (
    echo "Error: could not obtain exclusive lock on $lock_file." >&2
    return 1
  ) && trap "unlock ${fd} '${lock_file}'" EXIT
}

# Releases the write lock on a file.
function unlock() {
  local fd="${1:-200}"
  local lock_file="${2:-/tmp/script.lock}"
  #remove the file so it is non-blocking on other scripts
  rm -f "${lock_file}"
  #release the exclusive lock
  eval "exec ${fd}>&-"
}

function main() {
  #do some main code here
  echo "entered main"
  sleep 3
}

# obtain exclusive lock or immediately exit
lock
# execute main program
main

# unlock is not necessary here because the lock will auto-release and delete
# the lock file on exit.  However, sometimes it is useful to release the lock
# in the middle of the script.
unlock
```

In the above script, sometimes waiting for the lock is desired instead of
exiting immediately.  The proper way of waiting for the file lock is with a
while loop.

    #wait until lock is obtained
    while ! lock 2> /dev/null; do
      sleep 1
    done
    main

Ideas for this code was partially taken from [Elegant Locking of BASH
Program][locking].

[locking]: http://www.kfirlavi.com/blog/2012/11/06/elegant-locking-of-bash-program/
