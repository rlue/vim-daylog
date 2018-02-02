scriptencoding utf-8

" Initialization ---------------------------------------------------------------
function! s:daylog_home()
  if exists('g:daylog_home')
    return g:daylog_home
  elseif &l:filetype ==? 'daylog'
    return expand('%p:%h')
  else
    return getcwd()
  endif
endfunction

" TODO: Add more complete support for strftime formats
function! s:tstamp_regex()
  return substitute(
        \   substitute(s:tstamp_format, '%R', '\\d\\d:\\d\\d', ''),
        \   '\ze[[\]]', '\\', 'g')
endfunction

function! s:entries_per_hour()
  if !exists('g:daylog_entries_per_hour')
    return 4
  elseif (60 % g:daylog_entries_per_hour) == 0 && g:daylog_entries_per_hour <= 60
    return g:daylog_entries_per_hour
  else
    echoerr 'g:daylog_entries_per_hour must be a factor of 60' | finish
  endif
endfunction

let s:tstamp_format = exists('g:tstamp_format') ? g:tstamp_format : '[%R]'
let s:tstamp_regex = s:tstamp_regex()
let s:tstring_regex = '\d\d:\d\d'

let s:minutes_per_interval = 60 / s:entries_per_hour()
let s:seconds_per_interval = 60 * s:minutes_per_interval

let s:backfill_text = exists('g:daylog_backfill_text') ? g:daylog_backfill_text : '↓↓↓'

" Main Logic -------------------------------------------------------------------
function! daylog#enter_log()
  if s:verify_filename()
    call cursor('$', 1)

    let l:this_entry = s:start_of_interval()

    if getline('.') =~# s:tstamp_regex
      let l:last_entry = s:entry_time()
      call s:backfill_entries(l:this_entry, l:last_entry)
    endif

    if !exists('l:last_entry') || l:this_entry != l:last_entry
      call s:add_entry(l:this_entry)
    endif

    execute 's/' . s:tstamp_regex . '\zs\s*$/ /e'
    startinsert!
  else
    return
  endif
endfunction

" Helper Methods ---------------------------------------------------------------
function! s:verify_filename()
  if expand('%:t:r') =~# strftime('%F') | return 1 | endif
  execute 'edit ' . simplify(s:daylog_home() . '/' . strftime('%F') . '.daylog')
  call daylog#enter_log()
endfunction

" Accepts a time string of format %H:%M (optional, defaults to now);
" returns the UNIX time for the start of the containing interval.
function! s:start_of_interval(...)
  let l:base_time = a:0 ? s:parse_time(a:1) : (localtime() / 60) * 60

  let l:minutes_into_hour = eval(strftime('%M', l:base_time))
  let l:minutes_into_interval = l:minutes_into_hour % s:minutes_per_interval

  return l:base_time - (l:minutes_into_interval * 60)
endfunction

" Reads time from current line's tstamp;
" returns the corresponding UNIX time.
function! s:entry_time()
  if getline('.') !~# s:tstamp_regex
    echoerr 'Cursor is not on a log entry' | finish
  endif
  let l:tstring = matchstr(getline('.'), s:tstring_regex)
  return s:parse_time(l:tstring)
endfunction

" Adds an entry for the given time (defaults to start of current interval).
" NOTE: Does not force time to interval boundary
"       (in case that computation is redundant)
function! s:add_entry(...)
  let l:entry_time = a:0 ? a:1 : s:start_of_interval()
  if line('$') == 1 && getline(1) =~# '^$'
    call setline(1, s:tstamp(l:entry_time))
  else
    call append('.', s:tstamp(l:entry_time))
    call cursor(line('.') + 1, 1)
    if a:0 > 1 && strlen(a:2) > 0
      execute 'substitute/$/ ' . a:2
    endif
  endif
endfunction

" Accepts two arguments (both optional, for avoiding redundant computation):
"   1. start of current interval.
"   2. time of last completed entry, and
" Adds blank entry for each intervening interval.
function! s:backfill_entries(...)
  let l:current_entry = a:0 ? a:1 : s:start_of_interval()
  let l:first_missing_entry = (a:0 > 1 ? a:2 : s:entry_time()) + s:seconds_per_interval

  while ((l:current_entry - l:first_missing_entry) / s:seconds_per_interval) > 0
    call s:add_entry(l:first_missing_entry, s:backfill_text)
    let l:first_missing_entry += s:seconds_per_interval
  endwhile
endfunction

function! s:tstamp(...)
  let l:time = a:0 ? a:1 : localtime()
  return strftime(s:tstamp_format, l:time)
endfunction

" TODO: Support customized timestamps
" Accepts a time string of the format HH:MM;
" returns the corresponding UNIX time (seconds since epoch)
function! s:parse_time(target_time)
  if a:target_time !~# '^' . s:tstring_regex . '$'
    echoerr a:target_time . ' is not a valid time (HH:MM)' | finish
  endif

  let l:now = (localtime() / 60) * 60
  let l:target_hour = eval(matchstr(a:target_time, '^\d\d\ze:\d\d$'))
  let l:target_minute = eval(matchstr(a:target_time, '^\d\d:\zs\d\d$'))

  if l:target_hour > 23 || l:target_minute > 59
    echoerr a:target_time . ' is not a valid time (HH:MM)' | finish
  endif

  let l:target_minutes_today = l:target_hour * 60 + l:target_minute
  let l:current_minutes_today = strftime('%H', l:now) * 60 + strftime('%M', l:now)
  let l:minutes_since_target = l:current_minutes_today - l:target_minutes_today

  return l:now - (l:minutes_since_target * 60)
endfunction
