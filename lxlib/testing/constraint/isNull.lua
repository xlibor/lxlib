
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

    return other == nil
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is null'
end

return _M

