
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        constraints = {}
    }
    
    return oo(this, mt)
end

-- @var Constraint[]
-- @param Constraint[] constraints

function _M:setConstraints(constraints)

    local constraint
    self.constraints = {}
    for _, constraint in pairs(constraints) do
        if not constraint:__is('Constraint') then
            constraint = new('isEqual', constraint)
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
-- @throws ExpectationFailedException

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    local result
    local success = true
    local lastResult = nil
    local constraint = nil
    for _, constraint in pairs(self.constraints) do
        result = constraint:evaluate(other, description, true)
        if result == lastResult then
            success = false
            break
        end
        lastResult = result
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
            text = text .. ' xor '
        end
        text = text .. constraint:toStr()
    end
    
    return text
end

-- Counts the number of constraint elements.
-- @return int

function _M:count()

    local count = 0
    for _, constraint in pairs(self.constraints) do
        count = count + constraint:count()
    end
    
    return count
end

return _M

