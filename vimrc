source $VIMRUNTIME/defaults.vim
set syntax=on
set nocompatible
set expandtab
set scrolloff=0

set list
set lcs=tab:>\ ,trail:%

set noautoindent
set nosmartindent

let g:tabsize=4
let &tabstop=g:tabsize
let &shiftwidth=g:tabsize

set hlsearch incsearch
vnoremap K <esc>`<kdd`>p`<V`>
vnoremap J <esc>`>jdd`<PjV`>
vnoremap " <esc>`<i"<esc>`>la"<esc>
vnoremap ' <esc>`<i'<esc>`>la'<esc>
vnoremap ` <esc>`<i`<esc>`>la`<esc>
vnoremap ( <esc>`<i(<esc>`>la)<esc>
vnoremap { <esc>`<i{<esc>`>la}<esc>
vnoremap [ <esc>`<i[<esc>`>la]<esc>
nnoremap <S-tab> :tabprevious<CR>
nnoremap <tab>   :tabnext<CR>
inoremap <c-u> <esc>viwUea
cnoremap <C-Left> <S-Left>
cnoremap <C-Right> <S-Right>

let g:mapleader=','
let g:maplocalleader='-'

set showmatch
set matchtime=3

nnoremap <C-t> :tabnew<CR>
vnoremap <C-c> "+y
inoremap <C-v> <C-r><C-o>*
inoremap <C-g> <C-v>

colorscheme torte

if !&diff
  execute pathogen#infect()

  let g:ale_linters = {
  \ 'javascript': ['eslint'],
  \ 'python': ['flake8', 'mypy', 'pylint', 'pyright'],
  \ 'rust': ['analyzer']
  \ }
  let g:ale_fixers = {
  \ 'javascript': ['eslint'],
  \ 'powershell': ['trim_whitespace', 'remove_trailing_lines'],
  \ 'python': ['black'],
  \ 'rust': ['rustfmt', 'trim_whitespace', 'remove_trailing_lines']
  \ }
  let g:ale_fix_on_save = 1

  let g:ale_powershell_powershell_executable = 'powershell.exe'
  let g:ale_powershell_psscriptanalyzer_executable = 'powershell.exe'

  set completeopt=menu,menuone,preview,noselect,noinsert
  let g:ale_completion_enabled = 1

  nnoremap <localleader>r :ALEFindReferences<CR>
  nnoremap <localleader>h :ALEHover<CR>
  nnoremap <localleader>d :ALEGoToDefinition -tab<CR>
  nnoremap <localleader>D :ALEGoToDefinition -split<CR>

  nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeFocus<CR>
endif

set guioptions=
set number
set guifont=Monaco:h20
set statusline =%1*\ %n\ %*             "buffer number
set statusline +=%y                     "file type
set statusline +=%4*\ %<%F%*            "full path
set statusline +=%2*%m%*                "modified flag
set statusline +=%1*%=\ \ 0x%02B\ %*    "character under cursor
set statusline +=%1*%4c\ %*             "column number (line number given in text)
"set statusline +=%1*%4c/%l\ %*          "column number/line number
set statusline +=%1*%6o%*               "current total character number
"set statusline +=%2*%L%*\ \ %*         "total lines
set statusline +=%2*\ \ %3P             "percentage through file

set guifont=Consolas:h16

au GUIEnter * simalt ~x
