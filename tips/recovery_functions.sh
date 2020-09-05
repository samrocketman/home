# remove all aliases since they could affect functions
unalias -a

# a simple PS1 to know where you are located
PS1='${USER}:${PWD}$ '

# bash built-in recovery functions to emulate real common utilities
function ls() (
  for x in *; do
    filetype="-"
    if [ -d "$x" ]; then
      filetype="d"
      x+='/'
    elif [ -L "$x" ]; then
      filetype='l'
    elif [ -b "$x" ]; then
      filetype='b'
    fi
    if [ -r "$x" ]; then
      filetype+='r'
    else
      filetype+='-'
    fi
    if [ -w "$x" ]; then
      filetype+='w'
    else
      filetype+='-'
    fi
    if [ -x "$x" ]; then
      filetype+='x'
    else
      filetype+='-'
    fi
    echo "${filetype} ${x}"
  done
)
function cat() { until [ "$#" -eq 0 ]; do echo "$( < "$1" )"; shift; done; }
function cp() { cat "$1" > "$2"; }
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
        if [ ! -f "$filename" ]; then
            echo "WARNING: '${filename}' is a directory.  Skipping..." >&2
            continue
        fi
        count=0
        while read -r line; do
            ((count = count + 1))
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
