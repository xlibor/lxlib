
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:reg()

    app:bond('crypterBond',     'lxlib.crypt.crypterBond')
    
    app:bind('crypt',           'lxlib.crypt.cryptManager')
end

function _M:boot()

end

return _M

