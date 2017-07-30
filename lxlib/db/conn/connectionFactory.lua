
local lx, _M, mt = oo{ 
    _cls_    = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()
    
    local this = {
    }

    oo(this, mt)

    return this
end

function _M:ctor()

end

function _M:make(config, name)
    
    config = self:parseConfig(config, name)

    if config.read then 
        return self:createReadWriteConnection(config)
    end

    return self:createSingleConnection(config)
end

function _M:createConnector(config)

    local driver = config.driver

    if not driver then 
        throw('invalidArgumentException', 'a driver must be specified.')
    end
 
    local key = 'db.connector.' .. driver
    if app:bound(key) then 
        return app:make(key)
    end

    if driver == 'mysql' then
        app:bind(key, 'lxlib.db.connector.mysqlConnector')
        return app:make(key)
    elseif driver == 'sqlite' then 
        app:bind(key, 'lxlib.db.connector.sqliteConnector')
        return app:make(key)
    elseif driver == 'pgsql' then 
        app:bind(key, 'lxlib.db.connector.postgresConnector')
        return app:make(key)
    end

    throw('invalidArgumentException', 'unsupported driver:' .. driver)
end

function _M.__:createConnection(driver, ldo, dbName, prefix, config)

    local key = 'db.conn.' .. driver

    if app:bound(key) then 
        return app:make(key, ldo, dbName, prefix, config)
    end

    if driver == 'mysql' then 
        return app:make('mysqlConn', ldo, dbName, prefix, config)
    elseif driver == 'sqlite' then
        return app:make('sqliteConn', ldo, dbName, prefix, config)
    elseif driver == 'pgsql' then 
        return app:make('pgsqlConn', ldo, dbName, prefix, config)
    end

    throw('invalidArgumentException', 'unsupported driver:' .. driver)
end

function _M.__:parseConfig(config, name)

    tb.add(config, 'prefix', '')
    tb.add(config, 'name', name)

    return config
end

function _M.__:createSingleConnection(config)

    local ldo = function()
        return self:createConnector(config):connect(config)
    end

    return self:createConnection(config.driver, ldo, config.database, config.prefix, config)
end

function _M.__:createReadWriteConnection(config)

    local connection = self:createSingleConnection(self:getWriteConfig(config))

    return connection:setReadLdo(self:createReadLdo(config))
end

function _M.__:getReadConfig(config)
    local readConfig = self:getReadWriteConfig(config, 'read')
    local host = readConfig.host

    if host then
        if type(host) == 'table' then 
            if #host > 1 then 
                readConfig.host = tb.rand(host)
            else
                readConfig.host = host[1]
            end
        end
    end

    return self:mergeReadWriteConfig(config, readConfig)
end

function _M.__:getWriteConfig(config)

    local writeConfig = self:getReadWriteConfig(config, 'write')

    return self:mergeReadWriteConfig(config, writeConfig)
end

function _M.__:getReadWriteConfig(config, typ)
    local targetConfig = config[typ]
    if targetConfig then 
        if #targetConfig > 0 then 
            return tb.rand(targetConfig)
        end

        return targetConfig
    end
end

function _M.__:mergeReadWriteConfig(config, merge)

    return tb.except(tb.merge(config, merge), {'read', 'write'})
end

function _M.__:createReadLdo(config)

    local readConfig = self:getReadConfig(config)

    return self:createConnector(readConfig):connect(readConfig)
end

return _M

