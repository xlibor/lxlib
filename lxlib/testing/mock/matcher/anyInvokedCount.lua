
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'unit.mock.matcher.invokedRecorder'
}

local app, lf, tb, str = lx.kit()

-- @return string

function _M:toStr()

    return 'invoked zero or more times'
end

function _M:verify()

end

return _M

