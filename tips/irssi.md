# irssi IRC client

[irssi is an IRC client][irssi].

Here's my cheat sheet of irssi commands which are quick and easy to learn.  This
document makes it easy for me to share out irssi tips.

My favorite IRC networks include:

```
irc.freenode.net
irc.gimp.org (for #gimp channel)
irc.rizen.net
```

### Install irssi

On Mac

    brew install irssi

On Ubuntu

    sudo apt install irssi

### Start and connect to a network

Start irssi from the terminal.

    irssi

From within irssi, connect to a network with `/connect`.

    /connect -tls irc.freenode.net

`-tls` option is important to connect securely so that passwords sent over the
wire are confidential.

### Common commands

IRC commands are case insensitive.

| **Command**      | **Function**                                          |
| ---------------- | ----------------------------------------------------- |
| `/quit`          | Exit `irssi`.                                         |
| `/nick NAME`     | Change your username<sup>1</sup>.                     |
| `ESC N`          | Switch tabs<sup>2</sup>. `N` is a number between 1-9. |
| `ESC 1`          | Brings you back to the main connect window.           |
| `/join #channel` | Join a channel named `#channel` for chatting.         |
| `/wc`            | Close a channel or chat.  Short for "window close".   |
| `/msg SOMEUSER`  | This is a direct message to a user.                   |

Notes

1. Some usernames are restricted because they're registered and owned by someone
   else.
2. `ALT N` also works but some applications hijack the shortcut.  `ESC N` is the
   most reliable way of switching windows in `irssi`.

### Register and log into freenode

Register your account by running the following command.

    /nick myusername
    /msg NickServ REGISTER mypassword me@example.com

Log into your registered account after connecting to freenode.

    /nick myusername
    /msg NickServ IDENTIFY mypassword

# See also

Freenode and other networks commonly have pseudo user services that users can
interact with to manage their account, channels, and interactions with other
users.  For example, Freenode has ChanServ, MemoServ, and NickServ.

ChanServ help.  Create and manage your own channels.

    /msg chanserv help

MemoServ help.  Send memos to offline registered users.  They'll get them when
they log back in.

    /msg memoserv help

NickServ help.  Manage your account with the network.

    /msg nickserv help

[irssi]: https://irssi.org/
