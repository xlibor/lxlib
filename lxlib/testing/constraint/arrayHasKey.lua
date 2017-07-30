
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param int|string key

function _M:ctor(key)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.key = key
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    if lf.isTbl(other) then
        
        if lf.isObj(other) then
            if other:__has('_get_') then
                return other._get_(other, self.key) and true or false
            end
        else
            return tb.has(other, self.key)
        end
    end

    return false
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'has the key ' .. self.exporter:export(self.key)
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return 'an array ' .. self:toStr()
end

return _M

