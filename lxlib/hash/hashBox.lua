
local lx, _M, mt = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()

function _M:reg()

    app:bond('hasherBond', 'lxlib.hash.hasherBond')
    
    app:bindFrom('lxlib.hash.hasher', {
        ['hash.hasher.sha']     = 'sha',
        ['hash.hasher.md5']     = 'md5'
    })

    app:single('hash', 'lxlib.hash.hashManager')
end

function _M:boot()

end

return _M

