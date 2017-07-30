
local lx, _M, mt = oo{
    _cls_ = '',
    _bond_ = 'unit.mock.matcher.invocation'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        sequenceIndex = nil,
        currentIndex = -1
    }
    
    return oo(this, mt)
end

-- @param int sequenceIndex

function _M:ctor(sequenceIndex)

    self.sequenceIndex = sequenceIndex
end

-- @return string

function _M:toStr()

    return 'invoked at sequence index ' .. self.sequenceIndex
end

-- @param unit.mock.invocation invocation
-- @return bool

function _M:matches(invocation)

    self.currentIndex = self.currentIndex + 1
    
    return self.currentIndex == self.sequenceIndex
end

-- @param unit.mock.invocation invocation

function _M:invoked(invocation)

end

-- Verifies that the current expectation is valid. If everything is OK the
-- code should just return, if not it must throw an exception.

function _M:verify()

    if self.currentIndex < self.sequenceIndex then
        lx.throw('unit.expectationFailedException',
            fmt('The expected invocation at index %s was never reached.',
                self.sequenceIndex
            )
        )
    end
end

return _M

