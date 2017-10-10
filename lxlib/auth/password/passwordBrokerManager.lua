
local lx, _M, mt = oo{
    _cls_ = ' PasswordBrokerManager',
    _bond_ = 'factoryContract'
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        app = nil,
        brokers = {}
    }
end

function _M:ctor(app)

    app = app
end

function _M:broker(name)

    name = name or self:getDefaultDriver()
    
    return self.brokers[name] and self.brokers[name] or (self.brokers[name] = self:resolve(name))
end

function _M.__:resolve(name)

    local config = self:getConfig(name)
    if not config then
        lx.throw('invalidArgumentException', "Password resetter [{name}] is not defined.")
    end
    
    
    return new('passwordBroker',self:createTokenRepository(config), app.auth:createUserProvider(config['provider']))
end

function _M.__:createTokenRepository(config)

    local key = app:conf('app.key')
    if str.startsWith(key, 'base64:') then
        key = base64_decode(str.substr(key, 7))
    end
    local connection = config.connection
    
    return new('databaseTokenRepository',app:get('db'):connection(connection), app['hash'], config['table'], key, config['expire'])
end

function _M.__:getConfig(name)

    return app:conf('auth.passwords.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('auth.defaults.passwords')
end

function _M:setDefaultDriver(name)

    app:setConf('auth.defaults.passwords', name)
end

function _M:__call(method, parameters)

    return self:broker():[method](...parameters)
end

return _M

