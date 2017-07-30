
local lx, _M, mt = oo{
    _cls_     = '',
    _bond_    = 'strable'    
}

local app, lf, tb, str = lx.kit()

function _M:new(msg)

    local this = {
        msg = msg
    }
    
    return oo(this, mt)
end

function _M:getMessage()

    return self.msg
end

function _M:toStr()

    return self.msg
end

return _M

