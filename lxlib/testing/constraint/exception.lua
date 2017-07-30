
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param string className

function _M:ctor(className)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.className = className
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return other:__is(self.className)
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    local message
    if other then
        message = ''
        if other:__is('throwable') then
            message = '. Message was: "' .. other:getMessage()
        end
        
        return fmt('exception of type "%s" matches expected exception "%s"%s', other.__cls, self.className, message)
    end
    
    return fmt('exception of type "%s" is thrown', self.className)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return fmt('exception of type "%s"', self.className)
end

return _M

