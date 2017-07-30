
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'controller'
}

function _M:ctor()

    self:setBar('auth')
end

function _M:index(c)

    c:view('home')
end

return _M

