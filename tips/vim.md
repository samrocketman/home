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
