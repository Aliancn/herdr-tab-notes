" Use your normal Neovim config for tabnotes, with only the tabnotes behavior
" layered on top. pane.sh loads this with:
"   nvim -c "source <plugin>/init-user.vim" <note>
" The note file is already loaded when this runs, so apply the buffer-local
" settings and the jump-to-end here; init.vim's autocmds cover later reloads.
let g:tabnotes_user_config = 1
execute 'source ' . fnameescape(expand('<sfile>:p:h') . '/init.vim')

if &filetype ==# 'markdown' || expand('%:e') ==# 'md'
  setlocal wrap linebreak breakindent
  setlocal tabstop=2 shiftwidth=2 expandtab conceallevel=0
  silent! normal! G
endif
