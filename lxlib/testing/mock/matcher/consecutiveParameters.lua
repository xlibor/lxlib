
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.statelessInvocation'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        parameterGroups = {},
        invocations = {}
    }
    
    return oo(this, mt)
end

-- @param table parameterGroups

function _M:ctor(parameterGroups)

    local parameter
    for index, parameters in ipairs(parameterGroups) do
        for _, parameter in ipairs(parameters) do
            if not parameter:__is('unit.constraint') then
                parameter = new('unit.constraint.isEqual', parameter)
            end
            tapd(self.parameterGroups[index], parameter)
        end
    end
end

-- @return string

function _M:toStr()

    local text = 'with consecutive parameters'
    
    return text
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    tapd(self.invocations, invocation)
    local callIndex = #self.invocations - 1
    self:verifyInvocation(invocation, callIndex)
    
    return false
end

function _M:verify()

    for callIndex, invocation in ipairs(self.invocations) do
        self:verifyInvocation(invocation, callIndex)
    end
end

-- Verify a single invocation
-- @param unit.mock.invocation      invocation
-- @param int                       callIndex

function _M.__:verifyInvocation(invocation, callIndex)

    local parameters
    if self.parameterGroups[callIndex] then
        parameters = self.parameterGroups[callIndex]
     else 
        -- no parameter assertion for this call index
        return
    end
    if not invocation then
        lx.throw('unit.expectationFailedException', 'Mocked method does not exist.')
    end
    if #invocation.parameters < #parameters then
        lx.throw('unit.expectationFailedException',
            fmt('Parameter count for invocation %s is too low.',
                invocation:toStr()
            )
        )
    end
    for i, parameter in ipairs(parameters) do
        parameter:evaluate(invocation.parameters[i],
            fmt('Parameter %s for invocation #%d %s does not match expected ' .. 'value.',
                i, callIndex, invocation:toStr()
            )
        )
    end
end

return _M

