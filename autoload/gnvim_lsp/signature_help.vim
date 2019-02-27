

function! gnvim_lsp#signature_help#cursor_moved() abort
    call gnvim_lsp#signature_help#show()
endfunction

function! gnvim_lsp#signature_help#show() abort
    let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_hover_provider(v:val)')

    if len(l:servers) == 0
        return
    endif

    let l:pos = lsp#get_position()
    let l:screencol = screencol()
    let l:screenrow = screenrow()

    for l:server in l:servers
        call lsp#send_request(l:server, {
            \ 'method': 'textDocument/signatureHelp',
            \ 'params': {
            \   'textDocument': lsp#get_text_document_identifier(),
            \   'position': l:pos,
            \ },
            \ 'on_notification': function('s:handle', [l:server, l:pos, l:screencol, l:screenrow]),
            \ })
    endfor
endfunction

function! s:handle(server, pos, screencol, screenrow, data) abort

    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Failed to retrieve signature help information for ' . a:server)
        return
    endif

    if !has_key(a:data['response'], 'result')
        return
    endif

    let result = a:data['response']['result']

    let active_signature = get(result, 'activeSignature', 0)
    let active_param = get(result, 'activeParameter', 0)
    let signature = result['signatures'][active_signature]

    let content = signature['label'] . '<hr>'

    if has_key(signature, 'parameters')
        let param = signature['parameters'][active_param]

        let label = param['label']
        if type(label) == v:t_string
            let pos = matchstrpos(content, label)
            if pos[0] != ""
                let content = 
                            \ content[:pos[1] - 1]
                            \ . '<b><u>' . label . '</u></b>'
                            \ . content[pos[2]:]
            else
                echom 'Failed to get substring position for signature help label'
            endif
        else
            echom 'Label position not (yet) supported for signature help'
        endif

        let content .= "\n\n" . s:to_string(param['documentation'])
    endif
    
    if has_key(signature, 'documentation')
        let content .= "\n\n" . s:to_string(signature['documentation'])
    endif

    let col = screencol() - 1
    let row = screenrow() - 1
    call gnvim#cursor_tooltip#show(content, row, col)
endfunction

function! s:to_string(data) abort
    let l:content = ""

    if type(a:data) == type([])
        for l:entry in a:data
            let l:content .= s:to_string(entry)
        endfor
    elseif type(a:data) == type('')
        let l:content .= a:data . "\n"
    elseif type(a:data) == type({}) && has_key(a:data, 'language')
        let l:content .= "```".a:data.language . "\n"
        let l:content .= a:data.value
        let l:content .= "\n" . "```" . "\n"

    elseif type(a:data) == type({}) && has_key(a:data, 'kind')
        let l:content .= a:data.value . "\n"
    endif

    return l:content
endfunction
