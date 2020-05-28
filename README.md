# home

In other words files for my `$HOME`.  This is a handy little git repository I
use to track all of the files I use in day to day work and personal development.

## List of README files.

Here is a summary of README files in this repository where you can learn more
about that area.

- [bin/README.md](bin/README.md)
- [raspi/README.md](raspi/README.md)

# Program usage tips

Documentation on advanced usage of different programs I enjoy using (a.k.a.
cheatsheets).

- [tips/bash.md](tips/bash.md)
- [tips/docker.md](tips/docker.md)
- [tips/git.md](tips/git.md)
- [tips/gpg.md](tips/gpg.md)
- [tips/irssi.md](tips/irssi.md)
- [tips/ssh.md](tips/ssh.md)
- [tips/vim.md](tips/vim.md)

# Other directories

- `bin/` - This is user bin scripts I put in my ~/bin directory.
- `dotfiles/` - Some common dotfiles which I personally like to customize.

# Generate above lists

Generate bullet list of readme files:

```bash
find -s * -mindepth 1 -type f -iname 'readme*' -exec echo "- [{}]({})" \;
```

Generate bullet list of cheatsheets:

```bash
find -s tips -type f -iname "*.md" -exec echo "- [{}]({})" \;
```
