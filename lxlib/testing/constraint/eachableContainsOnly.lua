-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Constraint that asserts that the eachable it is applied to contains
-- only values of a given type.


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        constraint = nil,
        type = nil
    }
    
    return oo(this, mt)
end

-- @var Constraint
-- @var string
-- @param string type
-- @param bool   isNativeType

function _M:ctor(type, isNativeType)

    isNativeType = lf.needTrue(isNativeType)
    parent.__construct()
    if isNativeType then
        self.constraint = new('isType', type)
     else 
        self.constraint = new('isInstanceOf', type)
    end
    self.type = type
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
    local success = true
    for _, item in pairs(other) do
        if not self.constraint:evaluate(item, '', true) then
            success = false
            break
        end
    end
    if returnResult then
        
        return success
    end
    if not success then
        self:fail(other, description)
    end
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'contains only values of type "' .. self.type .. '"'
end

return _M

