
local _M = {
    _cls_ = ''
}

local mt = {__index = _M}
local lx = require('lxlib')

function _M:new(callback, nick)

    local this = {
        callback = callback,
        nick = nick
    }

    setmetatable(this, mt)

    return this
end

function _M:use(data)

    self.data = data

    return self
end

mt.__call = function(self, ...)
    local callback = self.callback

    local data = self.data
    data.this = self
    if data then
        setmetatable(data, {__index = function(tbl, k)
            return _G[k]
        end})
        setfenv(callback, data)
    end

    return callback(...)
end

return _M

