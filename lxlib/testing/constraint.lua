
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = {'countable', 'strable'},
    a__         = {},
    _static_    = {}
}

local app, lf, tb, str, new = lx.kit()

function _M:new()

    local this = {
        exporter = new('unit.exporter')
    }
    
    return oo(this, mt)
end

-- Evaluates the constraint for parameter other
-- If returnResult is set to false (the default), an exception is thrown
-- in case of a failure. null is returned otherwise.
-- If returnResult is true, the result of the evaluation is returned as
-- a boolean value instead: true in case of success, false in case of a
-- failure.
-- @param mixed|null        other        Value or object to evaluate.
-- @param string|null       description  Additional information about the test
-- @param bool|null         returnResult Whether to return a result or throw an exception
-- @return mixed|null

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    local success = false
    if self:matches(other) then
        success = true
    end
    if returnResult then
        
        return success
    end
    if not success then
        self:fail(other, description)
    end
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- This method can be overridden to implement the evaluation algorithm.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M:matches(other)

    return false
end

-- Counts the number of constraint elements.
-- @return int

function _M:count()

    return 1
end

-- Throws an exception for the given compared value and test description
-- @param mixed|null                    other             Evaluated value or object.
-- @param string                        description       Additional information about the test
-- @param unit.comparisonFailure|null   comparisonFailure

function _M.__:fail(other, description, comparisonFailure)

    local failureDescription = fmt('Failed asserting that %s.', self:failureDescription(other))
    local additionalFailureDescription = self:additionalFailureDescription(other)
    if additionalFailureDescription then
        failureDescription = failureDescription .. "\n" .. additionalFailureDescription
    end
    if not lf.isEmpty(description) then
        failureDescription = description .. "\n" .. failureDescription
    end

    lx.throw('unit.expectationFailedException', failureDescription, comparisonFailure)
end

-- Return additional failure description where needed
-- The function can be overridden to provide additional failure
-- information like a diff
-- @param mixed|null     other Evaluated value or object.
-- @return string

function _M.__:additionalFailureDescription(other)

    return ''
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- To provide additional failure information additionalFailureDescription
-- can be used.
-- @param mixed|null    other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return self.exporter:export(other) .. ' ' .. self:toStr()
end

return _M

