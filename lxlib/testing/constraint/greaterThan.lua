
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param numeric value

function _M:ctor(value)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.value = value
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other Value or object to evaluate.
-- @return bool

function _M.__:matches(other)

    return self.value < other
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return 'is greater than ' .. self.exporter:export(self.value)
end

return _M

