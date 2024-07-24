" use :source $MYVIMRC to update without reloading nvim

" Plugin manager junegunn/vim-plug
"""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.config/nvim/autoload/plugged')

" Color theme
Plug 'morhetz/gruvbox'

" Git support
Plug 'lewis6991/gitsigns.nvim'

" Semantic language support
" Configured with Lua LSP config below
Plug 'neovim/nvim-lspconfig'

" hrsh7th's omni-completion requires neovim/nvim-lspconfig
Plug 'hrsh7th/cmp-nvim-lsp', {'branch': 'main'}
Plug 'hrsh7th/cmp-buffer', {'branch': 'main'}
Plug 'hrsh7th/cmp-path', {'branch': 'main'}
Plug 'hrsh7th/cmp-cmdline' 
Plug 'hrsh7th/nvim-cmp', {'branch': 'main'}
" Because nvim-cmp _requires_ snippets
Plug 'hrsh7th/cmp-vsnip', {'branch': 'main'}
Plug 'hrsh7th/vim-vsnip'

" Language syntax support
Plug 'cespare/vim-toml'
Plug 'stephpy/vim-yaml'
Plug 'rust-lang/rust.vim'
Plug 'rhysd/vim-clang-format'
"Plug 'plasticboy/vim-markdown'

" Fuzzy finder (with required dependancy)
Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" File explorer
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'

call plug#end()

" Sets basic UI elements
""""""""""""""""""""""""
" Sets (absolute) numbered rows in the UI
set number

" Sets nvim color theme
colorscheme gruvbox

" Automatically equalize split widths on window resize
autocmd VimResized * wincmd =

" Opens option and definition float windows
"set updatetime=250
"augroup DiagnosticFloat
"  autocmd!
"  autocmd CursorHold,CursorHoldI * call OpenDiagnosticFloat()
"augroup END
function! OpenDiagnosticFloat() abort
  lua vim.diagnostic.open_float(nil, {focus=false})
endfunction

" Custom keybinds and associated functions
""""""""""""""""""""""""""""""""""""""""""
" Sets space as leader and localmapleader
let mapleader = " " 
let localmapleader = " " 

" Sets <S-k> to "hover" 
nnoremap <silent> K :lua vim.lsp.buf.hover()<CR>

" Alias opening a file explorer within an existing buffer
" Replaced by nvim-tree
"nnoremap <leader>e :e .<CR>

" Use ctrl + v to create vertical window split
nnoremap <C-s> :vsplit<CR> 

" Use ctrl + l or h to move to adjacent windows
nnoremap <C-l> <C-w>l 
nnoremap <C-h> <C-w>h 

" Use j & k to navigate visual lines
nnoremap j gj
nnoremap k gk

" Jumps to a function def. by entering gd in normal mode
" Use <C-o> to get back to where the cursor began
nnoremap <silent> gd :lua vim.lsp.buf.definition()<CR>

" Telescope bindings
" NOTE: Live grep requires a Ripgrep install
nnoremap <leader>ff <cmd>Telescope find_files<CR>
nnoremap <leader>fg <cmd>Telescope live_grep<CR> 
nnoremap <leader>fb <cmd>Telescope buffers<CR>
nnoremap <leader>fh <cmd>Telescope help_tags<CR>

" Remaps the escape key to double leader 
inoremap <C-e> <Esc>

" Toggles file explorer
nnoremap <leader>e <cmd>:NvimTreeToggle<CR>

" Lua block configures nvim-cmp, lspconfig, nvim-tree, and gitsigns plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
lua << EOF

  -- Setup for nvim-tree
  -- Disables netrw (the default file explorer)
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  
  -- optionally enable 24-bit colour
  --vim.opt.termguicolors = true

  local function my_on_attach(bufnr)
    local api = require "nvim-tree.api"

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, 
        buffer = bufnr, 
        noremap = true, 
        silent = true, 
        nowait = true }
    end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- custom mappings
    vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent, opts('Up'))
    vim.keymap.set('n', '?',     api.tree.toggle_help,           opts('Help'))
  end

  -- pass to setup along with your other options
  require("nvim-tree").setup {
    ---
    on_attach = my_on_attach,
    ---
  }


  -- Setup nvim-cmp
  local cmp = require'cmp'
  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
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
      { name = 'vsnip' }, 
    }, {
      { name = 'buffer' },
    })
  })
  -- Set configuration for specific filetype
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' }, 
      -- You can specify the `git` source if [you installed it](https://github.com/petertriho/cmp-git)
    }, {
      { name = 'buffer' },
    })
  })
  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore)
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })
  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore)
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  -- LSP configuration
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  require('lspconfig')['rust_analyzer'].setup {
    capabilities = capabilities,
    hoverAction = {
      maxLines = 30,
      MaxColumns = 50,
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
    signcolumn = false,  -- Toggle with `:Gitsigns toggle_signs`
    numhl      = true, -- Toggle with `:Gitsigns toggle_numhl`
    linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff  = true, -- Toggle with `:Gitsigns toggle_word_diff`
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
    }
  }

  -- Telescope configuration allows all file searches
  require('telescope').setup {
  defaults = {
    find_command = { 'rg', '--no-ignore', '--hidden', '--files' },
  }
}
EOF
