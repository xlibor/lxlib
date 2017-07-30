-- This file is part of PHPUnit.
-- (c) Sebastian Bergmann <sebastian@phpunit.de>
-- For the full copyright and license information, please view the LICENSE
-- file that was distributed with this source code.

-- Logical AND.
-- @since Class available since Release 3.0.0


local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'pHPUnit_Framework_Constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        constraints = {},
        lastConstraint = nil
    }
    
    return oo(this, mt)
end
-- @var PHPUnit_Framework_Constraint[]
-- @var PHPUnit_Framework_Constraint
-- @param PHPUnit_Framework_Constraint[] constraints
-- @throws PHPUnit_Framework_Exception

function _M:setConstraints(constraints)

    self.constraints = {}
    for _, constraint in pairs(constraints) do
        if not constraint:__is('PHPUnit_Framework_Constraint') then
            lx.throw('pHPUnit_Framework_Exception', 'All parameters to ' .. __CLASS__ .. ' must be a constraint object.')
        end
        self.constraints[] = constraint
    end
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
-- @throws PHPUnit_Framework_ExpectationFailedException

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    local success = true
    local constraint = nil
    for _, constraint in pairs(self.constraints) do
        if not constraint:evaluate(other, description, true) then
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

    local text = ''
    for key, constraint in pairs(self.constraints) do
        if key > 0 then
            text = text .. ' and '
        end
        text = text .. constraint:toStr()
    end
    
    return text
end
-- Counts the number of constraint elements.
-- @return int
-- @since Method available since Release 3.4.0

function _M:count()

    local count = 0
    for _, constraint in pairs(self.constraints) do
        count = count + #constraint
    end
    
    return count
end

return _M

