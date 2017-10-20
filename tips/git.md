# Cherry-pick merge commits as single diff

This is useful to cherry-pick merged changes rather performing a squash on all
of the commits.  This is essentially the same thing.

    git cherry-pick -m 1 5a5f9c5

Where `5a5f9c5` is a merge commit.  One can also see the changelog of a branch
only showing merge commits.

    git log --first-parent master

This is essentially the equivalent of squashing commits from the branch where
the changes were merged from.

# Searching git history contents

Find a file in history.

    git rev-list --all -- 'somefile'

Search the contents of a file in the current checkout.

    git grep <regexp>

Search all of the history for the contents.

    git rev-list --all | xargs git grep <regexp>

Limit search all of the history on just a specific file.

    git grep <regexp> $(git rev-list --all -- somefile)

# Deploy GitHub Pages

Using rsync to deploy github pages from a build directory.

    rsync -av --exclude '.git' --delete-after ./build/doc/groovydoc/ ./
