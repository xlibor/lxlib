
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed|null    other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    if lf.isA(other, 'countable') then
        
        return other:count() == 0
    end
    
    return lf.isEmpty(other)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is empty'
end

-- Returns the description of the failure
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    local vt = type(other)

    return fmt('%s %s %s', vt == 'table' and 'an' or 'a', vt, self:toStr())
end

return _M

