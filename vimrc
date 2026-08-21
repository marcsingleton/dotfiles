syntax on
set number
set ruler
set autoindent
set ts=4 sts=0 sw=4 expandtab
set bg=dark " Fixes colorizing in tmux windows

function! FormatBuffer(cmd, line1, line2)
  let l:view = winsaveview()
  let l:input = join(getline(a:line1, a:line2), "\n")
  let l:output = system(a:cmd, l:input)
  if v:shell_error
    echohl ErrorMsg
    for l:line in split(l:output, "\n")
      echom l:line
    endfor
    echohl None
  else
    let l:lines = split(l:output, "\n")
    call append(a:line2, l:lines)
    silent execute a:line1 . ',' . a:line2 . 'd _'
  endif
  call winrestview(l:view)
endfunction

function PyFormatBuffer(line1, line2)
  let l:cmd = 'ruff format -'
  call FormatBuffer(l:cmd, a:line1, a:line2)
endfunction

function! ShFormatBuffer(line1, line2)
  if expand('%') != ''
    let l:cmd = 'shfmt --filename ' . expand('%')
  else
    let l:cmd = 'shfmt'
  endif

  call FormatBuffer(l:cmd, a:line1, a:line2)
endfunction

command! -nargs=1 -range=% Format call FormatBuffer(<q-args>, <line1>, <line2>)
command! -range=% PyFormat call PyFormatBuffer(<line1>, <line2>)
command! -range=% ShFormat call ShFormatBuffer(<line1>, <line2>)
