
local _M = { 
    _cls_    = ''
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)
local app, lf, tb, str = lx.kit()

function _M:new()
    
    local this = {
        clients = {}
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor()

    local config = app:conf('redis')

    local servers = config.connections
    local cluster = config.cluster or false

    if cluster then
        self.clients = self:createAggregateClient(servers)
    else
        self.clients = self:createSingleClients(servers)
    end
end

function _M:createSingleClients(servers)

    local clients = {}
    for key, server in pairs(servers) do
        clients[key] = app:make('redis.client', server)
    end

    return clients
end

function _M:createAggregateClient()

end

function _M:connection(name)

    if not name then 
        name = self:getDefaultConnection()
    end

    return self.clients[name]
end

_M.conn = _M.connection

function _M.__:prepare(connection)

    return connection
end

function _M.__:getConfig(name)

    name = name or self:getDefaultConnection()
    local connections = app:conf('redis.connections')
    local config = tb.get(connections, name)
    if not config then
        throw('invalidArgumentException', 'redis db ' .. name .. ' not configured')
    end

    return config
end

function _M:getDefaultConnection()

    local default = app:conf('redis.default')
    if not default then
        throw('invalidArgumentException', 'not configured default redis db')
    end

    return default
end

function _M:getClients()

    return self.clients
end

function _M:_run_(method)

    return function(self, ...)
        local client = self:connection()
        local connection = client.connection

        return connection:doCommand(method, ...)
    end
end

return _M

