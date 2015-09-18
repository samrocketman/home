# Dynamic authors for git

This template directory is for git `pre-commit` hooks that determines which
author settings should be used depending on what origin domain is being
committed.  This was created out of the desire to have different authorship
depending on what git service is being used.

Research includes:

* [Global git hooks][global-hooks]
* [Git hook to make sure email exists][email-exists]

### Why and how?

I have many emails and work on many domains.  I needed a solution that would
allow me to use a different committer and author email depending on where I
needed to push my code.  Sometimes I worked in a corporate environment.
Sometimes I would work at a public source code hosting site (like GitHub).

This was born out of the fact that I needed this.  This hooks directory provides
what I like to call `authordomains`.  That is a different author depending on
what domain you're using.

You set your author settings for different domains.  Then a `pre-commit` git
hook will take those settings and set the name and email just for that
repository.  Under the hood it's basically doing the following.

    git config --local user.name 'Your Name'
    git config --local user.email 'youremail@domain.com'

### Setup

First, you need to copy this `.git_template` directory to your `$HOME`
directory.  Tell git that it needs to use your template for a `pre-commit` hook
when it clones new repositories.

    git config --global init.templatedir '~/.git_template'

Now, enable `authordomains` in your git settings.

    git config --global authordomains.enabled true

Add the credentials for your first domain (e.g. `github.com`).

    git config --global authordomains.github.com.name 'Your Name'
    git config --global authordomains.github.com.email 'youremail@domain.com'

##### Don't worry about missing domains

If you clone from a new domain, then fear not!  The `pre-commit` hook will tell
you that you're missing `user` and `email` author settings for that domain and
will abort your commit.  It even gives you helpful commands in which you can
copy to help you set up your name and email for that domain.

### Disable dynamic authors

If you ever need to disable the behavior of this `pre-commit` hook then simply
set the `authordomains.enabled` setting to any value other than `true`.  e.g.

    git config --global authordomains.enabled false

_**Please note:** this will only stop setting the local authors in your
repositories.  It will not remove them after they've been added.  Therefore, if
you want to use the global settings then you'll have to delete the settings
yourself._

    git config --local --unset user.name
    git config --local --unset user.email

### Defaults

In order for the `authordomains` helpful hints to be relevant it is recommended
you set your global `user.name` and `user.email`.  It will fill out the help
commands with those settings as recommended defaults.

    git config --global user.name 'Your Name'
    git config --global user.email 'youremail@domain.com'

### Already cloned repositories?

If you already have repositories cloned then they will not have the `pre-commit`
hook in place.  You can copy that `pre-commit` hook in with the following
one-liner.

    find . -type d -name '.git' | (while read x;do cp ~/.git_template/hooks/pre-commit "${x}"/hooks/;done)

[email-exists]: https://orrsella.com/2013/08/10/git-using-different-user-emails-for-different-repositories/
[global-hooks]: http://stackoverflow.com/questions/2293498/git-commit-hooks-global-settings
