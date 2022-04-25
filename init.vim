set runtimepath^=C:\Program\ Files\Vim\vimfiles runtimepath+=C:\Users\steve\AppData\local\nvim
let &packpath = &runtimepath

set syntax=on
set nocompatible
set expandtab
set scrolloff=0
" Turn off audible bell
set vb t_vb=

set list
set lcs=tab:>\ ,trail:%

set noautoindent
set nosmartindent

let g:tabsize=4
let &tabstop=g:tabsize
let &shiftwidth=g:tabsize

set hlsearch incsearch

let g:mapleader=','
let g:maplocalleader='-'

vnoremap K <esc>`<kdd`>p`<V`>
vnoremap <leader>K K
vnoremap J <esc>`>jdd`<PjV`>
vnoremap <C-J> J
vnoremap " <esc>`>a"<esc>`<i"<esc>
vnoremap ' <esc>`>a'<esc>`<i'<esc>
vnoremap ` <esc>`>a`<esc>`<i`<esc>
vnoremap ( <esc>`>a)<esc>`<i(<esc>
vnoremap { <esc>`>a}<esc>`<i{<esc>
vnoremap [ <esc>`>a]<esc>`<i[<esc>
vnoremap _ <esc>`>a_<esc>`<i_<esc>
vnoremap - <esc>`>a-<esc>`<i-<esc>
vnoremap <leader>* <esc>`>a*<esc>`<i*<esc>
vnoremap <leader>< <esc>`>a><esc>`<i<<esc>
nnoremap <S-tab> :tabprevious<CR>
nnoremap <tab>   :tabnext<CR>
inoremap <c-u> <esc>viwUea
cnoremap <C-Left> <S-Left>
cnoremap <C-Right> <S-Right>
" TODO:  character not working, is this OK?
nnoremap <localleader>r :%s/.\[[0-9]\+m\?//g<CR>

set showmatch
set matchtime=3

nnoremap <C-t> :tabnew<CR>
vnoremap <C-c> "+y
inoremap <C-v> <C-r><C-o>*
inoremap <C-g> <C-v>
inoremap <C-BS> <C-W>
inoremap <S-BS> <BS>

"colorscheme torte

set mouse=a

if !&diff
  execute pathogen#infect()

  let g:ale_linters = {
  \ 'javascript': ['eslint'],
  \ 'python': ['flake8', 'mypy', 'pylint', 'pyright'],
  \ 'rust': []
  \ }
  "\ 'rust': ['analyzer']
  let g:ale_fixers = {
  \ 'javascript': ['eslint'],
  \ 'powershell': ['trim_whitespace', 'remove_trailing_lines'],
  \ 'python': ['black'],
  \ 'rust': ['rustfmt', 'trim_whitespace', 'remove_trailing_lines']
  \ }
  let g:ale_fix_on_save = 1

  let g:ale_powershell_powershell_executable = 'powershell.exe'
  let g:ale_powershell_psscriptanalyzer_executable = 'powershell.exe'

  let g:ale_rust_rustfmt_options = '--edition 2021'
  let g:ale_rust_cargo_use_clippy = 1
  let g:ale_rust_cargo_check_tests = 1
  let g:ale_rust_cargo_check_examples = 1

  nnoremap <localleader>b :VadreBreakpoint<CR>
  nnoremap <C-n> :NERDTreeMirror<CR>:NERDTreeFocus<CR>

  xmap ga <Plug>(EasyAlign)
  nmap ga <Plug>(EasyAlign)

  set completeopt=menu,menuone,noselect

  set shortmess+=c

  lua << EOF
  -- Setup nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
      end,
    },
    mapping = {
      ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<S-Tab>'] = cmp.mapping.select_prev_item(),
      ['<Tab>'] = cmp.mapping.select_next_item(),
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Insert,
      })
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' },
      { name = 'path' },
      { name = 'buffer' },
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
EOF

  nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
  nnoremap <silent> gd <cmd>tab split \| lua vim.lsp.buf.definition()<CR>
  nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
  nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
  nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
  nnoremap <silent> g0 <cmd>lua vim.lsp.buf.document_symbol()<CR>
  nnoremap <silent> gW <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
  nnoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
  nnoremap <silent> <localleader>wa <cmd>lua vim.lsp.buf.add_workspace_folder()<CR>
  nnoremap <silent> <localleader>wr <cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>
  nnoremap <silent> <localleader>wl <cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>
  nnoremap <silent> <localleader>D <cmd>tab split \| lua vim.lsp.buf.type_definition()<CR>
  nnoremap <silent> <localleader>rn <cmd>lua vim.lsp.buf.rename()<CR>
  nnoremap <silent> <localleader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
  nnoremap <silent> <localleader>e <cmd>lua vim.diagnostic.open_float()<CR>
  nnoremap <silent> [d <cmd>lua vim.diagnostic.goto_prev()<CR>
  nnoremap <silent> ]d <cmd>lua vim.diagnostic.goto_next()<CR>
  nnoremap <silent> <localleader>q <cmd>lua vim.diagnostic.setloclist()<CR>
  nnoremap <silent> <localleader>f <cmd>lua vim.lsp.buf.formatting()<CR>
  nnoremap <silent> gh :Lspsaga lsp_finder<CR>
  nnoremap <silent> <localleader>pp <cmd>lua require'telescope.builtin'.builtin{}<CR>
  nnoremap <silent> <localleader>fb <cmd>lua require'telescope.builtin'.buffers{}<CR>
  nnoremap <silent> <localleader>/ <cmd>lua require'telescope.builtin'.current_buffer_fuzzy_find{}<CR>
  nnoremap <silent> <localleader>fg <cmd>lua require'telescope.builtin'.git_files{}<CR>
  nnoremap <silent> <localleader>ff <cmd>lua require'telescope.builtin'.find_files{}<CR>
  nnoremap <silent> <localleader>rg <cmd>lua require'telescope.builtin'.live_grep{}<CR>
  nnoremap <silent> <localleader>cs <cmd>lua require'telescope.builtin'.colorscheme{}<CR>

  set background=dark
  colorscheme gruvbox
  let g:gruvbox_contrast = "hard"

  lua << EOF
  -- Setup lspconfig.
  local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

  local lspconfig = require('lspconfig')

  local on_attach = function(client, bufnr)
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Enable completion triggered by <c-x><c-o>
    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  end

  -- Enable some language servers with the additional completion capabilities offered by nvim-cmp
  local servers = { 'clangd', 'pyright', 'terraformls', 'tsserver' }
  for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
      on_attach = on_attach,
      capabilities = capabilities,
    }
  end

  lspconfig.rust_analyzer.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        assist = {
          importMergeBehavior = "last",
          importPrefix = "by_self",
        },
        cargo = {
          loadOutDirsFromCheck = true
        },
        procMacro = {
          enable = true
        },
        checkOnSave = {
          command = "clippy"
        },
      }
    },
  }
EOF

  lua << EOF
  require('rust-tools').setup({})
EOF

  lua << EOF
  -- require('nvim-treesitter')
  -- require 'lspsaga'.init_lsp_saga()
EOF
endif

set guioptions=
set number
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

au GUIEnter * simalt ~x
