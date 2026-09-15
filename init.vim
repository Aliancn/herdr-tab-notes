" Minimal Neovim config for the tab-notes pane (loaded with --clean).
set nocompatible
filetype plugin on
syntax on
set encoding=utf-8
set wrap linebreak breakindent
set nonumber norelativenumber
set noswapfile nobackup nowritebackup
set autoread
set laststatus=0 noshowmode showcmd
set shortmess+=I
set signcolumn=no
set tabstop=2 shiftwidth=2 expandtab
set scrolloff=3
set mouse=a
set spelllang=en_us
set termguicolors
colorscheme habamax
autocmd BufRead,BufNewFile *.md setlocal filetype=markdown conceallevel=0

" Save on every change and when the pane loses focus; nothing is ever lost.
autocmd TextChanged,TextChangedI,InsertLeave,FocusLost * silent! update

" Open at the end of the note.
autocmd BufReadPost * silent! normal! G

" q writes and closes the pane. Ctrl+S saves.
nnoremap <silent> q :update<CR>:qa<CR>
nnoremap <silent> <C-s> :update<CR>
inoremap <silent> <C-s> <Esc>:update<CR>a

" Toggle a Markdown checkbox on the current line with Ctrl+X.
function! s:ToggleBox()
  let l = getline('.')
  if l =~ '\[ \]'
    call setline('.', substitute(l, '\[ \]', '[x]', ''))
  elseif l =~ '\[x\]'
    call setline('.', substitute(l, '\[x\]', '[ ]', ''))
  else
    call setline('.', substitute(l, '^\(\s*\)\(- \)\?', '\1- [ ] ', ''))
  endif
endfunction
nnoremap <silent> <C-x> :call <SID>ToggleBox()<CR>
inoremap <silent> <C-x> <Esc>:call <SID>ToggleBox()<CR>a
