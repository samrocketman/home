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

### File locking background learning

To fully understand how the file locking script works it is best to study up on
the following topics.

- [Bash Parameter Expansion][bash-pe] - to learn about positional arguments `$1`
  and `$2` represented as `${1:-200}` and `${2:-/tmp/script.lock}`.  That format
  is documented as `${parameter:-word}`.  Which essentially sets a default value
  if an argument is not defined.
- [Bash Redirections][bash-r] - to learn about how `200>` documented as `n>` is
  used as a file descriptor to open a file for writing.  In this case, `200` is
  called a file descriptor.  `flock -n 200` creates a lock on the file which was
  opened for writing on file descriptor `200`.  The number `200` for the file
  descriptor was arbitrarily chosen and has no meaning.  The number could have
  been anything.  Keep in mind the following file descriptors are reserved
  unless otherwise redirected:
  - `0` is the file descriptor for stdin.
  - `1` is the file descriptor for stdout.
  - `2` is the file descriptor for stderr.
- [`eval` shell builtin][bash-eval] - which evaluates the string and executes it
  as if the user typed it.
- [`exec` shell builtin][bash-exec] - Without a command, bash opens and closes
  files for reading and writing based on the currently running shell in the
  script.  Example, `exec 200> /tmp/file` opens the file `/tmp/file` open for
  writing.  You can write to `/tmp/file` with `echo hello >&200` because you're
  redirecting file descript `1` (stdout) to write to file descriptor `200`.
- [`man 2 flock`][flock] - The `flock()` system call built into the Linux Kernel
  (used by the `flock` command).
- [`man flock`][flock] - the flock command.
- [`trap` shell builtin][bash-trap] - `trap` functions executed when events
  (a.k.a. signals) occur in the shell.  For example, if the script exits then it
  is an event.  If a command fails, then it is an event.  `trap` allows commands
  or functions to be executed when an event happens.  In this case, trap is used
  to automatically clean up file locks.

[bash-eval]: https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-eval
[bash-exec]: https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-exec
[bash-pe]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[bash-r]: https://www.gnu.org/software/bash/manual/html_node/Redirections.html
[flock]: http://manpages.ubuntu.com/cgi-bin/search.py?q=flock
[locking]: http://www.kfirlavi.com/blog/2012/11/06/elegant-locking-of-bash-program/
