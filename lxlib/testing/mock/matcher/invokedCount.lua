
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.invokedRecorder'
}

local app, lf, tb, str = lx.kit()

-- @var int
-- @param int expectedCount

function _M:ctor(expectedCount)

    self.expectedCount = expectedCount
end

-- @return bool

function _M:isNever()

    return self.expectedCount == 0
end

-- @return string

function _M:toStr()

    return 'invoked ' .. self.expectedCount .. ' time(s)'
end

-- @param unit.mock.invocation invocation

function _M:invoked(invocation)

    local message
    self:__super(_M, 'invoked', invocation)
    local count = self:getInvocationCount()
    if count > self.expectedCount then
        message = invocation:toStr() .. ' '
        local st = self.expectedCount
        if st == 0 then
            message = message .. 'was not expected to be called.'
        elseif st == 1 then
            message = message .. 'was not expected to be called more than once.'
        else 
            message = message .. fmt('was not expected to be called more than %d times.', self.expectedCount)
        end
        lx.throw('unit.expectationFailedException', message)
    end
end

-- Verifies that the current expectation is valid. If everything is OK the
-- code should just return, if not it must throw an exception.

function _M:verify()

    local count = self:getInvocationCount()
    if count ~= self.expectedCount then
        lx.throw('unit.expectationFailedException',
            fmt('Method was expected to be called %d times, '..
                'actually called %d times.',
                self.expectedCount, count
            )
        )
    end
end

return _M

