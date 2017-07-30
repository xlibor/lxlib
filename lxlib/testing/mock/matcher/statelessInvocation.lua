
local lx, _M, mt = oo{
    _cls_   = '',
    _bond_  = 'unit.mock.matcher.invocation',
    a__     = {}
}

local app, lf, tb, str = lx.kit()

-- @param unit.mock.invocation invocation Object containing information on a mocked or stubbed method which was invoked
-- @return mixed

function _M:invoked(invocation)

end

-- Checks if the invocation invocation matches the current rules. If it does
-- the matcher will get the invoked() method called which should check if an
-- expectation is met.
-- @param unit.mock.invocation invocation Object containing information on a mocked or stubbed method which was invoked
-- @return bool

function _M:verify()

end

return _M

