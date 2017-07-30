
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()
local each = lf.each

-- @param mixed value
-- @param bool  checkForObjectIdentity
-- @param bool  checkForNonObjectIdentity

function _M:ctor(value, checkForObjectIdentity, checkForNonObjectIdentity)

    checkForNonObjectIdentity = checkForNonObjectIdentity or false
    checkForObjectIdentity = lf.needTrue(checkForObjectIdentity)
    self.__skip = true
    self:__super(_M, 'ctor')
    self.checkForObjectIdentity = checkForObjectIdentity
    self.checkForNonObjectIdentity = checkForNonObjectIdentity
    self.value = value
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    if lf.isObj(self.value) then
        for _, element in each(other) do
            if self.checkForObjectIdentity and element == self.value then
                
                return true
            end
            if not self.checkForObjectIdentity and element == self.value then
                
                return true
            end
        end
    else
        for _, element in each(other) do
            if self.checkForNonObjectIdentity and element == self.value then
                
                return true
            end
            if not self.checkForNonObjectIdentity and element == self.value then
                
                return true
            end
        end
    end
    
    return false
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    if lf.isStr(self.value) and str.strpos(self.value, "\n") then
        
        return 'contains "' .. self.value .. '"'
    end
    
    return 'contains ' .. self.exporter:export(self.value)
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return fmt('%s %s', lf.isTbl(other) and 'an array' or 'a eachable', self:toStr())
end

return _M

