
local _M = { 
    _cls_    = ''
}

local mt = { __index = _M }

local lx = require('lxlib').load(_M)
local app, lf, tb, str = lx.kit()
local throw = lx.throw

function _M:new(config)
    
    local this = {
        config = config
    }

    setmetatable(this, mt)

    return this
end

function _M:ctor(config)

    self.connection = app:make('redis.connection', config)
end

function _M:command(cmd, ...)

    return self.connection:doCommand(cmd, ...)
end

function _M:_run_(method)

    return function(self, ...)
        local connection = self.connection

        return connection:doCommand(method, ...)
    end
end

return _M

