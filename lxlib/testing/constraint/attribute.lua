-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'composite'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        attributeName = nil
    }
    
    return oo(this, mt)
end

-- @var string
-- @param Constraint constraint
-- @param string     attributeName

function _M:ctor(constraint, attributeName)

    parent.__construct(constraint)
    self.attributeName = attributeName
end

-- Evaluates the constraint for parameter other
-- If returnResult is set to false (the default), an exception is thrown
-- in case of a failure. null is returned otherwise.
-- If returnResult is true, the result of the evaluation is returned as
-- a boolean value instead: true in case of success, false in case of a
-- failure.
-- @param mixed  other        Value or object to evaluate.
-- @param string description  Additional information about the test
-- @param bool   returnResult Whether to return a result or throw an exception
-- @return mixed
-- @throws ExpectationFailedException

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    
    return parent.evaluate(Assert.readAttribute(other, self.attributeName), description, returnResult)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'attribute "' .. self.attributeName .. '" ' .. self.innerConstraint:toStr()
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return self:toStr()
end

return _M

