"this is a comment
"type :help command to see the vim help docs for that command

"this should be first always according to help docs if going to set it
set nocompatible

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" Navigating folds (collapsed code sections).  Run from normal mode.
"   zM - Shortcut to close all folds.
"   zR - Shortcut to open all folds.
"   zc - Close the current fold while cursor is inside of fold.
"   zo - Open a fold which is under the cursor.
"   l  - Open a fold which is under the cursor.
"   h  - Open a fold which is under the cursor.
"   gg - Shortcut to jump up to this menu.
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" OPTIONS FOR ALL FILES UNLESS OVERRIDDEN BY FILETYPE {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""

"if the number of colors supported by terminal is > 1 enable syntax highlighting
if &t_Co > 1
  syntax enable
endif
"enable filetype detection
:filetype on
"number of spaces to shift when using >> or << command in normal mode
set shiftwidth=2
"showmode indicates input or replace mode at bottom
set showmode
"showmatch briefly jumps to the line as you search
set showmatch
"when backspacing will backspace over eol, autoindent, and start
set backspace=2
"hlsearch for when there is a previous search pattern, highlight all its matches.
set hlsearch
"ruler shows line and char number in bottom right of vim
set ruler
"each line has line number prepended
set number
"scrolloff which keeps screen lines above and below the cursor when scrolling
set so=7
"expandtab means tabs create spaces in insert mode, softtabstop is the number of spaces created
"tabstop affects visual representation of tabs only
set tabstop=8
set expandtab
set softtabstop=2
set incsearch
"always show status bar at bottom
set laststatus=2
"always show tab bar at the top
"set showtabline=2
"ignore case sensitivity
set ignorecase
"Modify vim terminal colors based on the terminal background being light or dark
"set background=light
set background=dark
"when pressing ENTER will automatically indent the line
set autoindent

"filebrowser settings
let g:netrw_liststyle=3

"""""""""""""""""""""""""""""
" FUNCTION KEY SHORTCUTS {{{1
"""""""""""""""""""""""""""""

" F1 key - show vim help; same as :help
" F2 key - Toggle paste or nopaste
" F3 key - Toggle scrollbinding to scroll multiple windows in tandem
" F4 key - Toggle highlighting lines longer than 80 chars

"shortcut for toggling paste while in insert mode, press F2 key
set pastetoggle=<f2>
"shortcut for toggling scrollbinding; press F3 key
nnoremap <F3> :set scb! scb?<CR>
"toggle highlight lines longer than 80 chars in red; press F4 key
nnoremap <F4> :call ToggleErrorWidth()<CR>

"""""""""""""""""""""""""""""
" COLOR SETTINGS {{{1
"""""""""""""""""""""""""""""

:hi ColorColumn ctermbg=8 guibg=DarkGrey
:hi Folded ctermbg=5 ctermfg=15 guibg=DarkMagenta guifg=White
":hi Folded ctermbg=4 ctermfg=0 guibg=DarkBlue guifg=Black

"""""""""""""""""""""""""""""
" FUNCTIONS {{{1
"""""""""""""""""""""""""""""

" Toggles highlighting characters which go over 80 character width limit and
" adds a bar as a column to visibly display the limit.  This function will
" toggle it on and off.
func ToggleErrorWidth()
  if exists('w:errorwidth')
    call matchdelete(w:errorwidth)
    unlet w:errorwidth
    :setlocal colorcolumn=
  else
    let w:errorwidth=matchadd('ErrorMsg', '\%>80v.\+', -1)
    :setlocal colorcolumn=81
  endif
endfunc

" On markdown files, header sections and code blocks are collapsed by this
" fold-expr function.  See also :help fold-expr
" Special behavior includes:
"   - The fist section heading is not folded because this is typically an
"     introduction.
"   - Section headings get folded
"   - Code blocks get folded nested under section headings.
"   - Reference-style markdown links are excluded from folding.  I typically
"     put reference-style links at the end of a markdown file.
func FoldMarkdownHeadersAndCode()
  " initialize buffer variables (global to the document)
  if !exists('b:markdown_code')
    let b:markdown_code = v:false
  endif
  if !exists('b:collapse_markdown_header')
    let b:collapse_markdown_header = false
  endif
  " local function variables
  let l:thisline = getline(v:lnum)
  let l:depth = len(matchstr(thisline, '^#\+'))
  " this logic will return a fold-expr based on conditions
  if l:thisline =~ '^```.*$' " open or closing a code block
    if b:markdown_code
      let b:markdown_code = v:false
      return "s1"
    else
      let b:markdown_code = v:true
      return "a1"
    endif
  endif
  if l:depth > 0
    if !b:markdown_code && b:collapse_markdown_header
      return ">1"
    endif
    let b:collapse_markdown_header = v:true
  endif
  let l:reference_link_expr = '^\[[^\]]\+\]: \+[^ ]\+$' " matches text like '[foo]: https://link/to/foo'
  if l:thisline =~ l:reference_link_expr " regex match to display reference links
      return "0"
  endif
  return "="
