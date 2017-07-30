
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

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

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    
    return returnResult and true or nil
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is anything'
end

-- Counts the number of constraint elements.
-- @return int

function _M:count()

    return 0
end

return _M

