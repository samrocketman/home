# Screen shortcuts

A reminder of useful screen shortcuts for administering remote systems with
dodgy connectivity.

### Command line commands:

* Start a new session: `screen`
* List existing sessions: `screen -ls`
* Resume an old session (ID at the end is optional): `screen -r [ID]`
* Force detach an existing session (ID at the end is optional): `screen -D [ID]`

### Session management commands in-program shortcuts

* Access any command menu via meta command: `CTRL+A` (or `^A` for short)
* Access command line help: `CTRL+A`, `?` (or `^A`, release and `?`)
* Create a new terminal: `CTRL+A`, `c` (or press `^A`, release and then `c`)
* Rename current terminal title: `CTRL+A`, `SHIFT+A` (or press `^A`, release and
  then `A`)
* List open terminals with titles: `CTRL+A`, `"` (or press `^A`, release and
  then `"`)
  - To Navigate use the arrow keys and press ENTER on the terminal you wish to
    see.
* Detach from current session to resume later: CTRL+A, d (or ^A, release and
  then d)

### Text scrolling commands in-program shortcuts

* Scroll up in command output: `CTRL+A`, `ESC`, navigate with arrows (`^A`,
  release and press `ESC`, arrow keys to move around)
* Abort scrolling in command output: `ESC` (only while in scroll mode)
* Copy text: Move cursor to begining of text, press `ENTER` to start selection,
  move cursor to end, press `ENTER` to copy.
* Paste copied text onto command line: `CTRL+A`, `]` (or press `^A`, release and
  then `]`)

### Window management commands in-program shortcuts

* Split screens to see multiple terminals: `CTRL+A`, `SHIFT+S` (or `^A`, release
  and then `S`)
* Move to next split window: `CTRL+A`, `TAB` (or `^A`, release and then `TAB`)
* Close a split window: `CTRL+A`, `SHIFT+Q` (or `^A`, release and then `Q`)

Notes on window management:

- Alternately, you can detach and re-attach the session which removes all screen
  splitting.
- All screen commands apply to the currently selected window.  The shortcuts are
  the same for each window.
