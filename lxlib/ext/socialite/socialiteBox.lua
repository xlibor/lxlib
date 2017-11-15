
local lx, _M = oo{
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str = lx.kit()
local boxPath = 'lxlib.ext.socialite.'

function _M:reg()

    self:regDepends()
    app:single('socialite', boxPath .. 'socialiteManager')
end

function _M:regDepends()

    app:bindFrom(boxPath .. 'provider', {
        'abstractProvider', 'bitbucketProvider',
        'facebookProvider', 'githubProvider',
        'googleProvider', 'linkedInProvider',
        'wechatProvider', 'qqProvider'
    }, {prefix = 'socialite.'})

    app:bind('socialite.user',  boxPath .. 'user')
    app:bind('socialite.accessToken', boxPath .. 'accessToken')
    app:bond('socialite.userBond',      boxPath .. 'bond.user')
    app:bond('socialite.providerBond',  boxPath .. 'bond.provider')
    app:bind('socialite.invalidStateException', boxPath .. 'excp.invalidStateException')
end

function _M:boot()

end

return _M

