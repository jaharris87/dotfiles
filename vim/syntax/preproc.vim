" Vim syntax extension file
" Language:	C preprocessor syntax on top of c, cpp, ...
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" Copyright: (C) 2010-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" REVISION	DATE		REMARKS
"   1.00.004	17-Nov-2016	Prepare for publishing.
"	003	10-Feb-2011	BUG: No comment highlighting of #if 0 block.
"				Fixed by syncing with syntax/c.vim from 2009 Nov
"				17.
"				FIX: Syncing also found double "end=" in
"				preprocPreCondit.
"	002	25-Mar-2010	Added highlighting preprocessor comments.
"	001	24-Mar-2010	file creation

if exists('b:current_syntax') && b:current_syntax =~# 'preproc'
    finish
endif

function! s:AlreadyHasCComments()
    let l:commentGroup = 'cComment'

    " Quickly check with hlexists() whether the "cComment" syntax group exists
    " globally.
    if hlexists(l:commentGroup)
	" Existence of the syntax group is necessary, but not yet sufficient,
	" since this query is global, and the group could have been loaded by
	" another buffer. To check whether this file's syntax includes the
	" syntax group, we need to check the output of :syntax, as
	" :syntax list {group-name} also shows non-active groups.
	redir => l:syntaxGroupsOutput
	silent! syn list
	redir END

	let l:syntaxGroups = split(l:syntaxGroupsOutput, "\n")
	let l:commentGroups = filter(l:syntaxGroups, "v:val =~# '^\\V" . escape(l:commentGroup, '\') . "'")
	if ! empty(l:commentGroups)
	    " The syntax group is used in the current filetype.
"****D echomsg '**** C/C++ style comments already defined'
	    return 1
	endif
    endif

    return 0
endfunction

syn region	preprocIncluded	display start=+"+ skip=+\\\\\|\\"+ end=+"+ contained
syn match	preprocIncluded	display "<[^>]*>" contained
syn match	preprocInclude	display "^\s*\%(%:\|#\)\s*include\>\s*["<]" contains=preprocIncluded
syn cluster	preprocPreProcGroup	contains=preprocIncluded,preprocInclude,preprocDefine

" Use matchgroup here to have the preprocessor directive always highlighted as
" such, regardless of any native matching after that.
syn region	preprocDefine		matchgroup=preprocDefine start="^\s*\%(%:\|#\)\s*\(define\|undef\)\>" skip="\\$" end="$" keepend contains=ALLBUT,@preprocPreProcGroup,@Spell
syn region	preprocPreProc		matchgroup=preprocPreProc start="^\s*\%(%:\|#\)\s*\(pragma\>\|line\>\|warning\>\|warn\>\|error\>\)" skip="\\$" end="$" keepend contains=ALLBUT,@preprocPreProcGroup,@Spell

syn region	preprocPreCondit	start="^\s*\(%:\|#\)\s*\(if\|ifdef\|ifndef\|elif\)\>" skip="\\$" end="$" keepend contains=preprocCommentError
syn match	preprocPreCondit	display "^\s*\(%:\|#\)\s*\(else\|endif\)\>"

if ! exists('preproc_no_comments') && ! s:AlreadyHasCComments()
    syn region	preprocCommentL	start="//" skip="\\$" end="$" keepend contains=@preprocCommentGroup,@Spell
    if exists('preproc_no_comment_fold')
	syn region	preprocComment	matchgroup=preprocCommentStart start="/\*" end="\*/" contains=@preprocCommentGroup,preprocCommentStartError,@Spell extend
    else
	syn region	preprocComment	matchgroup=preprocCommentStart start="/\*" end="\*/" contains=@preprocCommentGroup,preprocCommentStartError,@Spell fold extend
    endif
    " keep a // comment separately, it terminates a preproc. conditional
    syn match	preprocCommentError	display "\*/"
    syn match	preprocCommentStartError display "/\*"me=e-1 contained
endif

if ! exists('preproc_no_if0')
    if ! exists('preproc_no_if0_fold') && exists('preproc_no_fold_conditions')
	syn region	preprocCppOut		start="^\s*\(%:\|#\)\s*if\s\+0\+\>" end=".\@=\|$" contains=preprocCppOut2 fold
    else
	syn region	preprocCppOut		start="^\s*\(%:\|#\)\s*if\s\+0\+\>" end=".\@=\|$" contains=preprocCppOut2
    endif
    syn region	preprocCppOut2	contained start="0" end="^\s*\(%:\|#\)\s*\(endif\>\|else\>\|elif\>\)" contains=preprocCppSkip
    syn region	preprocCppSkip	contained start="^\s*\(%:\|#\)\s*\(if\>\|ifdef\>\|ifndef\>\)" skip="\\$" end="^\s*\(%:\|#\)\s*endif\>" contains=preprocCppSkip
endif

if ! exists('preproc_no_fold_conditions')
    " Source: http://groups.google.com/group/vim_use/browse_thread/thread/49ed223185b6cb07
    " fold #if...#else...#endif constructs
    syn region preprocIfFoldContainer
	\ start="^\s*\%(%:\|#\)\s*if\(n\?def\)\?\>"
	\ end="#\s*endif\>"
	\ skip=+"\%(\\"\|[^"]\)\{-}\\\@<!"\|'[^']\{-}'\|'\\''\|//.*+
	\ transparent
	\ keepend extend
	\ containedin=NONE
	\ contains=preprocSynFoldIf,preprocSynFoldElif,preprocSynFoldElse
    syn region preprocSynFoldIf
	\ start="^\s*\%(%:\|#\)\s*if\(n\?def\)\?\>"
	\ end="^\s*\%(%:\|#\)\s*el\(se\|if\)\>"ms=s-1,me=s-1
	\ skip=+"\%(\\"\|[^"]\)\{-}\\\@<!"\|'[^']\{-}'\|'\\''\|//.*+
	\ fold transparent
	\ keepend
	\ contained
	\ nextgroup=preprocSynFoldElif,preprocSynFoldElse
	\ contains=TOP
    syn region preprocSynFoldElif
	\ start="^\s*\%(%:\|#\)\s*elif\>"
	\ end="^\s*\%(%:\|#\)\s*el\(se\|if\)\>"ms=s-1,me=s-1
	\ skip=+"\%(\\"\|[^"]\)\{-}\\\@<!"\|'[^']\{-}'\|'\\''\|//.*+
	\ fold transparent
	\ keepend
	\ contained
	\ nextgroup=preprocSynFoldElse
	\ contains=TOP
    syn region preprocSynFoldElse
	\ start="^\s*\%(%:\|#\)\s*else\>"
	\ end="^\s*\%(%:\|#\)\s*endif\>"
	\ skip=+"\%(\\"\|[^"]\)\{-}\\\@<!"\|'[^']\{-}'\|'\\''\|//.*+
	\ fold transparent
	\ keepend
	\ contained
	\ contains=TOP
endif


hi def link preprocDefine	Macro
hi def link preprocInclude	Include
hi def link preprocIncluded	String
hi def link preprocPreProc	PreProc
hi def link preprocPreCondit	PreCondit

hi def link preprocCommentL	preprocComment
hi def link preprocCommentStart	preprocComment
hi def link preprocComment	Comment
hi def link preprocCommentError	preprocError
hi def link preprocError	Error

hi def link preprocCppSkip	preprocCppOut
hi def link preprocCppOut2	preprocCppOut
hi def link preprocCppOut	Comment


if ! exists('b:current_syntax')
    let b:current_syntax = 'preproc'
else
    let b:current_syntax .= '.preproc'
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
