" Author: Vincent (wahrwolf [at] wolfpit.net)
" Description: languagetool for markdown files
"
call ale#Set('languagetool_executable', 'languagetool')
call ale#Set('languagetool_options', '--autoDetect')

function! ale#handlers#languagetool#GetExecutable(buffer) abort
    return ale#Var(a:buffer, 'languagetool_executable')
endfunction

function! ale#handlers#languagetool#GetCommand(buffer) abort
    let l:executable = ale#handlers#languagetool#GetExecutable(a:buffer)
    let l:options = ale#Var(a:buffer, 'languagetool_options')

    return ale#Escape(l:executable)
    \ . (empty(l:options) ? '' : ' ' . l:options) . ' %s'
endfunction

function! ale#handlers#languagetool#HandleOutput(buffer, lines) abort
    let l:lines = type(a:lines) is v:t_list ? a:lines : [a:lines]
    let l:i = 0
    let l:j = 0
    let l:output = []
    while l:i < len(l:lines)
        let l:message = ""
        let l:suggestion = ""

        let l:head_pattern = '^\v.+.\) Line (\d+), column (\d+), Rule ID. (.+) premium:.*$'
        let l:head_match = matchlist(l:lines[l:i], l:head_pattern)
        if !empty(l:head_match)
            let l:lnum = str2nr(l:head_match[1])
            let l:col = str2nr(l:head_match[2])
            let l:code = l:head_match[3]
            let l:i+=1
            let l:message_pattern = '^\vMessage. (.+)$'
            let l:message_match = matchlist(l:lines[l:i], l:message_pattern)
            if !empty(l:message_match)
                let l:message = l:message_match[0]
                let l:i+=1
            endif
            let l:suggestion_pattern = '^\vSuggestion. (.+)$'
            let l:suggestion_match = matchlist(l:lines[l:i], l:suggestion_pattern)
            if !empty(l:suggestion_match)
                let l:suggestion = l:suggestion_match[0]
                let l:i+=1
            endif
            let l:i+=1
            let l:markers_pattern = '^\v *(\^+) *$'
            let l:markers_match = matchlist(l:lines[l:i], l:markers_pattern)
            let l:end_col = str2nr(l:col + len(l:markers_match[1]))
            let l:text = l:message . " " . l:suggestion
            let l:item = { 'lnum': l:lnum, 'col': l:col, 'end_col': l:end_col, 'type': 'W', 'code': l:code, 'text': l:text }
            call add(l:output, l:item)
            let l:j+=1
        endif
        let l:i+=1
    endwhile
    return l:output
endfunction

" Define the languagetool linter for a given filetype.
" TODO:
" - Add language detection settings based on user env (for mothertongue)
" - Add fixer
" - Add config options for rules
function! ale#handlers#languagetool#DefineLinter(filetype) abort
    call ale#linter#Define(a:filetype, {
    \   'name': 'languagetool',
    \   'executable': function('ale#handlers#languagetool#GetExecutable'),
    \   'command': function('ale#handlers#languagetool#GetCommand'),
    \   'output_stream': 'stdout',
    \   'callback': 'ale#handlers#languagetool#HandleOutput',
    \   'lint_file': 1,
    \})
endfunction
