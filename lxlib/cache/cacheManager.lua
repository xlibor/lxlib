
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

_M.store = _M.driver

function _M.__:createArrDriver(config)

    return self:buildDoer(
        app:make('cache.arrStore'),
        config
    )
end

function _M.__:createFileDriver(config)

    local path = config.path

    return self:buildDoer(
        app:make('cache.fileStore', app.files, path),
        config
    )
end

function _M.__:createDbDriver(config)

    local db = app:get('db')
    local connName = config.connection
    local conn = db:connection(connName)

    return self:buildDoer(
        app:make('cache.dbStore',
            conn, config['table']
        ), config
    )
end

function _M:createRedisDriver(config)

    local redis = app:get('redis')
    local connection = config.connection or 'default'

    return self:buildDoer(
        app:make('cache.redisStore',
            redis, connection
        ), config
    )
end

function _M:buildDoer(store, config)

    local doer = app:make('cache.doer', store, config)

    return doer
end

function _M.__:getConfig(name)

    return app:conf('cache.stores.' .. name)
end

function _M:getDefaultDriver()

    return app:conf('cache.driver')
end

function _M:enable(isEnable)

    isEnable = lf.needTrue(isEnable)
    app:setConf('cache.enable', isEnable)

    return self
end

function _M:_run_(method)

    return 'store'
end

return _M

