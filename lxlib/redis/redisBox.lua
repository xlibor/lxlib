
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app = lx.app()

function _M:reg()

    app:bindFrom('lxlib.redis', {
        ['redis.connection']    = 'connection',
        ['redis.connector']     = 'connector',
        ['redis.client']        = 'client'
    })

    app:single('redis', 'lxlib.redis.manager')
end

function _M:boot()
 
end

return _M

