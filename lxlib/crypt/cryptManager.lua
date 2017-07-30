
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'manager'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:ctor()

end

function _M:driver(driver)

    return self:resolve(driver)
end

function _M:createAesDriver(config)

    local key = app:conf('app.key')
    local aesCrypter = app:make('crypt.crypter.aes', key, config)

    return aesCrypter
end

function _M.__:getConfig(name)

    return app:conf('crypt.crypters.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('crypt.driver')
end

function _M:_run_(method)

    return 'driver'
end

return _M