endfunc

" Custom titles for folded markdown sections and code blocks
func FoldTextMarkdown()
  let l:title = getline(v:foldstart)
  if l:title !~ '^```.*$' " section title
    let l:depth = len(matchstr(l:title, '^#\+'))
    if depth == 1
      return foldtext()
    endif
    " return a substituted title showing indented sub-section as |-
    let l:sub = repeat(' ', depth*2 - 2) . '|-'
    return substitute(foldtext(), '^\([^#]\+\)#\+\(.*\)$', '\1' . l:sub . '\2', '')
  endif
  " code block title
  let l:replace_expr = 'CODE BLOCK: \2 (\1)'
  if l:title == '```'
    let l:replace_expr = 'CODE BLOCK (\1)'
  endif
  return substitute(foldtext(), '^[^0-9]\+\([^:]\+\): ```\(.*\)$', l:replace_expr, '')
endfunc

"""""""""""""""""""""""""""""
" VIM SETTINGS SPECIFIC TO DIFFERENT FILE TYPES {{{1
"""""""""""""""""""""""""""""

" These are custom settings depending on which filetype is opened.  For
" instance, vim can behave diferently when it has a Java file open vs a shell
" script.
"
" To detect the filetype of your currenlty opened file then type the following:
"    :set filetype?
"
" Then create a setting which applies only to that filetype.

" automatically fold comments in .vimrc file
:autocmd BufNewFile,BufRead .vimrc setlocal foldmethod=marker foldexpr=0
"jenkins plugins are just zip files; see also :help zip
:autocmd BufReadCmd *.jpi,*.hpi call zip#Browse(expand("<amatch>"))
:autocmd BufNewFile,BufRead .gitconfig_settings setlocal filetype=gitconfig
:autocmd BufNewFile,BufRead *.gradle,Jenkinsfile setlocal filetype=groovy expandtab
:autocmd BufNewFile,BufRead *.md setlocal filetype=markdown
:autocmd BufNewFile,BufRead TODO setlocal filetype=markdown
:autocmd BufNewFile,BufRead *.jelly setlocal filetype=xml
"cfengine promises files
:autocmd BufNewFile,BufRead *.cf setlocal filetype=conf
"Set options in a specific way based on what type of file is opened
:autocmd FileType java,xml,python,markdown,make,gitconfig,groovy,cpp,go setlocal shiftwidth=4 tabstop=4 softtabstop=4
:autocmd FileType groovy setlocal expandtab
:autocmd FileType c,cpp,java,groovy setlocal cindent
"indent with tabs when following FileTypes are opened
:autocmd FileType make,gitconfig setlocal noexpandtab
"auto newline at 80 characters as you type and auto-format formatoptions+=a or fo+=a
"autoformatting can also be accomplished with gq see :help gq
:autocmd FileType markdown setlocal textwidth=80 foldmethod=expr foldexpr=FoldMarkdownHeadersAndCode() foldtext=FoldTextMarkdown()
"auto newline at 73 chars as you type. git commit messages are 73 chars wide on GitHub
:autocmd FileType gitcommit setlocal textwidth=73
"will highlight trailing white space with grey
:highlight ExtraWhitespace ctermfg=Grey ctermbg=LightGrey
:autocmd ColorScheme * highlight ExtraWhitespace ctermfg=Grey ctermbg=LightGrey
:autocmd BufWinEnter * let w:extrawhite=matchadd('ExtraWhitespace', '\s\+\%#\@<!$', -1)
"highlight lines longer than 80 chars in red
:autocmd BufWinEnter *.md,*.sh call ToggleErrorWidth()

""""""""""""""""
" CHARACTER MAPS {{{1
""""""""""""""""

":w!! will ask for password when trying to write to system files
"useful if you open a file as a user but need sudo to write to it as root
cmap w!! %!sudo tee > /dev/null %

" load pathogen only if it exists
" Sometimes I use pathogen... sometimes I don't.
" https://github.com/tpope/vim-pathogen
" https://github.com/rodjek/vim-puppet
" https://github.com/pearofducks/ansible-vim
" https://github.com/Xuyuanp/nerdtree-git-plugin
if filereadable(expand("~/.vim/autoload/pathogen.vim"))
    execute pathogen#infect()
    filetype plugin indent on
endif
