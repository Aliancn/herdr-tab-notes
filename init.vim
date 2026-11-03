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
set scrolloff=3
set mouse=a
set termguicolors

" Match Herdr's light theme by default. Override with NOTES_BACKGROUND and
" NOTES_COLORSCHEME in config.env.
if exists('$TABNOTES_BACKGROUND') && ($TABNOTES_BACKGROUND ==# 'light' || $TABNOTES_BACKGROUND ==# 'dark')
  execute 'set background=' . $TABNOTES_BACKGROUND
else
  set background=light
endif
if exists('$TABNOTES_COLORSCHEME') && !empty($TABNOTES_COLORSCHEME)
  execute 'colorscheme ' . $TABNOTES_COLORSCHEME
else
  colorscheme default
endif

autocmd BufRead,BufNewFile *.md setlocal filetype=markdown conceallevel=0

" The markdown ftplugin sets its own buffer-local 4-space tabs after startup;
" put the note buffer back to 2 spaces.
autocmd FileType markdown setlocal tabstop=2 shiftwidth=2 expandtab

" Optional spell checking (NOTES_SPELL=1 in config.env).
if exists('$TABNOTES_SPELL') && $TABNOTES_SPELL ==# '1'
  set spell spelllang=en_us
endif

" Save on every change and when the pane loses focus; nothing is ever lost.
autocmd TextChanged,TextChangedI,InsertLeave,FocusLost * silent! update

" The pane is narrow and lines wrap, so move by screen line, not by file line.
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk
nnoremap <Down> gj
nnoremap <Up> gk
vnoremap <Down> gj
vnoremap <Up> gk
inoremap <Down> <C-o>gj
inoremap <Up> <C-o>gk
nnoremap 0 g0
nnoremap $ g$

" Open markdown notes at the end. Keep this scoped to *.md so :help and :e of
" other files keep their normal cursor position.
autocmd BufReadPost *.md silent! normal! G

" Every yank also goes to the system clipboard. The text is sent through the
" terminal (OSC 52) and Herdr forwards it to the machine you sit at, so a yank on
" a saved SSH machine reaches the local clipboard too. Deletes stay in Neovim's
" registers, and p pastes from those registers as usual.
lua << EOF
local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
if ok then
  local copy = osc52.copy('+')
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      local ev = vim.v.event
      if ev.operator ~= 'y' then return end
      local lines = vim.deepcopy(ev.regcontents)
      if ev.regtype == 'V' then table.insert(lines, '') end  -- linewise: end with a newline
      copy(lines)
    end,
  })
end
EOF

" q, Ctrl+S and Ctrl+C are intentionally left at Neovim defaults:
" - close the pane with the Herdr toggle (prefix+f) or :q
" - every change is already saved by the autocmd above
" - y/yy/visual y still copy through OSC 52
" Ctrl+X stays remapped to the Markdown checkbox toggle below.

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
