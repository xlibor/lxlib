
local _M = {
    _cls_ = ''
}

local mt = { __index = _M }

local lx = require('lxlib')

function _M:new()

    local this = {}

    setmetatable(this, mt)

    return this
end

function _M:load(app)
    
    app:boot()
end

return _M

