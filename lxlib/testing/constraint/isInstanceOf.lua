
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

    return fmt('%s is an instance of %s "%s"', self.exporter:shortenedExport(other), self:getType(), self.className)
end

-- Returns a string representation of the constraint.
-- @return string

function _M:toStr()

    return fmt('is instance of %s "%s"', self:getType(), self.className)
end

function _M.__:getType()

    return 'class'
end

return _M

