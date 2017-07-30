
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

function _M:createShaDriver(config)

    local shaHasher = app:make('hash.hasher.sha', config)

    return shaHasher
end

function _M:createMd5Driver(config)

    local md5Hasher = app:make('hash.hasher.md5', config)

    return md5Hasher
end

function _M.__:getConfig(name)

    return app:conf('hash.hashers.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('hash.driver')
end

function _M:_run_(method)

    return 'driver'
end

return _M

