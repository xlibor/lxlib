
local lx, _M = oo{
    _cls_    = '',
    _ext_    = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

end

function _M:reg()

    local prefix = 'net.http.'
    app:bindFrom('lxlib.net.http', {
        [prefix .. 'client']    = 'client',
        [prefix .. 'request']    = 'request',
        [prefix .. 'response']    = 'response'
    })

end

function _M:boot()

end

return _M

