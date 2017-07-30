
local _M = { 
    _cls_    = '',
    _ext_     = 'viewException'
}

local util = require('lxlib.view.engine.base.util')

function _M:ctor(tpl, pre)
    
    self.pre = pre
    local view = tpl.view
    self.view = view

    if tpl.errInfo then
        local lineContent = tpl.srclines[tpl.lineno] or ''
        lineContent = util.escape(lineContent)
        self.msg = tostring(tpl.errInfo) .. ',str:' .. lineContent
    else
        self.msg = 'in "' .. view .. '", near line:' .. tpl.lineno .. ', detail:' .. pre.msg
    end
end


return _M