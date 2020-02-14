" =============================================================================
" File: plugin/follow-path.vim
" Description: Select text, treat it as a system path and follow it.
" Author: Jakub Warumzer <github.com/JakubWarumzer>
" Comment: Primarily done to deal with ansible playbooks
" =============================================================================

" Credit: <stackoverflow.com/FocusedWolf>
function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function! s:follow_directory()
	" Getting selected text
	let b:selection = s:get_visual_selection()

	" Priorities:
	" 1. Ansible role path (sadly gotta check both .yml/.yaml)
	" 2. Absolute path
	let b:ansible_path_yml = "roles/" . s:get_visual_selection() . "/tasks/main.yml"
	let b:ansible_path_yaml = "roles/" . s:get_visual_selection() . "/tasks/main.yaml"
	let b:absolute_path = b:selection

	if filereadable(b:ansible_path_yml)
		let b:destination_path = b:ansible_path_yml
	elseif filereadable(b:ansible_path_yaml)
		let b:destination_path = b:ansible_path_yaml
	elseif filereadable(b:absolute_path)
		let b:destination_path = b:absolute_path
	else
		echomsg "Incorrect path!"
		return
	endif

	" ...and we're switching to the view!
	execute 'view' b:destination_path

	" Some remapping to make transition seamless.
	command -bang -buffer WBD write!|bdelete
	ca <buffer> q bd
	ca <buffer> wq WBD
endfunction

vnoremap <C-e> :call <SID>follow_directory()<CR>
