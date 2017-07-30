
local _M = {
    _cls_ = '',
    _ext_ = {path = 'lxlib.view.engine.base.config'}
}

local mt = { __index = _M }

local lx = require('lxlib')
local app, lf, tb, Str = lx.kit()

function _M:append()
    
    self:appendCmds()
    self:appendPats()

end

function _M:appendCmds()

    local cmdList = 'section,endsection,yield,parent'
    cmdList = tb.flip(cmdList, true)

    self.cmds = tb.merge(self.cmds, cmdList)

end

function _M:appendPats()

    local pats = self.pats
    local tags = self.tags

    tags.tag_stmt_begin = '@'
    tags.tag_stmt_end = ''
    tags.stmt_begin = '@'
    tags.stmt_end = ''
    tags.q_stmt_begin = '@'
    tags.q_stmt_end = ''

    tags.tag_comment_begin, tags.tag_comment_end = '{--', '--}'
    tags.q_tag_comment_begin, tags.q_tag_comment_end = '{%-%-', '%-%-}'
    tags.comment_begin, tags.comment_end = '{{--', '--}'
    tags.q_comment_begin, tags.q_comment_end = '{{%-%-', '%-%-}}'

    pats.pat_any_syntax_begin =

        tags.q_tag_sign_begin..
        '['..
        tags.q_tag_var_begin..
        tags.q_tag_raw_begin..
        tags.q_tag_lua_begin..
        tags.q_tag_nev_begin..
        tags.q_tag_comment_begin..
        ']+'

    pats.q_verbatim_end = '@endverbatim'

end

return _M

