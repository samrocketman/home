# home

In other words files for my `$HOME`.  This is a handy little git repository I
use to track all of the files I use in day to day stuff.

## List of README files.

Here is a summary of README files in this repository where you can learn more
about that area.

* [bin/README.md](bin/README.md)
* [dotfiles/.git_template/README.md](dotfiles/.git_template/README.md)
* [raspi/README.md](raspi/README.md)

Generate bullet list of readme files:

    find . -type f -iname 'readme*' | while read x;do echo "* [${x#./}](${x#./})";done

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

Multi-file editing with `:bufdo`.  e.g.

    :bufdo %s/foo/bar/g

Auto-format blocks of text to 80 chars wide.

    #select block of text
    V
    #format block of text
    gq
    #see also :help gq

# Get HTTP status from URL using HEAD method

This can be used in bash scripts or other type of status scripts to get the raw
HTTP code without retrieving the content of the page using the HTTP `HEAD`
method.  If you want to pass through `3XX` redirects and get the status of the
final destination then also pass in `-L` option.  See `curl(1)` man page for
explanation of options.

    curl -siI -w "%{http_code}\\n" -o /dev/null https://www.google.com/

# Create a socks proxy using SSH

`ssh -ND 1080 <some other host>` and then configure your normal browser to use
that as a proxy (`localhost:1080`).

# Cherry-pick merge commits as single diff

This is useful to cherry-pick merged changes rather performing a squash on all
of the commits.  This is essentially the same thing.

    git cherry-pick -m 1 5a5f9c5

Where `5a5f9c5` is a merge commit.  One can also see the changelog of a branch
only showing merge commits.

    git log --first-parent master

This is essentially the equivalent of squashing commits from the branch where
the changes were merged from.

# Deploy GitHub Pages

Using rsync to deploy github pages from a build directory.

    rsync -av --exclude '.git' --delete-after ./build/doc/groovydoc/ ./

# Run docker images with dumb-init

Docker images should have better process handling.  [Yelp
`dumb-init`][dumb-init] is a nice basic init written in C.

    docker run -d -v /path/to/dumb-init:/dumb-init:ro --entrypoint=/dumb-init <image> <command>

# Searching git history contents

Find a file in history.

    git rev-list --all -- 'somefile'

Search the contents of a file in the current checkout.

    git grep <regexp>

Search all of the history for the contents.

    git rev-list --all | xargs git grep <regexp>

Limit search all of the history on just a specific file.

    git grep <regexp> $(git rev-list --all -- somefile)

[dumb-init]: https://github.com/Yelp/dumb-init/issues/74#issuecomment-217669450
