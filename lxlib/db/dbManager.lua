
local lx, _M, mt = oo{ 
    _cls_       = '',
    _bond_      = 'connectionResolverBond'
}

local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new()
    
    local this = {
        connections = {},
        extensions = {},
        factory = app:make('db.factory'),
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

end

function _M:connection(name)

    if not name then 
        name = self:getDefaultConnection()
    end
    if not self.connections[name] then
        local connection = self:makeConnection(name)
        self.connections[name] = self:prepare(connection)
    end

    return self.connections[name]
end

function _M.__:prepare(connection)

    return connection
end

function _M.__:makeConnection(name)

    local config = self:getConfig(name)
    local extension = self.extensions[name]
    if extension then 
        return extension(config, name)
    end

    local driver = config.driver

    extension = self.extensions[driver]

    if extension then 
        return extension(config, name)
    end

    return self.factory:make(config, name)
end

function _M.__:getConfig(name)

    name = name or self:getDefaultConnection()
    local connections = app:conf('db.connections')
    local config = tb.get(connections, name)
    if not config then 
        throw('invalidArgumentException', 'database ' .. name .. ' not configured')
    end

    return config
end

function _M:getDefaultConnection()

    local default = app:conf('db.default')
    if not default then
        throw('invalidArgumentException', 'not configured default database')
    end

    return default
end

function _M:setDefaultConnection(name)

    app:setConf('db.default', name)
end

_M.setDefaultConn = _M.setDefaultConnection

function _M:supportedDrivers()

    return {'mysql', 'pgsql', 'sqlite'}
end

function _M:extend(name, resolver)
    
    self.extensions[name] = resolver
end

function _M:getConnections()

    return self.connections
end

function _M:strictMode(strict)

    strict = lf.needTrue(strict)

    app:setConf('db.connections.mysql.strict', strict)

    return self
end

return _M

