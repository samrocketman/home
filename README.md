# home

In other words files for my `$HOME`.  This is a handy little git repository I use to track all of the files I use in day to day stuff.

## List of README files.

* [bin/README.md](bin/README.md)

Generate bullet list of readme files:

    find | grep -i readme | while read x;do readme="$(echo $x | sed 's#^\.##' | sed 's#^/##')";echo "* [$readme]($readme)";done

# ./bin/

This is user bin scripts I put in my ~/bin directory.

# ./dotfiles/

Some common dotfiles which I personally like to customize.
