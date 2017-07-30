
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param mixed value

function _M:ctor(value)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.value = value
end

-- Evaluates the constraint for parameter other
-- If returnResult is set to false (the default), an exception is thrown
-- in case of a failure. null is returned otherwise.
-- If returnResult is true, the result of the evaluation is returned as
-- a boolean value instead: true in case of success, false in case of a
-- failure.
-- @param mixed|null         other        Value or object to evaluate.
-- @param string|null        description  Additional information about the test
-- @param bool|null          returnResult Whether to return a result or throw an exception
-- @return mixed|null

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    local f
    local success
    if lf.isFloat(self.value) and lf.isFloat(other) then
        success = math.abs(self.value - other) < 0.0000000001
    else
        if lf.isTbl(self.value) and lf.isTbl(other) then
            success = tb.eq(self.value, other)
        else
            success = self.value == other
        end
    end
    if returnResult then
        
        return success
    end
    if not success then
        f = nil
        -- if both values are strings, make sure a diff is generated
        if lf.isStr(self.value) and lf.isStr(other) then
            f = new('unit.comparisonFailure', self.value, other, fmt("'%s'", self.value), fmt("'%s'", other))
        end
        self:fail(other, description, f)
    end
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    if lf.isObj(self.value) and lf.isObj(other) then
        
        return 'two variables reference the same object'
    end
    if lf.isStr(self.value) and lf.isStr(other) then
        
        return 'two strings are identical'
    end
    
    return self:__super(_M, 'failureDescription', other)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    if lf.isObj(self.value) then
        
        return 'is identical to an object of class "' .. self.value.__cls .. '"'
    end
    
    return 'is identical to ' .. self.exporter:export(self.value)
end

return _M

