let s:file_find_plugin_dir = expand("<sfile>:p:h:h")

if v:version < 704
  echom "FileFind: Vim < 7.4 not supported"
endif

if !exists('g:file_find_tab_move')
  let g:file_find_tab_move = 0
endif

let g:file_find_tab_fcn = "new"
if has("gui")
  let g:file_find_tab_fcn = "drop"
endif

func! PreFileFind()
  let a:cursor_pos = getpos(".")
  normal ggjVG"_d
  return a:cursor_pos
endfunc

func! PostFileFind(cursor_pos)
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
endfunc

if v:version >= 800
  func! FileFindJobMessageHandler(channel, msg)
    if exists("b:fileFindJob")
      let b:fileFindResults = b:fileFindResults + [a:msg]
    endif
  endfunc

  func! FileFindJobFinishedHandler(channel)
    if exists("b:fileFindJob")
      unlet b:fileFindJob
      if len(b:fileFindResults) > 0
        let a:cursor_pos = PreFileFind()
        1pu=b:fileFindResults
        call PostFileFind(a:cursor_pos)
        if exists("b:fileFindOnFinishFunction")
          let $INPUT=getline(2)
          exec "call " . b:fileFindOnFinishFunction . "($INPUT)"
        endif
      endif
    endif
  endfunc

  func! FileFindStartJob(input)
    if exists("b:fileFindJob")
      let b:fileFindResults = []
      let channel = job_getchannel(b:fileFindJob)
      call ch_close(channel)
      call job_stop(b:fileFindJob, "kill")
    endif
    let b:fileFindResults = []
    let b:fileFindJob = job_start(["/bin/bash", "-c", (s:file_find_plugin_dir . "/git_find_file " . a:input . " | head -n 200")], {"out_cb": "FileFindJobMessageHandler", "close_cb": "FileFindJobFinishedHandler"})
  endfunc
end

augroup file_find_keys
  au!
  au FileType file_search call File_find_key_mappings()
augroup END
function! File_find_key_mappings()
  inoremap <buffer> <C-\> <ESC>:call FileFindOverwrite()<CR>
  nnoremap <buffer> <C-\> :call FileFindOverwrite()<CR>
  inoremap <buffer> <CR> <ESC>:call FileFindOpenNewTab()<CR>
  nnoremap <buffer> <CR> :call FileFindOpenNewTab()<CR>
  inoremap <buffer> <C-v> <ESC>:call FileFindOpenInSplit()<CR>
  nnoremap <buffer> <C-v> :call FileFindOpenInSplit()<CR>
  inoremap <buffer> <C-a> <ESC>:q<CR>
  nnoremap <buffer> <C-a> :q<CR>
  augroup file_find_on_change
    au!
    au TextChangedI <buffer> call FileFindInputChanged()
    "au TextChanged <buffer> call FileFindInputChanged()
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
  normal! gg
  call cursor(a:cursor_pos[1], a:cursor_pos[2])
  if v:version >= 800
    call FileFindStartJob($INPUT)
  else
    let a:cursor_pos = PreFileFind()
    exec "silent 1read !" . s:file_find_plugin_dir . "/git_find_file " . $INPUT . " | head -n 200
    call PostFileFind(a:cursor_pos)
  endif
endfunction
func! FileFindOpenTabForInput(input)
  if a:input == ""
    return
  endif
  :q
  if g:file_find_tab_move
    tabmove
  endif
  exec "tab ". g:file_find_tab_fcn . " " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . a:input
  if g:file_find_tab_move
    tabmove
  endif
endfunc
function! FileFindOpenNewTab()
  if line(".")==1
    if line('$') > 1
      let $INPUT=getline(2)
      if $INPUT==""
        let $INPUT=getline(1)
      endif
    else
      let $INPUT=getline(1)
      if $INPUT==""
        let $INPUT=g:file_find_last_command
        call append(0, $INPUT)
        normal! gg
        call FileFind()
        return
      endif
    endif
  else
    let $INPUT=getline(".")
  endif
  if exists("b:fileFindJob")
    let b:fileFindOnFinishFunction = 'FileFindOpenTabForInput'
  else
    call FileFindOpenTabForInput($INPUT)
  endif
endfunction
function! FileFindOpenInSplitForInput(input)
  :q
  set splitright
  exec "vsp " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . a:input
endfunction
function! FileFindOpenInSplit()
  if line(".")==1
    let $INPUT=getline(2)
  else
    let $INPUT=getline(".")
  endif
  if exists("b:fileFindJob")
    let b:fileFindOnFinishFunction = 'FileFindOpenInSplitForInput'
  else
    call FileFindOpenInSplitForInput($INPUT)
  endif
endfunction
function! FileFindOverwriteForInput(input)
  :q
  exec ":e " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
endfunction
function! FileFindOverwrite()
  if line(".")==1
    let $INPUT=getline(2)
  else
    let $INPUT=getline(".")
  endif
  if exists("b:fileFindJob")
    let b:fileFindOnFinishFunction = 'FileFindOverwriteForInput'
  else
    call FileFindOverwriteForInput($INPUT)
  endif
endfunction
