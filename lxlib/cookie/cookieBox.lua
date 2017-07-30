
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    app:bind('simpleCookie', 'lxlib.cookie.base.cookie')
    app:keep('cookie', 'lxlib.cookie.cookieJar')
    app:single('lxlib.cookie.bar.addToResponse')

end

function _M:boot()

end

return _M

