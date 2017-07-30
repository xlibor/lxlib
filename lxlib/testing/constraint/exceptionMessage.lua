-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        expectedMessage = nil
    }
    
    return oo(this, mt)
end

-- @var int
-- @param string expected

function _M:ctor(expected)

    parent.__construct()
    self.expectedMessage = expected
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param \Throwable other
-- @return bool

function _M.__:matches(other)

    return \str.strpos(other:getMessage(), self.expectedMessage) ~= false
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return fmt("exception message '%s' contains '%s'", other:getMessage(), self.expectedMessage)
end

-- @return string

function _M:toStr()

    return 'exception message contains '
end

return _M

