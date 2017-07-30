
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.statelessInvocation'
}

local app, lf, tb, str = lx.kit()

-- @return string

function _M:toStr()

    return 'with any parameters'
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    return true
end

return _M

