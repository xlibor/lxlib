
local lx, _M, mt = oo{
    _cls_       = '',
    _ext_       = 'unit.constraint',
    _static_    = {}
}

local app, lf, tb, str = lx.kit()

local LogicalAnd = lx.use('unit.constraint.logicalAnd')
local LogicalOr  = lx.use('unit.constraint.logicalOr')

local static

function _M._init_(this)

    static = this.static
end

-- @param unit.constraint|mixed   constraint

function _M:ctor(constraint)

    self.__skip = true
    self:__super(_M, 'ctor')
    if not constraint:__is('unit.constraint') then
        constraint = new('unit.constraint.isEqual', constraint)
    end
    self.constraint = constraint
end

-- @param string string
-- @return string

function _M.s__.negate(string)

    return str.replace(string, {
            'contains ', 'exists', 'has ', 'is ', 'are ', 'matches ',
            'starts with ', 'ends with ', 'reference ', 'not not '
        }, {
            'does not contain ', 'does not exist', 'does not have ',
            'is not ', 'are not ', 'does not match ', 'starts not with ',
            'ends not with ', 'don\'t reference ', 'not '
        }
    )
end

-- Evaluates the constraint for parameter other
-- If returnResult is set to false (the default), an exception is thrown
-- in case of a failure. null is returned otherwise.
-- If returnResult is true, the result of the evaluation is returned as
-- a boolean value instead: true in case of success, false in case of a
-- failure.
-- @param mixed|null         other        Value or object to evaluate.
-- @param string            description  Additional information about the test
-- @param bool|null         returnResult Whether to return a result or throw an exception
-- @return mixed|null

function _M:evaluate(other, description, returnResult)

    returnResult = returnResult or false
    description = description or ''
    local success = not self.constraint:evaluate(other, description, true)
    if returnResult then
        
        return success
    end
    if not success then
        self:fail(other, description)
    end
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed|null    other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    local st = self.constraint.__cls
    if st == LogicalAnd.__cls then
     elseif st == self.class then
     elseif st == LogicalOr.__cls then
        
        return 'not( ' .. self.constraint:failureDescription(other) .. ' )'
     else 
        
        return static.negate(self.constraint:failureDescription(other))
    end
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    local st = self.constraint.__cls
    if st == LogicalAnd.__cls then
    elseif st == self.__cls then
    elseif st == LogicalOr.__cls then
        
        return 'not( ' .. self.constraint:toStr() .. ' )'
     else 
        
        return static.negate(self.constraint:toStr())
    end
end

-- Counts the number of constraint elements.
-- @return int

function _M:count()

    return self.constraint:count()
end

return _M

