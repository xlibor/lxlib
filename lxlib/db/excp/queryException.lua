
local _M = { 
    _cls_     = '',
    _ext_     = {
        from = 'ldoException'
    }
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)

function _M:new(sql, bindings, pre)

    local this = {
        sql         = sql,
        bindings     = bindings,
        pre    = pre
    }
    
    setmetatable(this, mt)
 
    return this
end

function _M:ctor(sql, bindings, pre)

    self.code = pre.code or 0
    self.msg = self:formatMessage(sql, bindings, pre)

end

function _M.__:formatMessage(sql, bindings, pre)
 
    local preMsg = pre:getMsg()

    local msg = preMsg .. ' (SQL: ' .. sql .. ')'

    return msg
end

function _M:getSql()

end

function _M:getBinginds()

end

return _M

