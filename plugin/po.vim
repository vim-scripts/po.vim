" VIM filetype plugin
" Language:	PO-files (message catalogs for gettext)
" Maintainer:	Michael Piefel <piefel@informatik.hu-berlin.de>
" Last Change:	30 May 2001
" Licence:	Public Domain

" Do this for every buffer
nnoremap <buffer> <CR>     :call <SID>OpenFile()<CR>

if exists("g:did_po_ftplugin")
    finish
endif

" Don't load another plugin (this is global)
let g:did_po_ftplugin = 1

" This function removes the quotes in a translation entry.
" It also joins lines which are split because the PO file is supposed to only
" have a tw of 80 (Emacs?), but where the contents of the line is shorter than
" 80 characters.
function s:Unstringify()
    let l:reportsave=&report
    set report=65535
    if search('^msgstr ""$', "b") > 0
	let l:anfang = line(".")+1
	if search('^$') > 0
	    let l:ende = line(".")
	    execute l:ende . "," . l:ende . 's/^$/###---end of entry---###/'
	    execute l:anfang . "," . l:ende . 's/^"//'
	    execute l:anfang . "," . l:ende . 's/\\n"$//e'
	    execute l:anfang . "," . l:ende . 's/ "\n/ /e'
	endif
    endif
    let &report=l:reportsave
endfunction

" This adds quotes around an entry.
" It also adds the \n characters. It doesn't split lines which are too long,
" because there's really no need for that.
function s:Stringify()
    let l:reportsave=&report
    set report=65535
    if search('^msgstr ""$', "b") > 0
	let l:anfang = line(".")+1
	if search('^###---end of entry---###$') > 0
	    let l:ende = line(".")-1
	    execute (l:ende+1) . "," . (l:ende+1) . 's/###---end of entry---###//'
	    execute l:anfang . "," . l:ende . 's/^\(.*\)$/"\1\\n"/'
	endif
    endif
    let &report=l:reportsave
endfunction 

" This opens the file under the cursor
" In PO files, there are comments like src/hallo.c:45 to point to the spot the
" string is defined. This routine extracts the name and the line number,
" splits the window and positions the cursor.
function s:OpenFile()
    let l:currline=line(".")
    if search(" ", 'b') != l:currline
	return
    else
	let l:anfang=col(".")
    endif

    if search(":") != l:currline
	return
    else
	let l:mitte=col(".")
    endif

    if search(" ") != l:currline
	let l:ende=strlen(getline(l:currline))+1
    else
	let l:ende=col(".")
    end
    
    let l:datei=strpart(getline(l:currline), l:anfang, l:mitte-l:anfang-1)
    let l:line=strpart(getline(l:currline), l:mitte, l:ende-l:mitte-1)

    if matchend(getcwd(), '/po$') == strlen(getcwd())
	let l:dirpre="../"
    else
	let l:dirpre=""
    endif
    exec("silent sp +" . l:line . " " . l:dirpre . l:datei )
endfunction

function s:SendMail()
    write
    call system('mutt -a ' . bufname("%") .
	\ ' -s "TP-Robot ' . bufname("%") . '" translation@iro.umontreal.ca < /dev/null')
endfunction

" Adjust spelling to according to iX rules
" Many more corrections are possible, but are optional.
" Many are still needed, but are hard to do automatically.
function s:NewGerman()
    execute '%s/\([Gg]\)raphi\([^c]\)/\1rafi\2/ge'
	" Graphik -> Grafik
    execute '%s/\<\([mMnN]u\)ﬂ\>/\1ss/ge'
	" Muﬂ -> Muss, Nuﬂ -> Nuss 
    execute '%s/\([pPnNdD]a\)ﬂ/\1ss/ge'
	" Paﬂ -> Pass, Naﬂ -> Nass, daﬂ -> dass
    execute '%s/\([mM]\)iﬂ/\1iss/ge'
	" Miﬂ... -> Miss...
    execute "%s/giﬂ\\([t']?\\)/giss\\1/ge"
	" (ver)giﬂ[t'] -> giss[t']
    execute '%s/\([lLfFpP]\)\([‰a]\)ﬂt\\>/\1\2sst/ge' 
	" laﬂt -> lasst, 
	" l‰ﬂt -> l‰sst, 
	" faﬂt -> fasst,
    execute '%s/\([Pp]roze\)ﬂ/\1ss/ge'
	" Prozeﬂ -> Prozess...
    execute '%s/\\<\([aA]dre\)ﬂ/\1ss/ge'
	" Adreﬂ... -> Adress...
    execute '%s/\([mM]\)enue?\\>/\1en¸/ge'
	" Menu -> Men¸
    execute '%s/\([pP]\)otenti/\1otenzi/ge'
	" Potenti... -> Potenzi...
    execute '%s/\\<\([mM][u¸]\)ﬂ\([^e]\)/\1ss\2/ge'
	" "m¸ﬂte" aber nicht "Muﬂe"!
    execute '%s/\([sS]chlu\)ﬂ/\1ss/ge'
	" ...schluﬂ -> schluss
    execute '%s/\([sS]\)ogenannt\(.*\)\\>/\1o genannt\2/ge'
	" sogenannt -> so genannt
    execute '%s/\([aA]\)usser/\1ﬂer/ge'
	" ausser -> auﬂer
    execute '%s/\([hH]\)eiss/\1eiﬂ/ge'
	"  heiss  -> heiﬂ
    execute '%s/\([hH]\)ier zu Lande/\1ierzulande/ge'
	" hier zu Lande -> hierzulande

    " zur Zeit -> zurzeit fehlt, weil es weiterhin "zur Zeit Julius C‰sars" heiﬂt
endfunction

function s:MakeMenu()
    amenu &PO-Editing.&Remove\ quotes		:call <SID>Unstringify()<CR>
    amenu PO-Editing.&Add\ quotes		:call <SID>Stringify()<CR>
    amenu PO-Editing.Unfu&zzy			:?fuzzy? s/, fuzzy//<CR>
    amenu PO-Editing.Jump\ to\ File<TAB>Enter	:call <SID>OpenFile()<CR>
    amenu PO-Editing.-sep-			<nul>
    amenu PO-Editing.&Next\ entry		:call search('\(fuzzy\)\\|\(""\n\n\)')<CR>
    amenu PO-Editing.Next\ &fuzzy		:call search('fuzzy')<CR>
    amenu PO-Editing.Next\ &untranslated	:call search('""\n\n')<CR>
    amenu PO-Editing.-sep-			<nul>
    amenu PO-Editing.Send\ entry\ to\ Translation\ Project   :call <SID>SendMail()<CR>
    amenu PO-Editing.Convert\ old\ to\ new\ German\ spelling :call <SID>NewGerman()<CR>
endfunction

augroup poMenu
au BufEnter * if &filetype == "po" | call <SID>MakeMenu() | setlocal tw=79 | endif
au BufLeave * if &filetype == "po" | aunmenu PO-Editing | endif
augroup END

