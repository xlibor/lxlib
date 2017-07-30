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
        expectedMessageRegExp = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param string expected

function _M:ctor(expected)

    parent.__construct()
    self.expectedMessageRegExp = expected
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param \PHPUnit\Framework\Exception other
-- @return bool

function _M.__:matches(other)

    local match = RegularExpressionUtil.safeMatch(self.expectedMessageRegExp, other:getMessage())
    if false == match then
        lx.throw('pHPUnit', "Invalid expected exception message regex given: '{self.expectedMessageRegExp}'")
    end
    
    return 1 == match
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return fmt("exception message '%s' matches '%s'", other:getMessage(), self.expectedMessageRegExp)
end

-- @return string

function _M:toStr()

    return 'exception message matches '
end

return _M

