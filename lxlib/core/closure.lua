
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

function _M:use(...)

    self.params = {...}

    return self
end

function _M:args()

    return unpack(self.params)
end

mt.__call = function(self, ...)
    local callback = self.callback

    return callback(self, ...)
end

return _M

