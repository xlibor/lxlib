
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

    local cmdList = 'block,endblock,set,endset'
    cmdList = tb.flip(cmdList, true)

    self.cmds = tb.merge(self.cmds, cmdList)
 
end

function _M:appendPats()

    local pats = self.pats
    local tags = self.tags

    pats.q_verbatim_end = 'endverbatim%s*'..tags.q_stmt_end
end

return _M

