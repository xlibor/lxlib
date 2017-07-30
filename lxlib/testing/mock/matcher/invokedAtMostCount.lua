
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.invokedRecorder'
}

local app, lf, tb, str = lx.kit()

-- @param int allowedInvocations

function _M:ctor(allowedInvocations)

    self.allowedInvocations = allowedInvocations
end

-- @return string

function _M:toStr()

    return 'invoked at most ' .. self.allowedInvocations .. ' times'
end

-- Verifies that the current expectation is valid. If everything is OK the
-- code should just return, if not it must throw an exception.

function _M:verify()

    local count = self:getInvocationCount()
    if count > self.allowedInvocations then
        lx.throw('unit.expectationFailedException',
            'Expected invocation at most ' .. 
            self.allowedInvocations .. 
            ' times but it occurred ' .. count .. ' time(s).'
        )
    end
end

return _M

