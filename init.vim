call plug#begin('~/.config/nvim/autoload/plugged')

" PLUGINS
" ++++++++++++++++++++
" Color theme
Plug 'morhetz/gruvbox'

" Git support
Plug 'lewis6991/gitsigns.nvim'

" Semantic language support
Plug 'neovim/nvim-lspconfig'
"Plug 'ray-x/lsp_signature.nvim'

" hrsh7th's omni-completion requires neovim/nvim-lspconfig
Plug 'hrsh7th/cmp-nvim-lsp', {'branch': 'main'}
Plug 'hrsh7th/cmp-buffer', {'branch': 'main'}
Plug 'hrsh7th/cmp-path', {'branch': 'main'}
Plug 'hrsh7th/cmp-cmdline' 
Plug 'hrsh7th/nvim-cmp', {'branch': 'main'}
" Because nvim-cmp _requires_ snippets
Plug 'hrsh7th/cmp-vsnip', {'branch': 'main'}
Plug 'hrsh7th/vim-vsnip'

" Syntactic language support
Plug 'cespare/vim-toml'
Plug 'stephpy/vim-yaml'
Plug 'rust-lang/rust.vim'
Plug 'rhysd/vim-clang-format'
Plug 'plasticboy/vim-markdown'

" ++++++++++++++++++++++
call plug#end()

" Sets numbered rows in the UI
set number

" Sets color theme
"autocmd vimenter * ++nested colorscheme gruvbox
colorscheme gruvbox

"Rrust LSP
lua require'lspconfig'.rust_analyzer.setup({})

"Some bullshit that doesn't work
lua << EOF
  vim.diagnostic.config{
    virtual_text = false,
    signs = true,
    float = true,
    underline = true,
    update_in_insert = true,
    severity_sort = true,
  }
EOF

" Set updatetime for various functionality
set updatetime=250

" Define autocmd for CursorHold and CursorHoldI events
augroup DiagnosticFloat
  autocmd!
  autocmd CursorHold,CursorHoldI * call OpenDiagnosticFloat()
augroup END

" Function to open diagnostic float window, used with autocmd above
function! OpenDiagnosticFloat() abort
  lua vim.diagnostic.open_float(nil, {focus=false})
endfunction

" Custom keybinds and associated functions
" Jumps to a function definition by entering gd in normal mode
nnoremap <silent> gd :lua vim.lsp.buf.definition()<CR>

" Jumps to the use of a function by entering gu in normal mode
nnoremap <silent> gu :call JumpToFunctionUses()<CR>
function! JumpToFunctionUses() abort
    " Get the visually selected text
    let selected_text = getreg('v')

    " Escape special characters in the selected text for searching
    let escaped_text = escape(selected_text, '.*\[]^$~')

    " Search for occurrences of the selected text (function) using a global search
    execute 'vimgrep /' . escaped_text . '/j **/*.rs'

    " Open the quickfix window to display the search results
    copen
endfunction

lua <<EOF
  -- Set up nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- Set up lspconfig.
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
  require('lspconfig')['rust_analyzer'].setup {
    capabilities = capabilities,
    hoverAction = {
      maxLines = 30,
      MaxColumns = 120,
    },
  }
  -- Set up Git Signs
  require('gitsigns').setup {
  signs = {
    add          = { text = '│' },
    change       = { text = '│' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
  numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  watch_gitdir = {
    follow_files = true
  },
  attach_to_untracked = true,
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
    delay = 1000,
    ignore_whitespace = false,
    virt_text_priority = 100,
  },
  current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil, -- Use default
  max_file_length = 40000, -- Disable if file is longer than this (in lines)
  preview_config = {
    -- Options passed to nvim_open_win
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
  yadm = {
    enable = false
  },
}
EOF
