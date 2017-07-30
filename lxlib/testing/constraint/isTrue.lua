
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed|null     other   Value or object to evaluate.
-- @return bool

function _M:matches(other)

    return other and true or false
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is true'
end

return _M

