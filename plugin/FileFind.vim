let g:file_find_plugin_dir = expand("<sfile>:p:h:h")

augroup file_find_keys
    au!
    au FileType file_search call File_find_key_mappings()
augroup END
function! File_find_key_mappings()
    nnoremap <buffer> <leader><CR> :call FileFindOverwrite()<CR>
    inoremap <buffer> <CR> <ESC>j:call FileFindOpenNewTab()<CR>
    nnoremap <buffer> <CR> :call FileFindOpenNewTab()<CR>
    nnoremap <buffer> T :call FileFindOpenInNewTab()<CR>
    augroup file_find_on_change
        au!
        au TextChangedI <buffer> call FileFind()
    augroup END
endfunction
function! OpenFileFindSearch()
    10new
    set buftype=nofile
    set filetype=file_search
    file FileFind
    startinsert
endfunction
function! FileFind()
    let a:cursor_pos = getpos(".")
    let $INPUT=getline(1)
    :2
    silent normal! 9999dd
    exec "silent 1read !" . g:file_find_plugin_dir . "/git_find_file " . $INPUT
    syntax clear
    let i = 0
    let words = split($INPUT)
    let colors = ["red", "27", "green", "gray"]
    while i < len(words)
        execute "syn match Match" . i . " \"" . words[i] . "\\V\\c\""
        execute "hi Match" . i . " ctermfg=" . colors[i%len(colors)]
        let i += 1
    endwhile
    normal! gg
    call cursor(a:cursor_pos[1], a:cursor_pos[2])
endfunction
function! FileFindOpenNewTab()
    if line(".")==1
        call FileFind()
    else
        let $INPUT=getline(".")
        :q
        exec "tab drop " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
    endif
endfunction
function! FileFindOpenInNewTab()
    if line(".")!=1
        let $INPUT=getline(".")
        tabnew $INPUT
        exec "tabnew " . substitute(system("git rev-parse --show-toplevel"), "\n "", "") . "/" . $INPUT
        tabprevious
    endif
endfunction
function! FileFindOverwrite()
    if line(".")!=1
        let $INPUT=getline(".")
        :q
        exec ":e " . substitute(system("git rev-parse --show-toplevel"), "\n "", "") . "/" . $INPUT
    endif
endfunction
