"this is a comment
"type :help command to see the vim help docs for that command
:filetype on
:au FileType c,cpp,java set cindent
"will display the trailing space
:highlight ExtraWhitespace ctermfg=Grey ctermbg=LightGrey
:autocmd ColorScheme * highlight ExtraWhitespace ctermfg=Grey ctermbg=LightGrey
:au BufWinEnter * let w:m2=matchadd('ExtraWhitespace', '\s\+\%#\@<!$', -1)
"highlight lines longer than 80 chars in red
":au BufWinEnter *.py let w:m2=matchadd('ErrorMsg', '\%>79v.\+', -1)

set nocompatible
set shiftwidth=2
"showmode indicates input or replace mode at botto
set showmode
set showmatch
"shortcut for toggling paste while in insert mode, press F2 key
set pastetoggle=<f2>
set backspace=2
"hlsearch for when there is a previous search pattern, highlight all its matches.
set hlsearch
"ruler shows line and char number in bottom right of vim
set ruler
"each line has line number prepended
set number
"expandtab means tabs create spaces in insert mode, softtabstop is the number of spaces created
"tabstop affects visual representation of tabs only
set tabstop=4
set expandtab
set softtabstop=2

"always show status and tabs
set laststatus=2
"set showtabline=2

"ignore case
set ignorecase

"set background=light
set background=dark
set autoindent
if &t_Co > 1 
  syntax enable
endif

":w!! will ask for password when trying to write to system files
cmap w!! %!sudo tee > /dev/null %

set incsearch

"This executes a command and puts output into a throw away scratch pad
"source: http://vim.wikia.com/wiki/Display_output_of_shell_commands_in_new_window
function! s:ExecuteInShell(command, bang)
  let _ = a:bang != '' ? s:_ : a:command == '' ? '' : join(map(split(a:command), 'expand(v:val)'))
  if (_ != '')
    let s:_ = _
    let bufnr = bufnr('%')
    let winnr = bufwinnr('^' . _ . '$')
    silent! execute  winnr < 0 ? 'belowright new ' . fnameescape(_) : winnr . 'wincmd w'
    setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile wrap number
    silent! :%d
    let message = 'Execute ' . _ . '...'
    call append(0, message)
    echo message
    silent! 2d | resize 1 | redraw
    silent! execute 'silent! %!'. _
    silent! execute 'resize ' . line('$')
    silent! execute 'syntax on'
    silent! execute 'autocmd BufUnload <buffer> execute bufwinnr(' . bufnr . ') . ''wincmd w'''
    silent! execute 'autocmd BufEnter <buffer> execute ''resize '' .  line(''$'')'
    silent! execute 'nnoremap <silent> <buffer> <CR> :call <SID>ExecuteInShell(''' . _ . ''', '''')<CR>'
    silent! execute 'nnoremap <silent> <buffer> <LocalLeader>r :call <SID>ExecuteInShell(''' . _ . ''', '''')<CR>'
    silent! execute 'nnoremap <silent> <buffer> <LocalLeader>g :execute bufwinnr(' . bufnr . ') . ''wincmd w''<CR>'
    nnoremap <silent> <buffer> <C-W>_ :execute 'resize ' . line('$')<CR>
    silent! syntax on
  endif
endfunction
command! -complete=shellcmd -nargs=* -bang Scratchpad call s:ExecuteInShell(<q-args>, '<bang>')
command! -complete=shellcmd -nargs=* -bang Scp call s:ExecuteInShell(<q-args>, '<bang>')
