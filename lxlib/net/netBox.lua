
local lx, _M = oo{
    _cls_    = '',
    _ext_    = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:ctor()

end

function _M:reg()

    app:bindFrom('lxlib.net.http', {
        'client', 'request', 'response'
    }, {prefix = 'net.http.'})

end

function _M:boot()

end

return _M

