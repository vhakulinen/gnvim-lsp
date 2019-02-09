if has("g:gnvim_lsp_loaded") || !exists("g:gnvim")
    finish
endif

let g:gnvim_lsp_loaded = 1

augroup GnvimHover
    autocmd!
    autocmd CursorMoved,CursorMovedI * call gnvim_lsp#hover#cursor_moved()
    autocmd User GnvimScroll call gnvim_lsp#hover#abort()
    autocmd InsertEnter,CmdlineEnter * call gnvim_lsp#hover#abort()
augroup END
