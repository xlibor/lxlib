
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.constraint'
}

local app, lf, tb, str = lx.kit()

-- @param int expected

function _M:ctor(expected)

    self.__skip = true
    self:__super(_M, 'ctor')
    self.expectedCount = expected or 0
end

-- Evaluates the constraint for parameter other. Returns true if the
-- constraint is met, false otherwise.
-- @param mixed other
-- @return bool

function _M.__:matches(other)

    return self.expectedCount == self:getCountOf(other)
end

-- @param table|countable other
-- @return int

function _M.__:getCountOf(other)

    local count = 0
    local key
    local iterator

    if not lf.isObj(other) then
        return tb.count(other)
    elseif other:__is('countable') then
        return other:count()
    elseif other:__is('eachable') then
        key = iterator:key()
        if key then
            iterator:rewind()
            while iterator:valid() do
                iterator:next()
                count = count + 1
            end
        end
        
        return count
    end
end

-- Returns the description of the failure.
-- The beginning of failure messages is "Failed asserting that" in most
-- cases. This method should return the second part of that sentence.
-- @param mixed other Evaluated value or object.
-- @return string

function _M.__:failureDescription(other)

    return fmt('actual size %d matches expected size %d', self:getCountOf(other), self.expectedCount)
end

-- @return string

function _M:toStr()

    return fmt('count matches %d', self.expectedCount)
end

return _M

