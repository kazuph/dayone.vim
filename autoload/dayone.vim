" autoload/dayone.vim
" Author:  Kazuhiro Homma <kazu.homma@gmail.com>
" Version: 0.0.1
" Install this file as autoload/dayone.vim.  This file is sourced manually by
" plugin/dayone.vim.  It is in autoload directory to allow for future usage of
" Vim 7's autoload feature.

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set

if &cp || exists("g:autoloaded_dayone")
  finish
endif
let g:autoloaded_dayone= '1'

let s:cpo_save = &cpo
set cpo&vim

" Utility Functions {{{1
function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction
" }}}1

"------------------------
" setting
"------------------------
if !exists('g:dayone_entry_suffix')
  let g:dayone_entry_suffix = "doentry"
endif

if !exists('g:dayone_entry_date')
  let g:dayone_entry_date = "%Y-%m-%dT%H:%M:%SZ"
endif

if !exists('g:dayone_title_pattern')
  let g:dayone_title_pattern = "[ /\\'\"]"
endif

if !exists('g:dayone_template_dir_path')
  let g:dayone_template_dir_path = ""
endif

function! s:esctitle(str)
  let str = a:str
  let str = tolower(str)
  let str = substitute(str, g:dayone_title_pattern, '-', 'g')
  let str = substitute(str, '\(--\)\+', '-', 'g')
  let str = substitute(str, '\(^-\|-$\)', '', 'g')
  return str
endfunction

function! s:escarg(s)
  return escape(a:s, ' ')
endfunction

let g:dayone_path = expand(g:dayone_path, ':p')
if !isdirectory(g:dayone_path)
  " call mkdir(g:dayone_path, 'p')
  echo 'Not exists directory.'
endif

let text = '@@@@@@@@@@@'
echo s:create_uuid()


"------------------------
" function
"------------------------
function! dayone#list()
  if get(g:, 'dayone_vimfiler', 0) != 0
    exe "VimFiler" s:escarg(g:dayone_path)
  else
    exe "e" s:escarg(g:dayone_path)
  endif
endfunction

function! dayone#grep(word)
  let word = a:word
  if word == ''
    let word = input("EntryGrep word: ")
  endif
  if word == ''
    return
  endif

  try
    if get(g:, 'dayone_qfixgrep', 0) != 0
      exe "Vimgrep -r" s:escarg(word) s:escarg(g:dayone_path . "/*")
    else
      exe "vimgrep" s:escarg(word) s:escarg(g:dayone_path . "/*")
    endif
  catch
    redraw | echohl ErrorMsg | echo v:exception | echohl None
  endtry
endfunction

function! dayone#_complete_ymdhms(...)
  return [strftime("%Y%m%d%H%M")]
endfunction

function! dayone#new(text)
  echo 'koko!'
  let items = {
  \ 'text': a:text,
  \ 'date': localtime(),
  \ 'uuid': s:create_uuid(),
  \ 'star': 'false',
  \}

  if g:dayone_entry_date != 'epoch'
    let items['date'] = strftime(g:dayone_entry_date)
  endif
  if items['text'] == ''
    let items['text']= input("Entry title: ", "", "customlist,dayone#_complete_ymdhms")
  endif
  if items['text'] == ''
    return
  endif

  if get(g:, 'dayone_prompt_tags', 0) != 0
    let items['tags'] = join(split(input("Entry tags: "), '\s'), ' ')
  endif

  if get(g:, 'dayone_prompt_categories', 0) != 0
    let items['categories'] = join(split(input("Entry categories: "), '\s'), ' ')
  endif

  " let file_name = strftime("%Y-%m-%d-") . s:create_uuid() . "." . g:dayone_entry_suffix
  let file_name = s:create_uuid() . "." . g:dayone_entry_suffix

  echo "Making that entry " . file_name
  exe (&l:modified ? "sp" : "e") s:escarg(g:dayone_path . "/" . file_name)

  " entry template
  let template = s:default_template
  if g:dayone_template_dir_path != ""
    let path = expand(g:dayone_template_dir_path, ":p")
    let path = path . "/" . g:dayone_entry_suffix . ".txt"
    if filereadable(path)
      let template = readfile(path)
    endif
  endif
  " apply template
  let old_undolevels = &undolevels
  set undolevels=-1
  call append(0, s:apply_template(template, items))
  let &undolevels = old_undolevels
  set nomodified

  return 'END!!!'

endfunction

let s:default_template = [
\ '<?xml version="1.0" encoding="UTF-8"?>',
\ '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
\ '<plist version="1.0">',
\ '<dict>',
\ '    <key>Creation Date</key>',
\ '    <date>{{_$date_}}</date>',
\ '    <key>Entry Text</key>',
\ '    <string>{{_$text_}}</string>',
\ '    <key>Starred</key>',
\ '    <{{_$star_}}/>',
\ '    <key>UUID</key>',
\ '    <string>{{_$uuid_}}</string>',
\ '</dict>',
\ '</plist>',
\]

function! s:apply_template(template, items)
  let mx = '{{_\(\w\+\)_}}'
  return map(copy(a:template), "
  \  substitute(v:val, mx,
  \   '\\=has_key(a:items, submatch(1)) ? a:items[submatch(1)] : submatch(0)', 'g')
  \")
endfunction

function! s:create_uuid()
  let uuid = toupper(substitute(matchstr(system("uuidgen"),
        \ "[^\n\r]*"), "-", "", "g"))
  return uuid
endfunction

let &cpo = s:cpo_save

" vim:set ft=vim ts=2 sw=2 sts=2:
