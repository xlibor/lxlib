
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.stub.return'
}

local app, lf, tb, str = lx.kit()

function _M:ctor(value)

    self.value = value
end

return _M

