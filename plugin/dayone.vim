" dayone.vim
" Author:  Kazuhiro Homma <kazu.homma@gmail.com>
" Version:  0.0.1
" See doc/dayone.txt for instructions and usage.

" Code {{{1
" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set

if (exists("g:loaded_dayone") && g:loaded_dayone) || &cp
  finish
endif
let g:loaded_dayone = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists('g:dayone_path')
  let g:dayone_path = $HOME . "/Dropbox/アプリ/Day One/Journal.dayone/entries"
endif

command! -nargs=0 DayOneList :call dayone#list()
command! -nargs=? DayOneGrep :call dayone#grep(<q-args>)
command! -nargs=? DayOneNew :call dayone#new(<q-args>)

let &cpo = s:cpo_save

" vim:set ft=vim ts=2 sw=2 sts=2:
