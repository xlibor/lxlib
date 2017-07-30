
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.invokedRecorder'
}

local app, lf, tb, str = lx.kit()

-- @return string

function _M:toStr()

    return 'invoked at least once'
end

-- Verifies that the current expectation is valid. If everything is OK the
-- code should just return, if not it must throw an exception.

function _M:verify()

    local count = self:getInvocationCount()
    if count < 1 then
        lx.throw('unit.expectationFailedException',
            'Expected invocation at least once but it never occurred.'
        )
    end
end

return _M

