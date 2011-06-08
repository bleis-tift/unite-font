let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'font',
      \ 'hooks': {},
      \ 'action_table': {'*': {}},
      \ }

function! s:quote(str)
    return "'" . a:str . "'"
endfunction

function! s:unite_source.hooks.on_init(args, context)
    let s:beforefont = s:quote(&guifont)
endfunction

function! s:unite_source.hooks.on_close(args, context)
    if s:beforefont == s:quote(&guifont)
        return
    endif
    execute s:guifont(s:beforefont)
endfunction

let s:unite_source.action_table['*'].preview = {
      \ 'description': 'preview this font',
      \ 'is_quit': 0,
      \ }

function! s:unite_source.action_table['*'].preview.func(candidate)
    execute a:candidate.action__command
endfunction

function! s:guifont(x)
    return "let &guifont = " . a:x
endfunction

function! s:unite_source.gather_candidates(args, context)
  if has('gui_macvim')
    let list = split(glob('/Library/Fonts/*'), "\n")
    let list = extend(list, split(glob('/System/Library/Fonts/*'), "\n"))
    let list = extend(list, split(glob('~/Library/Fonts/*'), "\n"))
    call map(list, "fnamemodify(v:val, ':t:r')")
  elseif has('win32') && executable('fontinfo')
    let cmd = exists('g:use_unite_font_filter_win32') ? 'fontinfo ' . g:use_unite_font_filter_win32 : 'fontinfo'
    let list = split(iconv(system(cmd), 'utf-8', &encoding), "\n")
  elseif executable('fc-list')
    " 'fc-list' for win32 is included 'gtk win32 runtime'.
    " see: http://www.gtk.org/download-windows.html
    let list = split(iconv(system('fc-list :spacing=mono'), 'utf-8', &encoding), "\n")
    if v:lang =~ '^\(ja\|ko\|zh\)' 
      let list += split(iconv(system('fc-list :spacing=90'), 'utf-8', &encoding), "\n")
    endif
    call map(list, "substitute(v:val, '[:,].*', '', '')")
  else
    echoerr 'Your environment does not support the current version of unite-font.'
    finish
  endif

  return map(list, '{
        \ "word": v:val,
        \ "source": "font",
        \ "kind": "command",
        \ "action__command": s:guifont(string(v:val)),
        \ }')
endfunction

function! unite#sources#font#define()
  return has('gui_running') ? s:unite_source : []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
