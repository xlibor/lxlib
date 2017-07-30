
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param string string
-- @param bool   ignoreCase

function _M:ctor(string, ignoreCase)

    ignoreCase = ignoreCase or false
    self.__skip = true
    self:__super(_M, 'ctor')
    self.string = string
    self.ignoreCase = ignoreCase
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    if self.ignoreCase then
        
        return str.strpos(other, self.string) and true or false
    end
    
    return str.strpos(other, self.string) and true or false
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    local string
    if self.ignoreCase then
        string = str.lower(self.string)
     else 
        string = self.string
    end
    
    return fmt('contains "%s"', string)
end

return _M

