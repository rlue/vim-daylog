vim-daylog
==========

Where did the day go? Find out with Daylog.

Daylog helps me keep a record of how I spent my (work)day. I use it in
conjunction with [timer](https://github.com/rlue/timer) to jot down quick
notes of what I did (and what I want to start next) every 15 minutes.

Installation
------------

There are lots of vim plugin managers out there. I like [vim-plug](https://github.com/junegunn/vim-plug).

Usage
-----

Call `daylog#enter_log()` to create a new daylog file named after the current
date (or open it, if it already exists). You may wish to set a mapping in your
`.vimrc` to make this easier (I use `<Leader>ed` for **e**dit **d**aylog):

```viml
nnoremap <Leader>ed :call daylog#enter_log()<CR>
```

When editing a `.daylog` file, use `<Enter>` in Normal mode to add a new entry
to the end of the file. New entries are timestamped with the preceding
15-minute interval of the current hour (_e.g.,_ a new entry created between
13:15–13:29 would have a timestamp of “[13:15]”).

If more than one interval has elapsed since your last entry, missing entries
leading up to the new one will be filled in automatically. If the current
interval has not yet elapsed, the new entry will be appended to the last one,
rather than added on a new line.

When finished, hit `<Enter>` again to save and exit Insert mode.

Configuration
-------------

To customize the behavior of Daylog, modify the lines below and add them to
your `.vimrc`:

```viml
" Specify where daylogs are stored (by default, Daylog will create new files
" in the same directory as the current buffer).
let g:daylog_home = $HOME . '/Documents/Notes/Daylogs'

" Specify how often to create a new entry.
" (Use `3` for 20 minutes or `2` for 30; must be a factor of 60).
let g:daylog_entries_per_hour = 4

" Specify filler text for backfilled entries
let g:daylog_backfill_text = '↓↓↓'
```

License
-------

The MIT License (MIT)

Copyright © 2017 Ryan Lue
