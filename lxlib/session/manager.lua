
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'manager'
}

local app = lx.app()

function _M:ctor()

    self.inCtx = true
end

function _M:driver(name)

    return self:resolve(name)
end

function _M.__:createCookieDriver(config)

    local lifetime = app:conf('session.lifetime')
 
    return self:buildSession(
        app:make('session.cookieHandler', lifetime)
    )
end

function _M.__:createFileDriver(config)

    local path = config.path
 
    return self:buildSession(
        app:make('session.fileHandler', app:get('files'), path)
    )
end

function _M.__:createDbDriver(config)
     
    local conn = self:getDbConnection(config)
    local table = config.table

    return self:buildSession(
        app:make('session.dbHandler', conn, table)
    )
end

function _M.__:getDbConnection(config)

    local conn = config.connection

    return app:get('db'):connection(conn)
end

function _M.__:createRedisDriver(config)

    local handler = self:createCacheHandler('redis')
    handler:getCache():getStore()
        :setConnection(config.connection)

    return self:buildSession(handler)
end

function _M.__:createCacheHandler(driver)

    local store = driver
    local minutes = app:conf('session.lifetime')

    return app:make('session.cacheHandler',
        app:get('cache'):store(store):__clone(), minutes
    )
end

function _M.__:createCacheBased(driver)

    return self:buildSession(self:createCacheHandler(driver))
end

function _M.__:buildSession(handler)

    local name = app:conf('session.cookie')
    
    return app:make('session.commonStore', name, handler)
 
end

function _M:setDefaultDriver(name)

    app:conf('session.driver', name)
end

function _M.__:getConfig(name)

    return app:conf('session.drivers.' .. name)
end

function _M.c__:getSessionConfig()

    return app:conf('session')
end

function _M.c__:getDefaultDriver()

    return app:conf('session.driver')
end

return _M

