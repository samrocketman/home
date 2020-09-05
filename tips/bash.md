# bash tips

See the exit status of each command in a one liner pipeline.

    echo ${PIPESTATUS[@]}

# PDF file conversion

Use GhostScript to combine multiple PDFs into one.  The PDFs are combined in
order so shell globbing will list them alphabeticially.  To specify the order in
which the PDFs are combined, name them alphabetically.  Example: `page-1.pdf`,
`page-2.pdf`, `page-3.pdf`.

    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=/tmp/total.pdf *.pdf

Convert a set of images into a PDF book using ImageMagick.

    magick convert *.png images.pdf

ImageMagick installed by homebrew for Mac requires that `policy.xml` be modified
in order to allow converting to PDF.  On Mac, `policy.xml` can be found with:

    find /usr/local -maxdepth 7 -type f -name policy.xml

# Get HTTP status from URL using HEAD method

This can be used in bash scripts or other type of status scripts to get the raw
HTTP code without retrieving the content of the page using the HTTP `HEAD`
method.  If you want to pass through `3XX` redirects and get the status of the
final destination then also pass in `-L` option.  See `curl(1)` man page for
explanation of options.

    curl -siI -w "%{http_code}\\n" -o /dev/null https://www.google.com/

See an [example of a script using this](../bin/jenkins_wait_reboot_done.sh).

# Locking scripts forcing serialization

Ideas for this code was partially taken from [Elegant Locking of BASH
Program][locking].

Sometimes, allowing only a single instance of a script to run system-wide is
desired.  The `flock` command makes use of the `flock()` system call to open and
maintain an exclusive lock on a file.  This is the safest method in bash to
force unrelated programs to execute serially.

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
  #remove the lock file only if it is locked by this program
  if eval "{ >&${fd} ; }" &> /dev/null; then
    rm -f "${lock_file}"
  fi
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

# Worst-case system recovery

> You may find all of these functions availab within the source-able script
> [`recovery_functions.sh`](recovery_functions.sh).

When all utilities seem lost... you still have bash ;).  The following attempts
to use only bash builtin methods to emulate oft-used utilities.

> **Note:** `http_get` is kind of like `curl`.  In order to download binary data
> it requires `dd` to be available... unfortunately I could not get downloading
> binary data to work in bash using strictly shell builtins.

Copy and paste the following functions into a dead environment.

```bash
# remove all aliases since they could affect functions
unalias -a
# a simple PS1 to know where you are located
PS1='${USER}:${PWD}$ '

# bash built-in recovery functions
function ls() ( echo *; )
function pwd() { echo "${PWD}"; }
function cat() { until [ "$#" -eq 0 ]; do echo "$( < "$1" )"; shift; done; }
function catnull() {
    while IFS=$'\0' read -r -d $'\0' line; do
        echo "$line"
    done < "$1"
}
function env() {
    while IFS=$'\0' read -r -d $'\0' line; do
        echo "$line"
    done < /proc/self/environ
}
function grep() (
    local expr="$1"
    local filename=""
    local count=0
    shift
    until [ "$#" -eq 0 ]; do
        filename="$1"
        shift;
        count=0
        while read -r line; do
            ((count = count + 1))
            echo $expr
            if [ ! "$line" = "${line//${expr}/}" ]; then
                echo "${filename}:${count}:${line}"
            fi
        done < "${filename}"
    done;
)
function http_get() (
    if [ ! "$#" -eq 1 -a ! "$#" -eq 3 ]; then
        echo 'ERROR: must provide 1 or 3 arguments.' >&2
        echo 'Example usage:' >&2
        echo '    http_get example.com/' >&2
        echo '    http_get example.com 80 /' >&2
        return 1
    fi
    if [ "$#" = 1 ]; then
        if [ "$1" = "${1#*/}" ]; then
            echo 'ERROR: Must end with trailing slash.' >&2
            return 1
        fi
        connecthost="${1%%/*}"
        connectport=80
        path="/${1#*/}"
    else
        connecthost="$1"
        connectport="$2"
        path="$3"
    fi
    exec 3<>/dev/tcp/"${connecthost}/${connectport}"
    echo -e "GET ${path} HTTP/1.1\r\nHost: ${connecthost}\r\nConnection: close\r\n\r\n" >&3
    # print HTTP headers to stderr
    while read -d $'\r\n' -r line; do
        echo "$line" >&2
        # hack to prepare reading binary data
        if [ -z "$(echo "$line")" ]; then
            read -d $'\0' -N1 -r line
            break
        fi
    done <&3
    if type -P dd >&2; then
        dd <&3
    else
        # does not work for binary data...
        while IFS= read -N1 -u3 -r -s line; do echo -n "$line"; done
    fi
    # close the connection
    exec 3<&-
    exec 3>&-
)
function http_head() (
    exec 3<>/dev/tcp/"$1/$2"
    echo -e "HEAD $3 HTTP/1.1\r\nHost: ${1}\r\nConnection: close\r\n\r\n" >&3
    while read -r line; do echo "$line"; done <&3
    # close the connection
    exec 3<&-
    exec 3>&-
)
```

My take on useful commands using bash builtins when all appears lost.  You can then use them almost like their real counterparts.

Usage for files and navigation:

```bash
# print working directory
pwd

# list files in directory
ls

# cat two files into a third file
cat file1 file2 > file3

# read the environ from another process
catnull /proc/<PID>/environ

# show environment for current shell
env
```

Usage for websites:

```bash
# read headers for remote URL
http_head www.example.com 80 /

# download a plain HTML file
http_get www.example.com 80 / > index.html

# download a binary file (requires dd to be available)
http_get www.example.com 80 /file.png > file.png
```

[bash-eval]: https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-eval
[bash-exec]: https://www.gnu.org/software/bash/manual/html_node/Bourne-Shell-Builtins.html#index-exec
[bash-pe]: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
[bash-r]: https://www.gnu.org/software/bash/manual/html_node/Redirections.html
[flock]: http://manpages.ubuntu.com/cgi-bin/search.py?q=flock
[locking]: http://www.kfirlavi.com/blog/2012/11/06/elegant-locking-of-bash-program/
