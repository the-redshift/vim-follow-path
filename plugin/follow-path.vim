" =============================================================================
" File: plugin/follow-path.vim
" Description: Select text, treat it as a system path and follow it.
" Author: Jakub Warumzer <github.com/the-redshift>
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
	" 1. Working directory path, looking for ansible role match
	" 2. Ansible galaxy role paths
	" 3. Absolute path

	let b:possible_paths = [
		\"roles/" . s:get_visual_selection(),
		\$HOME . "/.ansible/roles/" . s:get_visual_selection(),
		\"/usr/share/ansible/roles/" . s:get_visual_selection(),
		\"/etc/ansible/roles/" . s:get_visual_selection(),
		\s:get_visual_selection(),
	\]

	let b:possible_path_suffixes = [
		\"/tasks/main.yml",
		\"/tasks/main.yaml",
		\"",
	\]

	let b:final_path = ""
	for path in b:possible_paths
		for suffix in b:possible_path_suffixes
			let b:path = path . suffix
			if filereadable(b:path)
				let b:final_path = b:path
				break
			endif
		endfor

		if b:final_path != ""
			break
		endif
	endfor

	if b:final_path == ""
		echomsg "Incorrect path!"
		return
	endif

	" ...and we're switching to the view!
	execute 'view' b:final_path

	" Some remapping to make transition seamless.
	command! -bang -buffer WBD write!|bdelete
	ca <buffer> q bd
	ca <buffer> wq WBD
endfunction

vnoremap <C-e> :call <SID>follow_directory()<CR>
