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
        innerConstraint = nil
    }
    
    return oo(this, mt)
end

-- @var Constraint
-- @param Constraint innerConstraint

function _M:ctor(innerConstraint)

    parent.__construct()
    self.innerConstraint = innerConstraint
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
    try(function()
        
        return self.innerConstraint:evaluate(other, description, returnResult)
    end)
    :catch(function(ExpectationFailedException e) 
        self:fail(other, description)
    end)
    :run()
end

-- Counts the number of constraint elements.
-- @return int

function _M:count()

    return self.innerConstraint:count()
end

return _M

