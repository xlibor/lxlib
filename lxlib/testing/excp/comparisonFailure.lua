
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'runtimeException'
}

local app, lf, tb, str = lx.kit()

-- Expected value of the retrieval which does not match actual.
-- @param mixed             expected         Expected value retrieved.
-- @param mixed|null        actual           Actual value retrieved.
-- @param string            expectedAsString
-- @param string            actualAsString
-- @param bool|null         identical
-- @param string|null       message          A string which is prefixed on all returned lines
--                                       in the difference output.

function _M:ctor(expected, actual, expectedAsString, actualAsString, identical, message)

    message = message or ''
    identical = identical or false
    self.expected = expected
    self.actual = actual
    self.expectedAsString = expectedAsString
    self.actualAsString = actualAsString
    self.msg = message

    -- if expectedAsString and actualAsString then
    --     echo('expectedAsString:', expectedAsString)
    --     echo('actualAsString:', actualAsString)
    -- end
end

-- @return mixed

function _M:getActual()

    return self.actual
end

-- @return mixed

function _M:getExpected()

    return self.expected
end

-- @return string

function _M:getActualAsString()

    return self.actualAsString
end

-- @return string

function _M:getExpectedAsString()

    return self.expectedAsString
end

-- @return string

function _M:getDiff()

    if not self.actualAsString and not self.expectedAsString then
        
        return ''
    end
    local differ = new('differ', "\n--- Expected\n+++ Actual\n")
    
    return differ:diff(self.expectedAsString, self.actualAsString)
end

-- @return string

function _M:toStr()

    return self.message .. self:getDiff()
end

return _M

