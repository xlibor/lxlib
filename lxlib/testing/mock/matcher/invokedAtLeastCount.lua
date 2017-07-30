
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.invokedRecorder'
}

local app, lf, tb, str = lx.kit()

-- @param int requiredInvocations

function _M:ctor(requiredInvocations)

    self.requiredInvocations = requiredInvocations
end

-- @return string

function _M:toStr()

    return 'invoked at least ' .. self.requiredInvocations .. ' times'
end

-- Verifies that the current expectation is valid. If everything is OK the
-- code should just return, if not it must throw an exception.

function _M:verify()

    local count = self:getInvocationCount()
    if count < self.requiredInvocations then
        lx.throw('unit.expectationFailedException', 
            'Expected invocation at least ' .. 
            self.requiredInvocations .. 
            ' times but it occurred ' .. count .. ' time(s).'
        )
    end
end

return _M

