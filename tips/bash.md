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
