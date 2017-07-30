
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'unit.mock.matcher.invocation',
    a__     = {}
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        invocations = {}
    }
    
    return oo(this, mt)
end

-- @return int

function _M:getInvocationCount()

    return #self.invocations
end

-- @return unit.mock.invocation[]

function _M:getInvocations()

    return self.invocations
end

-- @return bool

function _M:hasBeenInvoked()

    return #self.invocations > 0
end

-- @param unit.mock.invocation invocation

function _M:invoked(invocation)

    tapd(self.invocations, invocation)
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    return true
end

return _M

