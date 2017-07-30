
local lx, _M = oo{
    _cls_   = '',
    _ext_   = 'unit.exception',
    _bond_  = 'strable'
}

local app, lf, tb, str = lx.kit()

function _M:toStr()

    return self:getMsg()
end

return _M

