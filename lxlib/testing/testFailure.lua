
local lx, _M = oo{
    _cls_       = '',
    _static_    = {

    }
}

local app, lf, tb, str = lx.kit()
local static

function _M._init_(this)

    static = this.static
end

-- Constructs a TestFailure with the given test and exception.
-- @param unit.test         failedTest
-- @param throwable         t

function _M:ctor(failedTest, t)

    self.assertLine = lx.G('lxunitLastAssertLine')

    if failedTest:__is('strable') then
        self.testName = failedTest:toStr()
     else 
        self.testName = failedTest.__cls
    end
    if not failedTest:__is('unit.testCase') or not failedTest:isInIsolation() then
        self.failedTest = failedTest
    end
    self._thrownException = t
end

-- Returns a short description of the failure.
-- @return string

function _M:toStr()

    return fmt('%s: %s', self.testName, self._thrownException:getMsg())
end

-- Returns a description for the thrown exception.
-- @return string
-- @since Method available since Release 3.4.0

function _M:getExceptionAsString()

    return static.exceptionToString(self._thrownException)
end

-- Returns a description for an exception.
-- @param Exception e
-- @return string
-- @since Method available since Release 3.2.0

function _M.s__.exceptionToString(e)

    local buffer
    if e:__is('strable') then
        buffer = e:toStr()
        if e:__is('unit.expectationFailedException') and e:getComparisonFailure() then
            buffer = buffer .. e:getComparisonFailure():getDiff()
        end
        if not lf.isEmpty(buffer) then
            buffer = str.trim(buffer) .. "\n"
        end
    elseif e:__is('unit.error') then
        buffer = e:getMsg() .. "\n"
    elseif e:__is('unit.exceptionWrapper') then
        buffer = e:getClassname() .. ': ' .. e:getMsg() .. "\n"
    else
        buffer = e.__cls .. ': ' .. e:getMsg() .. "\n"
    end
    
    return buffer
end

-- Returns the name of the failing test (including data set, if any).
-- @return string

function _M:getTestName()

    return self.testName
end

function _M:getLine()

    return self.assertLine
end
-- Returns the failing test.
-- Note: The test object is not set when the test is executed in process
-- isolation.
-- @see PHPUnit_Framework_Exception
-- @return unit.test|null

function _M:failedTest()

    return self.failedTest
end

-- Gets the thrown exception.
-- @return exception

function _M:thrownException()

    return self._thrownException
end

-- Returns the exception's message.
-- @return string

function _M:exceptionMessage()

    return self:thrownException():getMsg()
end

-- Returns true if the thrown exception
-- is of type AssertionFailedError.
-- @return bool

function _M:isFailure()

    return self:thrownException():__is('unit.assertionFailedError')
end

return _M

