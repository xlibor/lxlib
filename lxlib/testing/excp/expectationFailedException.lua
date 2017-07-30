
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.assertionFailedError'
}

local app, lf, tb, str = lx.kit()

-- @param string                        message
-- @param unit.comparisonFailure|null   comparisonFailure
-- @param exception|null                previous

function _M:ctor(message, comparisonFailure, previous)

    self.comparisonFailure = comparisonFailure
    self.__skip = true
    self:__super(_M, 'ctor', message, 0, previous)
end

-- @return comparisonFailure|null

function _M:getComparisonFailure()

    return self.comparisonFailure
end

return _M

