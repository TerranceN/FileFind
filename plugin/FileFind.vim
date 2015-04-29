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
    inoremap <buffer> <C-v> <ESC>:call FileFindOpenInSplit()<CR>
    nnoremap <buffer> <C-v> :call FileFindOpenInSplit()<CR>
    inoremap <buffer> <C-a> <ESC>:q<CR>
    nnoremap <buffer> <C-a> :q<CR>
    augroup file_find_on_change
        au!
        au TextChangedI <buffer> call FileFindInputChanged()
    augroup END
endfunction
function! OpenFileFindSearch()
    silent! call FileFindBuffer()
    startinsert
endfunction
function! FileFindBuffer()
    10new
    set buftype=nofile
    set filetype=file_search
    file FileFind
endfunction
function! FileFindInputChanged()
    let g:file_find_last_command=getline(1)
    call FileFind()
endfunction
function! FileFind()
    let a:cursor_pos = getpos(".")
    let $INPUT=getline(1)
    if $INPUT==""
        let $INPUT=g:file_find_last_command
        call append(0, $INPUT)
    endif
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
        let $INPUT=getline(2)
        if $INPUT==""
            call FileFind()
            return
        endif
    else
        let $INPUT=getline(".")
    endif
    :q
    exec "tab new " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
endfunction
function! FileFindOpenInSplit()
    if line(".")==1
        let $INPUT=getline(2)
    else
        let $INPUT=getline(".")
    endif
    :q
    exec "vsp " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
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
