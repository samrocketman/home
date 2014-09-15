# home

In other words files for my `$HOME`.  This is a handy little git repository I
use to track all of the files I use in day to day stuff.

## List of README files.

* [bin/README.md](bin/README.md)

Generate bullet list of readme files:

    find | grep -i readme | while read x;do readme="$(echo $x | sed 's#^\.##' | sed 's#^/##')";echo "* [$readme]($readme)";done

# ./bin/

This is user bin scripts I put in my ~/bin directory.

# ./dotfiles/

Some common dotfiles which I personally like to customize.

# Package must haves

I need the following packages to be highly productive at a minimum.

```
git
screen
vim
automake
autoconf
make
build-essential
```

# bash tips

See the exit status of each command in a one liner pipeline.

    echo ${PIPESTATUS[@]}

# vim tips

I use the following selection substitute command for converting bash variables
from `$var` to `${var}`.

    :'<,'>s#$\([^0-9(\{]\{1\}[^/{} '"()\\;.|`+*-]\+\)#${\1}#g

Here's that expression broken down.

    :'<,'> - perform a task on a text selection in vim
    s# - substitute using a hash as the expression delimiter
    $ - just a plain old dollar sign with no special meaning in this context
      \( - BEGIN regex group
        [ - BEGIN character class
          ^0-9(\{ - the carat (^) states that NOT the following characters
        ]\{1\} - END character class and only one character (redundant I think)
        [ - BEGIN character class
          ^/{} '"()\\;.|`+*- - The carat at the beginning denotes NOT these characters.  The hyphen at the end is literal.
        ]\+ - END character class one or more characters
      \) - END regex group
    #${\1}#g - replace expression to act globally on the line

# Get HTTP status from URL using HEAD method

This can be used in bash scripts or other type of status scripts to get the raw
HTTP code without retrieving the content of the page using the HTTP `HEAD`
method.  If you want to pass through `3XX` redirects and get the status of the
final destination then also pass in `-L` option.  See `curl(1)` man page for
explanation of options.

    curl -siI -w "%{http_code}\\n" -o /dev/null https://www.google.com/

